import std.stdio, std.traits;

import msgbuf;

unittest {
  write("tests/enums.d ");
}

/// test struct with embedded enum member
unittest {
  write("#1 ");
  struct TestStruct1 {
    enum TestEnum1 {
      val0 = 0,
      val1 = 1
    }

    TestEnum1 val = TestEnum1.val1;
  }

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto t1 = TestStruct1();
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct1, T)(msg);
      assert(t1 == t2);
    }
  }
}

/// test struct with external enum member
unittest {
  write("#2 ");
  enum TestEnum2 {
    val0 = 0,
    val1 = 1
  }

  struct TestStruct2 {
    TestEnum2 val = TestEnum2.val1;
  }

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto t1 = TestStruct2();
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct2, T)(msg);
      assert(t1 == t2);
    }
  }
}

/// test struct with embedded string enum member
// unittest {
// 	write("#3 ");
// 	struct TestStruct3 {
// 		enum TestEnum3 {
// 			val0 = "aaa",
// 			val1 = "bbb"
// 		}
// 		TestEnum3 val = TestEnum3.val1;
// 	}
// 	auto t1 = TestStruct3();
// 	auto msg = toMsgBuffer(t1);
// 	auto t2 = fromMsgBuffer!TestStruct3(msg);
// 	assert(t1 == t2);
// }

unittest {
  writeln;
}
