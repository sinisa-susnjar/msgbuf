import std.stdio, std.traits;

import msgbuf;

unittest {
  write("tests/simple.d ");
}

// Some easy tests to get started.

/// test struct with single int member
unittest {
  write("#1 ");
  struct TestStruct {
    int val = 42;
  }

  auto t1 = TestStruct();
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
      assert(t1 == t2);
    }
  }
}

/// test static array containing ints
unittest {
  write("#2 ");
  auto a1 = [1, 2, 3];
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      immutable a2 = fromMsgBuffer!(typeof(a1), T)(msg);
      assert(a1 == a2);
    }
  }
}

/// test associative array containing strings
unittest {
  write("#3 ");
  immutable string[string] m1 = ["key1": "val1", "key2": "val2"];
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(m1);
      immutable m2 = fromMsgBuffer!(string[string], T)(msg);
      assert(m1 == m2);
    }
  }
}

/// test struct containing a dynamic array of doubles
unittest {
  write("#4 ");
  struct TestStruct {
    double[] val;
  }

  auto t1 = TestStruct();
  t1.val = new double[3];
  t1.val[0] = 1.1;
  t1.val[1] = 2.2;
  t1.val[2] = 3.3;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
      assert(t1 == t2);
    }
  }
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
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(t1);
      immutable t2 = fromMsgBuffer!(TestStruct, T)(msg);
      assert(t1 == t2);
    }
  }
}

/// test dynamic array containing ints
unittest {
  write("#6 ");
  immutable int[] a1 = [1, 2, 3, 4, 5];
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      immutable a2 = fromMsgBuffer!(int[], T)(msg);
      // auto a2 = fromMsgBuffer!(typeof(a1), T)(msg);
      assert(a1 == a2);
    }
  }
}

/// test static array containing doubles
unittest {
  write("#7 ");
  immutable double[] a1 = [1.1, 2.2, 3.3];
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      immutable a2 = fromMsgBuffer!(double[], T)(msg);
      assert(a1 == a2);
    }
  }
}

/// test default initialised static array containing ints
unittest {
  write("#8 ");
  immutable int[10] a1;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      immutable auto a2 = fromMsgBuffer!(int[10], T)(msg);
      assert(a1 == a2);
    }
  }
}

/// test default initialised static array containing doubles
unittest {
  import std.math;

  write("#9 ");
  double[10] a1;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(a1);
      auto a2 = fromMsgBuffer!(typeof(a1), T)(msg);
      assert(a1.length == a2.length);
      foreach (i; a2)
        assert(isNaN(i));
    }
  }
}

/// some more floating point tests
unittest {
  write("#10 ");

  import std.outbuffer : OutBuffer;
  import std.math : pow, abs;
  import std.conv : to;

  double precision = pow(10, 7);
  auto e = 1.0e-6;
  immutable max = long.max / precision;
  immutable min = long.min / precision;
  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto buf = new OutBuffer;
      auto v = 0.0;
      auto f = 1.0;
      size_t len = 0;
      foreach (double l; 0 .. 10_000_000) {
        v = l * 3.1415926 * f;
        if (v > 0)
          assert(v < max);
        else
          assert(v > min);
        auto val = to!long(v * precision);
        serializeValue!(T, long)(val, buf);
        f *= -1;
      }

      size_t processed = 0;
      v = 0.0;
      f = 1.0;
      foreach (double l; 0 .. 10_000_000) {
        auto val = deserializeValue!(long, T)(buf.toBytes(), processed);
        v = l * 3.1415926 * f;
        auto d = to!double(val) / precision;
        assert(abs(d - v) <= e,
            to!string(d) ~ " != " ~ to!string(v) ~ " (" ~ to!string(l) ~ ") = " ~ to!string(d - v));
        f *= -1;
      }
    }
  }
}

/// Just some regression test for to/from LEB
unittest {
  write("#11 ");

  immutable orig = long.min / 2;
  import std.outbuffer;

  auto buf = new OutBuffer;
  size_t processed = 0;
  serializeValue!(MsgBufferType.Var, long)(orig, buf);
  immutable val = deserializeValue!(long, MsgBufferType.Var)(buf.toBytes, processed);
  assert(orig == val);
}

unittest {
  writeln;
}
