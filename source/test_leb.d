import std.conv, std.traits, std.outbuffer, std.stdio;

import leb128;

unittest { write("tests/leb128.d "); }

unittest {
	write("#1 ");

	auto buf = new OutBuffer;
	size_t processed = 0;

	immutable ulong l = 0x1122334455667788;
	toLEB128!ulong(buf, l);

	immutable ubyte[] expected = [ 0x88, 0xef, 0x99, 0xab, 0xc5, 0xe8, 0x8c, 0x91, 0x11 ];

	const data = buf.toBytes();

	assert(data == expected);

	assert(l == fromLEB128!ulong(buf.toBytes(), processed));
}

unittest {
	import std.exception, core.exception;

	write("#2 ");

	auto buf = new OutBuffer;
	size_t processed = 0;

	// test byte/ubyte
	toLEB128!byte(buf, byte.max);
	toLEB128!byte(buf, byte.min);

	toLEB128!ubyte(buf, ubyte.max);
	toLEB128!ubyte(buf, ubyte.min);

	assert(byte.max == fromLEB128!byte(buf.toBytes(), processed));
	assert(processed == 2);
	assert(byte.min == fromLEB128!byte(buf.toBytes(), processed));
	assert(processed == 4);

	assert(ubyte.max == fromLEB128!ubyte(buf.toBytes(), processed));
	assert(processed == 6);
	assert(ubyte.min == fromLEB128!ubyte(buf.toBytes(), processed));
	assert(processed == 7);

	// test short/ushort
	toLEB128!short(buf, short.max);
	toLEB128!short(buf, short.min);

	toLEB128!ushort(buf, ushort.max);
	toLEB128!ushort(buf, ushort.min);

	assert(short.max == fromLEB128!short(buf.toBytes(), processed));
	assert(processed == 10);
	assert(short.min == fromLEB128!short(buf.toBytes(), processed));
	assert(processed == 13);

	assert(ushort.max == fromLEB128!ushort(buf.toBytes(), processed));
	assert(processed == 16);
	assert(ushort.min == fromLEB128!ushort(buf.toBytes(), processed));
	assert(processed == 17);

	// test int/uint
	toLEB128!int(buf, int.max);
	toLEB128!int(buf, int.min);

	toLEB128!uint(buf, uint.max);
	toLEB128!uint(buf, uint.min);

	assert(int.max == fromLEB128!int(buf.toBytes(), processed));
	assert(processed == 22);
	assert(int.min == fromLEB128!int(buf.toBytes(), processed));
	assert(processed == 27);

	assert(uint.max == fromLEB128!uint(buf.toBytes(), processed));
	assert(processed == 32);
	assert(uint.min == fromLEB128!uint(buf.toBytes(), processed));
	assert(processed == 33);

	// test long/ulong
	toLEB128!long(buf, long.max);
	toLEB128!long(buf, long.min);

	toLEB128!ulong(buf, ulong.max);
	toLEB128!ulong(buf, ulong.min);

	assert(long.max == fromLEB128!long(buf.toBytes(), processed));
	assert(processed == 43);
	assert(long.min == fromLEB128!long(buf.toBytes(), processed));
	assert(processed == 53);

	assert(ulong.max == fromLEB128!ulong(buf.toBytes(), processed));
	assert(processed == 63);
	assert(ulong.min == fromLEB128!ulong(buf.toBytes(), processed));
	assert(processed == 64);

	// try reading when there is nothing to read
	assertThrown!RangeError(fromLEB128!byte(buf.toBytes(), processed));

	// trick fromLEB() into trying to read more than there are bytes available
	buf.write(to!ubyte(0x80));
	assertThrown!RangeError(fromLEB128!byte(buf.toBytes(), processed));
}

unittest {
	auto buf = new OutBuffer;
	size_t processed = 0;

	write("#3 ");

	immutable ops = 30_000;
	long[ops] la;

	foreach (n; 0..ops)
		la[n] = n;

	toLEB128(buf, la);

	long[ops] lb;

	arrayFromLEB128(buf.toBytes(), processed, lb);

	assert(la == lb);
}

