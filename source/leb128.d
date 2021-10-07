/// Little Endian Base - see https://en.wikipedia.org/wiki/LEB128
module leb128;

import std.conv, std.traits, std.outbuffer;

/// Decode LEB128 value encoded in `buf`.
const(T) fromLEB128(T)(const ubyte[] buf, ref size_t processed) {
	static if (isScalarType!T && !isFloatingPoint!T) {
		T result;
		size_t shift;
		ubyte b;
		static if (isSigned!T)
			immutable size = T.sizeof * 8;
		do {
			b = buf[processed];
			version (BigEndian) {
				result |= to!T(b & 0x7f) << ((T.sizeof - 1) * 8 - shift);
			} else {
				result |= to!T(b & 0x7f) << shift;
			}
			shift += 7;
			processed++;
		} while (b & 0x80);
		static if (isSigned!T)
			if ((shift < size) && (b & 0x40) != 0) {
				version (BigEndian) {
					result |= to!T(~0) << ((T.sizeof - 1) * 8 - shift);
				} else {
					result |= to!T(~0) << shift;
				}
			}
		return result;
	} else {
		static assert(0, T.stringof ~ " is not an integral type");
	}
}	// fromLEB()

/// Decode LEB128 value encoded in `buf` into array `val`.
void arrayFromLEB128(T)(const ubyte[] buf, ref size_t processed, ref T val) {
	static if (isArray!T && !isFloatingPoint!(T[0])) {
		size_t n = processed;
		foreach (ref result; val) {
			static if (isSigned!(typeof(val[0])))
				immutable size = result.sizeof * 8;
			size_t shift;
			ubyte b;
			do {
				b = buf[n];
				version (BigEndian) {
					result |= to!(typeof(result))(b & 0x7f) << ((T.sizeof - 1) * 8 - shift);
				} else {
					result |= to!(typeof(result))(b & 0x7f) << shift;
				}
				shift += 7;
				n++;
			} while (b & 0x80);
			static if (isSigned!(typeof(val[0])))
				if ((shift < size) && (b & 0x40) != 0) {
					version (BigEndian) {
						result |= to!(typeof(result))(~0) << ((T.sizeof - 1) * 8 - shift);
					} else {
						result |= to!(typeof(result))(~0) << shift;
					}
				}
		}
		processed = n;
	} else {
		static assert(0, T.stringof ~ " is not an integral array type");
	}
}	// arrayFromLEB()

/// Encode value `_val` of type `T` into given `buf`.
void toLEB128(T)(OutBuffer buf, const T _val) {
	static if (isScalarType!T && !isFloatingPoint!T) {
		ubyte[T.sizeof*2] data;
		bool more = true;
		size_t idx;
		static if (isSigned!T)
			long val = _val;
		else
			ulong val = _val;
		do {
			version (BigEndian) {
				ubyte b = (cast(ubyte[T.sizeof])((cast(ubyte*)&val)[0..T.sizeof]))[T.sizeof-1] & 0x7f;
			} else {
				ubyte b = val & 0x7f;
			}
			val >>= 7;
			static if (isSigned!T) {
				if ((val == 0 && (b & 0x40) == 0) || (val == -1 && (b & 0x40) != 0))
					more = false;
				else
					b |= 0x80;
			} else {
				if (val != 0)
					b |= 0x80;
				else
					more = false;
			}
			data[idx] = b;
			idx++;
		} while (more);
		if (idx > 0)
			buf.write(data[0..idx]);
	} else static if (isArray!T && !isFloatingPoint!(typeof(_val[0]))) {
		ubyte[8192] data;
		size_t idx;
		foreach (v; _val) {
			bool more = true;
			static if (isSigned!(typeof(v)))
				long val = v;
			else
				ulong val = v;
			do {
				version (BigEndian) {
					ubyte b = (cast(ubyte[T.sizeof])((cast(ubyte*)&val)[0..T.sizeof]))[T.sizeof-1] & 0x7f;
				} else {
					ubyte b = val & 0x7f;
				}
				val >>= 7;
				static if (isSigned!(typeof(v))) {
					if ((val == 0 && (b & 0x40) == 0) || (val == -1 && (b & 0x40) != 0))
						more = false;
					else
						b |= 0x80;
				} else {
					if (val != 0)
						b |= 0x80;
					else
						more = false;
				}
				data[idx] = b;
				if (++idx >= data.length) {
					buf.write(data);
					idx = 0;
				}
			} while (more);
		}
		if (idx > 0)
			buf.write(data[0..idx]);
	} else {
		static assert(0, T.stringof ~ " is not an integral type");
	}
}	// toLEB128()
