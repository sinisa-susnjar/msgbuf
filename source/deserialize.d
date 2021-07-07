/// Deserialize a message buffer into a D struct, class or array.
module deserialize;

import std.conv, std.traits, std.string, std.outbuffer;

import leb128, common;

/// Deserialize top-level, either array, associative array or struct from
/// a given ubyte array.
/// For aggregate types like structs, deserialize each member.
auto fromMsgBuffer(T, MsgBufferType E = MsgBufferType.Var)(const ubyte[] msg) {
	size_t processed = 0;
	return fromMsgBuffer!(T, E)(msg, processed);
}	// fromMsgBuffer()

/// Deserialize top-level, either array, associative array or struct from
/// a given OutBuffer.
/// For aggregate types like structs, deserialize each member.
auto fromMsgBuffer(T, MsgBufferType E = MsgBufferType.Var)(const OutBuffer buf) {
	size_t processed = 0;
	return fromMsgBuffer!(T, E)(buf.toBytes, processed);
}	// fromMsgBuffer()

// Deserialise a number from an integer value.
pragma(inline, true)
const(T) deserializeInt(MsgBufferType E, T)(const ubyte[] msg, ref size_t processed) {
	static if (E == MsgBufferType.Flat) {
		// See: https://github.com/KabukiStarship/KabukiToolkit/wiki/Fastest-Method-to-Align-Pointers
		processed += (-processed) & (T.alignof - 1);
		immutable n = *cast(T *)&msg[processed];
		processed += n.sizeof;
	} else {
		immutable n = fromLEB128!T(msg, processed);
	}
	return n;
}	// deserializeInt()

// Deserialize a single value, either a string, a floating point value or a scalar, e.g.
// int, bool, long, etc. If it is neither, then forward to top-level deserialize.
auto deserializeValue(T, MsgBufferType E)(const ubyte[] msg, ref size_t processed) {
	if (processed >= msg.length) {
		// check for out of data, e.g. when trying to read a newer message format with more
		// fields from data that has been serialised using an older message format version
		T val;
		return val;
	}
	static if (isSomeString!(T)) {
		immutable n = deserializeInt!(E, uint)(msg, processed);
		immutable s = processed;
		processed += n;
		return to!T(msg[s..processed].assumeUTF);
	} else static if (isBoolean!(T)) {
		immutable n = processed;
		processed += T.sizeof;
		static assert(ubyte.sizeof == bool.sizeof);
		return *cast(T *)&msg[n];
	} else static if (is(T == enum)) {
		static if (__traits(compiles, to!int(EnumMembers!T[0]))) {
			static if (E == MsgBufferType.Flat) {
				processed += (-processed) & (int.alignof - 1);
				immutable n = processed;
				processed += int.sizeof;
				return *cast(T *)&msg[n];
			} else {
				return to!T(fromLEB128!int(msg, processed));
			}
		} else {
			static assert(0, "only integral enums supported for enum " ~ T.stringof);
		}
	} else static if (isScalarType!(T) || isFloatingPoint!(T)) {
		static if (!isFloatingPoint!(T) && T.sizeof > 1 && E == MsgBufferType.Var) {
			return fromLEB128!T(msg, processed);
		} else {
			processed += (-processed) & (T.alignof - 1);
			immutable n = processed;
			processed += T.sizeof;
			return *cast(T *)&msg[n];
		}
	} else static if (isArray!(T)) {
		T val;
		auto n = deserializeInt!(E, uint)(msg, processed);
		static if (isDynamicArray!(T))
			val = new typeof(val[0])[n];
		static if (isScalarType!(typeof(val[0])) || isFloatingPoint!(typeof(val[0]))) {
			static if (!isFloatingPoint!(typeof(val[0])) && typeof(val[0]).sizeof > 1 && E == MsgBufferType.Var) {
				arrayFromLEB128!T(msg, processed, val);
			} else {
				processed += (-processed) & (T.alignof - 1);
				import core.stdc.string : memcpy;
				memcpy(&val[0], &msg[processed], val.length * typeof(val[0]).sizeof);
				// I think memcpy() is faster than the below code, but I might be wrong...
				// val[0..n][] = (cast(const(typeof(val[0]))*)&msg[processed])[0..n];
				processed += val.length * typeof(val[0]).sizeof;
			}
		} else {
			static foreach (i; 0..n)
				val[i] = deserializeValue!(typeof(val[i]), E)(msg, processed);
		}
		return val;
	} else static if (isAssociativeArray!(T)) {
		T val;
		immutable n = deserializeInt!(E, uint)(msg, processed);
		foreach (i; 0..n) {
			auto k = deserializeValue!(KeyType!T, E)(msg, processed);
			val[k] = deserializeValue!(ValueType!T, E)(msg, processed);
		}
		return val;
	} else static if (is(T == struct) && T.stringof.startsWith("Oneof")) {
		T val;
		immutable oneOfIdx = deserializeInt!(E, ubyte)(msg, processed);
		if (oneOfIdx > 0) {
			static foreach (idx, s; T.tupleof) {{
				alias OneofMemberType = typeof(s);
				enum OneofMemberName = __traits(identifier, s);
				static if (!is(OneofMemberType == TypeInfo)) {
					if (OneofMemberName.startsWith("___data_field_" ~ to!string(oneOfIdx-1))) {
						val = deserializeValue!(OneofMemberType, E)(msg, processed);
					}
				}
			}}
		}
		return val;
	} else {
		return fromMsgBuffer!(T, E)(msg, processed);
	}
}	// deserializeValue()

auto fromMsgBuffer(T, MsgBufferType E)(const ubyte[] msg, ref size_t processed) {
	T val;
	static if (isAggregateType!(T) && !is(T == class)) {
		static foreach (v; T.tupleof)
			mixin("val." ~ __traits(identifier, v)) = deserializeValue!(typeof(v), E)(msg, processed);
	} else static if (isArray!(T) || isAssociativeArray!(T)) {
		val = deserializeValue!(T, E)(msg, processed);
	} else {
		static assert(0, "expected struct or array, not " ~ T.stringof);
	}
	return val;
}	// fromMsgBuffer()
