import std.stdio, std.conv, std.traits, std.string, std.exception, core.exception;

import msgbuf;

unittest { write("tests/oneof.d "); }

unittest {
	write("#1 ");

	Oneof!(bool, byte, ubyte, char, wchar, dchar, int, uint, short, ushort, long, ulong, string, char[]) msg;

	msg = true;
	assert(has!bool(msg));
	assert(get!bool(msg) == true);
	assertThrown!AssertError(get!ubyte(msg));

	msg = false;
	assert(has!bool(msg));
	assert(get!bool(msg) == false);

	msg = to!ubyte(0xff);
	assert(has!ubyte(msg));
	assert(get!ubyte(msg) == to!ubyte(0xff));
	assertThrown!AssertError(get!bool(msg));
	assertThrown!AssertError(get!byte(msg));

	msg = to!byte(0x7f);
	assert(has!byte(msg));
	assert(get!byte(msg) == to!byte(0x7f));
	assertThrown!AssertError(get!ubyte(msg));

	msg = to!char('A');
	assert(has!char(msg));
	assert(get!char(msg) == to!char('A'));
	assertThrown!AssertError(get!ubyte(msg));

	msg = to!wchar("\u03B3");
	assert(has!wchar(msg));
	assert(get!wchar(msg) == to!wchar("\u03B3"));
	assertThrown!AssertError(get!char(msg));
	assertThrown!AssertError(get!dchar(msg));

	msg = to!dchar("\U0001F603");
	assert(has!dchar(msg));
	assert(get!dchar(msg) == to!dchar("\U0001F603"));
	assertThrown!AssertError(get!wchar(msg));
	assertThrown!AssertError(get!ushort(msg));

	msg = to!int(42);
	assert(has!int(msg));
	assert(get!int(msg) == to!int(42));
	assertThrown!AssertError(get!uint(msg));

	msg = to!uint(42);
	assert(has!uint(msg));
	assert(get!uint(msg) == to!uint(42));
	assertThrown!AssertError(get!int(msg));

	msg = to!short(42);
	assert(has!short(msg));
	assert(get!short(msg) == to!short(42));
	assertThrown!AssertError(get!ushort(msg));

	msg = to!ulong(42);
	assert(has!ulong(msg));
	assert(get!ulong(msg) == to!ulong(42));
	assertThrown!AssertError(get!long(msg));

	msg = to!long(42);
	assert(has!long(msg));
	assert(get!long(msg) == to!long(42));
	assertThrown!AssertError(get!ulong(msg));

	msg = "Hallo Welt";
	assert(has!string(msg));
	assert(get!string(msg) == "Hallo Welt");
	assertThrown!AssertError(get!(char[])(msg));

	msg = to!(char[])("Hallo Welt");
	assert(has!(char[])(msg));
	assert(get!(char[])(msg) == to!(char[])("Hallo Welt"));
	assertThrown!AssertError(get!string(msg));
}

unittest {
	write("#2 ");

	enum Huhu {
		VAL0 = 0,
		VAL1 = 1
	}

	struct Sub1 {
		this(int v) {
			val = v;
		}
		int val;
		string s = "sub1";
	}

	struct Sub2 {
		this(double v) {
			val = v;
		}
		double val;
		string s = "sub2";
	}

	struct Sub3 {
		this(string v) {
			val = v;
		}
		string val;
		string s = "sub3";
	}

	struct Sub4 {
		this(string v, uint d) {
			q = v;
			a = d;
		}
		uint a;
		string s = "sub4";
		string q;
	}

	struct Message {
		Oneof!(Sub1, Sub2, Sub3, Sub4, string, int, Huhu) sub;
		long val = 4711;
	}

	auto msg = Message();

	auto s1 = Sub1(42);
	msg.sub = s1;
	assert(has!Sub1(msg.sub));
	assert(get!Sub1(msg.sub) == s1);

	auto s2 = Sub2(1.5);
	msg.sub = s2;
	assert(has!Sub2(msg.sub));
	assert(get!Sub2(msg.sub) == s2);

	auto s3 = Sub3("Hello World");
	msg.sub = s3;
	assert(has!Sub3(msg.sub));
	assert(get!Sub3(msg.sub) == s3);

	auto s4 = Sub4("what is the answer?", 42);
	msg.sub = s4;
	assert(has!Sub4(msg.sub));
	assert(get!Sub4(msg.sub) == s4);

	assert(!has!Sub1(msg.sub));
	assertThrown!AssertError(get!Sub1(msg.sub));

	immutable s = "Zdravo svijete!";
	msg.sub = s;
	assert(has!string(msg.sub));
	assert(get!string(msg.sub) == s);

	immutable i = 42;
	msg.sub = i;
	assert(has!int(msg.sub));
	assert(get!int(msg.sub) == i);

	immutable e = Huhu.VAL0;
	msg.sub = e;
	assert(has!Huhu(msg.sub));
	assert(get!Huhu(msg.sub) == e);
}

unittest {
	import msgbuf;

	write("#3 ");

	struct Sub0 {
		string s;
	}

	struct Sub1 {
		string s;
		int i;
		double d;
	}

	struct Sub2 {
		struct Sub2_1 {
			struct Sub2_2 {
				string s;
			}
			Sub2_2 s;
		}
		Sub2_1 s;
		ushort us;
	}

	struct Sub3 {
		enum Type { ok=1, notOk=-1 }
		Type t;
	}

	struct TestStruct {
		Oneof!(Sub0, Sub1, Sub2, Sub3, string) msg;
		int val;
	}
	static foreach (T; EnumMembers!MsgBufferType) {{
		{
			// test empty oneof
			auto t1 = TestStruct();
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
		{
			auto t1 = TestStruct();
			t1.val = 42;
			t1.msg = "Hello World!";
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
		{
			auto t1 = TestStruct();
			t1.val = 42;
			t1.msg = Sub0("Hello World!");
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
		{
			auto t1 = TestStruct();
			t1.val = 42;
			t1.msg = Sub1("Hello World!", 42, 1.5);
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
		{
			auto t1 = TestStruct();
			t1.val = 42;
			auto s2 = Sub2();
			s2.us = 42;
			s2.s = Sub2.Sub2_1();
			s2.s.s = Sub2.Sub2_1.Sub2_2();
			s2.s.s.s = "Hello World";
			t1.msg = s2;
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
		{
			auto t1 = TestStruct();
			t1.val = 42;
			auto s3 = Sub3();
			s3.t = Sub3.Type.ok;
			t1.msg = s3;
			auto msg = toMsgBuffer!(T)(t1);
			auto t2 = fromMsgBuffer!(TestStruct, T)(msg);
			assert(t1 == t2);
		}
	}}
}

unittest {
	write("#4 ");

	{
		Oneof!(string, ulong) o1 = "Hello";
		Oneof!(string, ulong) o2 = 42;
		assert(o1 != o2);
	}
	{
		Oneof!(string, ulong) o1;
		Oneof!(string, ulong) o2 = 42;
		assert(o1 != o2);
	}
	{
		Oneof!(string, ulong) o1 = "Hello";
		Oneof!(string, ulong) o2;
		assert(o1 != o2);
	}
	{
		Oneof!(string, ulong) o1;
		Oneof!(string, ulong) o2;
		assert(o1 == o2);
	}
}

unittest { writeln; }
