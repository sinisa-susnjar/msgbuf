import std.stdio, std.traits;

import msgbuf;

unittest { write("tests/simple.d "); }

// Some easy tests to get started.

/// test struct with single int member
unittest {
	write("#1 ");
	struct TestStruct { int val = 42; }
	auto t1 = TestStruct();
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(t1);
		immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
		assert(t1 == t2);
	}}
}

/// test static array containing ints
unittest {
	write("#2 ");
	auto a1 = [1, 2, 3];
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(a1);
		immutable a2 = fromMsgBuffer!(typeof(a1), T)(msg);
		assert(a1 == a2);
	}}
}

/// test associative array containing strings
unittest {
	write("#3 ");
	immutable string[string] m1 = [ "key1": "val1", "key2": "val2" ];
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(m1);
		immutable m2 = fromMsgBuffer!(string[string], T)(msg);
		assert(m1 == m2);
	}}
}

/// test struct containing a dynamic array of doubles
unittest {
	write("#4 ");
	struct TestStruct { double[] val; }
	auto t1 = TestStruct();
	t1.val = new double[3];
	t1.val[0] = 1.1;
	t1.val[1] = 2.2;
	t1.val[2] = 3.3;
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(t1);
		immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
		assert(t1 == t2);
	}}
}

/// test struct containing some scalar values
unittest {
	write("#5 ");
	struct TestStruct {
		ubyte b = 0xf3;
		char c = 'A';
		ushort us = 50_001;
		short s = 32_001;
		uint ui = 0xffffff;
		int i = -1;
		ulong ul = 0x1122334455667788;
		long l = -42;
		bool f = true;
	}
	auto t1 = TestStruct();
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(t1);
		immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
		assert(t1 == t2);
	}}
}

/// test dynamic array containing ints
unittest {
	write("#6 ");
	immutable int[] a1 = [ 1, 2, 3, 4, 5];
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(a1);
		immutable a2 = fromMsgBuffer!(int[], T)(msg);
		// auto a2 = fromMsgBuffer!(typeof(a1), T)(msg);
		assert(a1 == a2);
	}}
}

/// test static array containing doubles
unittest {
	write("#7 ");
	immutable double[] a1 = [1.1, 2.2, 3.3];
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(a1);
		immutable a2 = fromMsgBuffer!(double[], T)(msg);
		assert(a1 == a2);
	}}
}

/// test default initialised static array containing ints
unittest {
	write("#8 ");
	immutable int[10] a1;
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(a1);
		immutable auto a2 = fromMsgBuffer!(int[10], T)(msg);
		assert(a1 == a2);
	}}
}

/// test default initialised static array containing doubles
unittest {
	import std.math;
	write("#9 ");
	double[10] a1;
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto msg = toMsgBuffer!(T)(a1);
		auto a2 = fromMsgBuffer!(typeof(a1), T)(msg);
		assert(a1.length == a2.length);
		foreach (i; a2)
			assert(isNaN(i));
	}}
}

unittest { writeln; }