unittest {
	auto buf = new OutBuffer;
	size_t processed = 0;

	write("#4 ");

	immutable ops = 30_000;
	ulong[ops] la;

	foreach (n; 0..ops)
		la[n] = n;

	toLEB128(buf, la);

	ulong[ops] lb;

	arrayFromLEB128(buf.toBytes(), processed, lb);

	assert(la == lb);
}

unittest {
	auto buf = new OutBuffer;
	size_t processed = 0;

	write("#5 ");

	immutable ops = 30_000;
	long[ops] la;

	foreach (n; 0..ops)
		la[n] = -n;

	toLEB128(buf, la);

	long[ops] lb;

	arrayFromLEB128(buf.toBytes(), processed, lb);

	assert(la == lb);
}

unittest {
	write("#6 ");

	auto buf = new OutBuffer;
	auto f = 0;
	foreach (l; 0..10_000_000L) {
		toLEB128!long(buf, l * f);
		f *= -1;
	}

	size_t processed = 0;
	f = 0;
	foreach (l; 0..10_000_000L) {
		assert(l * f == fromLEB128!long(buf.toBytes(), processed));
		f *= -1;
	}
}

unittest {
	auto buf = new OutBuffer;
	size_t processed = 0;

	write("#7 ");

	immutable ops = 30_000;
	long[ops] la;

	foreach (n; 1..ops)
		la[n] = long.max / n;

	toLEB128(buf, la);

	long[ops] lb;

	arrayFromLEB128(buf.toBytes(), processed, lb);

	assert(la == lb);
}

unittest {
	auto buf = new OutBuffer;
	size_t processed = 0;

	write("#8 ");

	immutable ops = 30_000;
	long[ops] la;

	foreach (n; 1..ops)
		la[n] = long.min / n;

	toLEB128(buf, la);

	long[ops] lb;

	arrayFromLEB128(buf.toBytes(), processed, lb);

	assert(la == lb);
}

unittest {
	import std.exception, core.exception;

	write("#9 ");

	auto buf = new OutBuffer;
	size_t processed = 0;

	// test byte/ubyte
	toLEB128!byte(buf, byte.max / 2);
	toLEB128!byte(buf, byte.min / 2);

	toLEB128!ubyte(buf, ubyte.max / 2);
	toLEB128!ubyte(buf, ubyte.min);

	assert(byte.max / 2 == fromLEB128!byte(buf.toBytes(), processed));
	assert(byte.min / 2 == fromLEB128!byte(buf.toBytes(), processed));

	assert(ubyte.max / 2 == fromLEB128!ubyte(buf.toBytes(), processed));
	assert(ubyte.min == fromLEB128!ubyte(buf.toBytes(), processed));

	// test short/ushort
	toLEB128!short(buf, short.max / 2);
	toLEB128!short(buf, short.min / 2);

	toLEB128!ushort(buf, ushort.max / 2);
	toLEB128!ushort(buf, ushort.min);

	assert(short.max / 2 == fromLEB128!short(buf.toBytes(), processed));
	assert(short.min / 2 == fromLEB128!short(buf.toBytes(), processed));

	assert(ushort.max / 2 == fromLEB128!ushort(buf.toBytes(), processed));
	assert(ushort.min == fromLEB128!ushort(buf.toBytes(), processed));

	// test int/uint
	toLEB128!int(buf, int.max / 2);
	toLEB128!int(buf, int.min / 2);

	toLEB128!uint(buf, uint.max / 2);
	toLEB128!uint(buf, uint.min);

	assert(int.max / 2 == fromLEB128!int(buf.toBytes(), processed));
	assert(int.min / 2 == fromLEB128!int(buf.toBytes(), processed));

	assert(uint.max / 2 == fromLEB128!uint(buf.toBytes(), processed));
	assert(uint.min == fromLEB128!uint(buf.toBytes(), processed));

	// test long/ulong
	toLEB128!long(buf, long.max / 2);
	toLEB128!long(buf, long.min / 2);

	toLEB128!ulong(buf, ulong.max / 2);
	toLEB128!ulong(buf, ulong.min);

	assert(long.max / 2 == fromLEB128!long(buf.toBytes(), processed));
	assert(long.min / 2 == fromLEB128!long(buf.toBytes(), processed));

	assert(ulong.max / 2 == fromLEB128!ulong(buf.toBytes(), processed));
	assert(ulong.min == fromLEB128!ulong(buf.toBytes(), processed));
}

unittest { writeln; }
