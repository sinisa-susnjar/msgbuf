import std.stdio, std.traits;

import msgbuf;

unittest { write("tests/aggregate.d "); }

// Structs within struct and other nested things.

/// test struct withing struct
unittest {
	write("#1 ");
	struct TestStruct1 {
		struct InnerStruct1 {
			double val = 0.123456;
		}
		InnerStruct1 inner;
		int val = 42;
	}
	
	static foreach (T; EnumMembers!MsgBufferType) {{
		auto t1 = TestStruct1();
		auto msg = toMsgBuffer!(T)(t1);
		immutable t2 = fromMsgBuffer!(TestStruct1, T)(msg);
		assert(t1 == t2);
	}}
}

/// test struct withing struct within struct within struct...
unittest {
	write("#2 ");
	struct TestStruct2 {
		struct InnerStruct2 {
			struct InnerStruct2_1 {
				struct InnerStruct2_2 {
					struct InnerStruct2_3 {
						struct InnerStruct2_4 {
							struct InnerStruct2_5 {
								struct InnerStruct2_6 {
									float val = 2.6;
								}
								InnerStruct2_6 inner2_6;
								float val = 2.5;
							}
							InnerStruct2_5 inner2_5;
							float val = 2.4;
						}
						InnerStruct2_4 inner2_4;
						float val = 2.3;
					}
					InnerStruct2_3 inner2_3;
					float val = 2.2;
				}
				InnerStruct2_2 inner2_2;
				float val = 2.1;
			}
			InnerStruct2_1 inner2_1;
			ubyte val = 2;
		}
		InnerStruct2 inner2;
		int val = 42;
	}

	static foreach (T; EnumMembers!MsgBufferType) {{
		auto t1 = TestStruct2();
		auto msg = toMsgBuffer!(T)(t1);
		immutable t2 = fromMsgBuffer!(TestStruct2, T)(msg);
		assert(t1 == t2);
	}}
}

unittest { writeln; }
