import std.stdio, std.conv, std.traits;

import msgbuf;

unittest {
  write("tests/nutcracker.d ");
}

// Some not so easy tests

/// test some brobdingnagian dynamic array containing floats
unittest {
  write("#1 ");
  float[] a1;
  // immutable len = 32_000_000;
  immutable len = 1_000_000;
  a1.length = len;
  foreach (n; 0 .. len)
    a1[n] = n;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      immutable a2 = fromMsgBuffer!(typeof(a1), T)(msg);
      assert(a1 == a2);
    }
  }
}

/// test a big associative array
unittest {
  write("#2 ");
  string[int] m1;
  // immutable len = 4_000_000;
  immutable len = 100_000;
  foreach (n; 0 .. len)
    m1[n] = to!string(n);
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(m1);
      auto m2 = fromMsgBuffer!(typeof(m1), T)(msg);
      assert(m1 == m2);
    }
  }
}

/// test struct containing a dynamic array of doubles
unittest {
  write("#3 ");
  struct TestStruct {
    double[] val;
  }

  auto t1 = TestStruct();
  // immutable len = 32_000_000;
  immutable len = 1_000_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
      assert(t1 == t2);
    }
  }
}

/// write struct Av2 with an additional field, then read struct Av1 which is missing this field.
unittest {
  write("#4 ");
  struct TestStructV2 {
    double[] val;
    int answer;
    bool flag;
  }

  auto t1 = TestStructV2();
  // immutable len = 32_000_000;
  immutable len = 1_000_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;
  t1.answer = 42;
  t1.flag = true;
  // The "old" version of the struct missing the new flag field.
  struct TestStructV1 {
    double[] val;
    int answer;
  }

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStructV1, T)(msg);
      assert(t1.val == t2.val);
      assert(t1.answer == t2.answer);
    }
  }
}

/// simulate use case where some middleware "enriches" received messages
/// for internal use before routing it to their destination, i.e. adding
/// a new field to the message while "in-flight"
unittest {
  write("#5 ");

  // this is the "original" message
  struct TestStruct {
    double[] val;
  }

  auto t1 = TestStruct();
  // immutable len = 32_000_000;
  immutable len = 1_000_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;

  // it is enriched with a timestamp by a hypothetical middleware
  struct TestStructEnriched {
    TestStruct val;
    ulong timestamp;
  }

  // the final, i.e. receive end struct simply merges both together
  struct TestStructFinal {
    double[] val;
    ulong timestamp;
  }

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      // serialise original
      auto msg = toMsgBuffer!(T)(t1);

      // read original into enriched
      auto e1 = TestStructEnriched();
      e1.val = fromMsgBuffer!(TestStruct, T)(msg);

      // add "timestamp"
      e1.timestamp = 12_345;
      assert(t1.val == e1.val.val);

      // serialise enriched message
      auto msg1 = toMsgBuffer!(T)(e1);

      // deserialise final message
      immutable f1 = fromMsgBuffer!(TestStructFinal, T)(msg1);

      assert(t1.val == f1.val);
      assert(e1.timestamp == f1.timestamp);
    }
  }
}

/// simulate use case where some middleware removes members from messages
/// before routing it to their destination, i.e. removing fields from the
/// message while "in-flight"
unittest {
  write("#6 ");

  // this is the "original" message
  struct TestStruct {
    double[] val;
    ulong timestamp;
  }

  auto t1 = TestStruct();
  // immutable len = 32_000_000;
  immutable len = 1_000_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;
  t1.timestamp = 12_345;

  // the timestamp is removed by a hypothetical middleware
  // to become the final, i.e. receive end struct
  struct TestStructFinal {
    double[] val;
  }

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      // serialise original
      auto msg = toMsgBuffer!(T)(t1);

      // deserialise original into final
      auto e1 = TestStructFinal();
      e1 = fromMsgBuffer!(TestStructFinal, T)(msg);

      // serialise final message
      auto msg1 = toMsgBuffer!(T)(e1);

      // deserialise final message
      immutable f1 = fromMsgBuffer!(TestStructFinal, T)(msg1);

      assert(t1.val == f1.val);
      assert(e1 == f1);
    }
  }
}

/// simulate use case where a program reads data created using an older message
/// format, i.e. with less fields than the current message format
unittest {
  write("#7 ");

  // this is the "old" message format
  struct TestStructOld {
    ulong[] val;
    ulong timestamp;
  }

  auto t1 = TestStructOld();
  // immutable len = 32_000_000;
  immutable len = 1_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;
  t1.timestamp = 12_345;

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      File old_data = File("nutcracker_7_test_data.tmp", "wb");
      foreach (i; 0 .. 100) {
        // serialise original
        auto msg = toMsgBuffer!(T)(t1);
        size_t[1] length = msg.toBytes.length;
        old_data.rawWrite(length);
        old_data.rawWrite(msg.toBytes);
      }
      old_data.close();

      // this is the "new" message format with new field(s) appended at the end
      struct TestStructNew {
        ulong[] val;
        ulong timestamp;
        string greeting;
        double temp;
      }

      File new_data = File("nutcracker_7_test_data.tmp", "rb");
      auto size = new_data.size();
      while (!new_data.eof && size > 0) {

        auto length = new_data.rawRead(new size_t[1]);
        size -= size_t.sizeof;

        auto buf = new_data.rawRead(new ubyte[length[0]]);
        size -= buf.length;

        // deserialise original into new
        immutable t2 = fromMsgBuffer!(TestStructNew, T)(buf);

        assert(t1.val == t2.val);
        assert(t1.timestamp == t2.timestamp);
      }
      new_data.close();
    }
  }

  import std.file : remove;

  remove("nutcracker_7_test_data.tmp");
}

/// simulate use case where a program reads data created using a newer message
/// format, i.e. with more fields than the current (older) message format
unittest {
  write("#8 ");

  // this is the "new" message format with new field(s) appended at the end
  struct TestStructNew {
    ulong[] val;
    ulong timestamp;
    string greeting;
    double temp;
  }

  auto t1 = TestStructNew();
  // immutable len = 32_000_000;
  immutable len = 1_000;
  t1.val.length = len;
  foreach (n; 0 .. len)
    t1.val[n] = n;
  t1.timestamp = 12_345;
  t1.greeting = "Hello World";
  t1.temp = -52.3;

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      File new_data = File("nutcracker_8_test_data.tmp", "wb");
      foreach (i; 0 .. 100) {
        // serialise new format
        auto msg = toMsgBuffer!(T)(t1);
        size_t[1] length = msg.toBytes.length;
        new_data.rawWrite(length);
        new_data.rawWrite(msg.toBytes);
      }
      new_data.close();

      // this is the "old" message format
      struct TestStructOld {
        ulong[] val;
        ulong timestamp;
      }

      File old_data = File("nutcracker_8_test_data.tmp", "rb");
      auto size = old_data.size();
      while (!old_data.eof && size > 0) {

        auto length = old_data.rawRead(new size_t[1]);
        size -= size_t.sizeof;

        auto buf = old_data.rawRead(new ubyte[length[0]]);
        size -= buf.length;

        // deserialise newer format into older one
        immutable t2 = fromMsgBuffer!(TestStructOld, T)(buf);

        assert(t1.val == t2.val);
        assert(t1.timestamp == t2.timestamp);
      }
      old_data.close();
    }
  }

  import std.file : remove;

  remove("nutcracker_8_test_data.tmp");
}

unittest {
  writeln;
}
