/// Serialize a D struct, class or array to a message buffer.
module serialize;

import std.conv, std.traits, std.outbuffer, std.string;

import leb128, common, oneof;

/// Serialize top-level, either array, associative array or struct.
/// For aggregate types like structs, serialize each member.
auto toMsgBuffer(MsgBufferType E = MsgBufferType.Flat, T)(const ref T val) {
	return _toMsgBuffer!(E, T)(val, new OutBuffer);
}	// toMsgBuffer()

private:

// Serialise a number as integer value.
pragma(inline, true)
static void serializeInt(MsgBufferType E, T)(const T val, OutBuffer buf) {
	static if (E == MsgBufferType.Flat) {
		buf.alignSize(T.alignof);
		buf.write(to!T(val));
	} else {
		toLEB128(buf, to!T(val));
	}
}	// serializeInt()

// Serialize a single value, either a string, a floating point value or a scalar, e.g.
// int, bool, long, etc. If it is neither, then forward to top-level serialize.
static auto serializeValue(MsgBufferType E, T)(const ref T val, OutBuffer buf) {
	static if (isSomeString!(T)) {
		serializeInt!(E)(to!uint(val.length), buf);
		buf.write(val);
	} else static if (isBoolean!(T)) {
		static assert(ubyte.sizeof == bool.sizeof);
		buf.write(to!ubyte(val));
	} else static if (is(T == enum)) {
		static if (__traits(compiles, to!int(EnumMembers!T[0]))) {
			static if (E == MsgBufferType.Flat) {
				buf.alignSize(T.alignof);
				buf.write(to!int(val));
			} else {
				toLEB128(buf, to!int(val));
			}
		} else {
			static assert(0, "only integral enums supported for enum " ~ T.stringof);
		}
	} else static if (isScalarType!(T) || isFloatingPoint!(T)) {
		static if (!isFloatingPoint!(T) && T.sizeof > 1 && E == MsgBufferType.Var) {
			toLEB128!T(buf, val);
		} else {
			buf.alignSize(T.alignof);
			buf.write(val);
		}
	} else static if (isArray!(T)) {
		serializeInt!(E)(to!uint(val.length), buf);
		static if (isScalarType!(typeof(val[0])) || isFloatingPoint!(typeof(val[0]))) {
			// Performance optimisation for scalar/floating point arrays
			static if (!isFloatingPoint!(typeof(val[0])) && typeof(val[0]).sizeof > 1 && E == MsgBufferType.Var) {
				toLEB128!T(buf, val);
			} else {
				buf.reserve(val.length * typeof(val[0]).sizeof);
				buf.alignSize(T.alignof);
				buf.write(cast(ubyte[])val);
			}
		} else {
			static foreach (k; val)
				serializeValue!(E, typeof(k))(k, buf);
		}
	} else static if (isAssociativeArray!(T)) {
		// TODO: the performance for AAs is underwhelming, maybe there is a way to make "forbidden"
		// optimisations, given the implementation details of AAs here:
		// https://github.com/dlang/dmd/blob/7f4620f4e1fe29641b28648c5c4c93d9fafdf90f/src/dmd/backend/aarray.d
		// However, this might not work for all compilers, so maybe there is another way I have not seen yet...
		serializeInt!(E)(to!uint(val.length), buf);
		foreach (k; val.keys) {
			serializeValue!(E, typeof(k))(k, buf);
			serializeValue!(E, typeof(val[k]))(val[k], buf);
		}
	} else static if (is(T == struct) && T.stringof.startsWith("Oneof")) {
		bool hasValue;
		static foreach (idx, s; T.tupleof) {{
			alias OneofMemberType = typeof(s);
			enum OneofMemberName = __traits(identifier, s);

			static if (OneofMemberName.startsWith("___data_field")) {

				if (has!(OneofMemberType)(val)) {
					immutable oneOfValue = get!(OneofMemberType)(val);
					serializeInt!(E)(to!ubyte(idx+1), buf);
					serializeValue!(E, OneofMemberType)(oneOfValue, buf);
					hasValue = true;
				}
			}
		}}
		if (!hasValue) {
			// Oneof was empty.
			serializeInt!(E)(to!ubyte(0), buf);
		}
	} else {
		_toMsgBuffer!(E, T)(val, buf);
	}
}	// serializeValue()

static auto _toMsgBuffer(MsgBufferType E, T)(const ref T val, OutBuffer buf) {
	static if (isAggregateType!(T) && !is(T == class)) {
		static foreach (v; T.tupleof)
			serializeValue!(E, typeof(v))(mixin("val." ~ __traits(identifier, v)), buf);
	} else static if (isArray!(T) || isAssociativeArray!(T)) {
		serializeValue!(E, T)(val, buf);
	} else {
		static assert(0, "expected struct or array, not " ~ T.stringof);
	}
	return buf;
}	// _toMsgBuffer()
