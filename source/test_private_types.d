import std.stdio, std.traits;
import std.outbuffer : OutBuffer;
import std.datetime.date : Date, Month;

import msgbuf;

unittest {
  write("tests/private_types.d ");
}

// Some tests using types with non-accessible private members.

// A struct encapsulating a std.datetime.date.Date
struct MyDate {
  this(int year, int month, int day)
  {
    date = Date(year, month, day);
  }

  // Define a method with this signature to take care of serialization.
  void toMsgBuf(MsgBufferType E = MsgBufferType.Var)(OutBuffer buf) const
  {
    serializeValue!(E, int)(date.year, buf);
    serializeValue!(E, int)(date.month, buf);
    serializeValue!(E, int)(date.day, buf);
  }

  // Define a method with this signature to take care of deserialization.
  void fromMsgBuf(MsgBufferType E = MsgBufferType.Var)(const ubyte[] msg, ref size_t processed)
  {
    date = Date(deserializeValue!(int, E)(msg, processed),
        deserializeValue!(int, E)(msg, processed), deserializeValue!(int, E)(msg, processed));
  }

  // Add a data type whose members are not publicly accessible
  // and use e.g. alias this to make it "feel" like a Date.
  Date date;
  alias date this;
}

unittest {
  write("#1 ");

  auto d1 = MyDate(2021, 8, 2);

  auto buf = new OutBuffer;
  assert(__traits(hasMember, MyDate, "toMsgBuf"));
  assert(__traits(compiles, d1.toMsgBuf(buf)));

  ubyte[] data;
  size_t processed;
  assert(__traits(hasMember, MyDate, "fromMsgBuf"));
  assert(__traits(compiles, d1.fromMsgBuf(data, processed)));

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = new OutBuffer;
      d1.toMsgBuf!(T)(msg);
      MyDate d2;
      size_t n;
      d2.fromMsgBuf!(T)(msg.toBytes, n);
      assert(d1 == d2);
    }
  }
}

unittest {
  write("#2 ");

  struct MyData {
    this(string data, int year, int month, int day)
    {
      this.date = MyDate(year, month, day);
      this.data = data;
    }

    MyDate date;
    string data;
  }

  auto d1 = MyData("Hello World!", 2021, 8, 2);

  static foreach (T; EnumMembers!MsgBufferType) {
    {
      auto msg = toMsgBuffer!(T)(d1);
      MyData d2;
      fromMsgBuffer!(MyData, T)(d2, msg);
      assert(d1 == d2);
    }
  }
}

unittest {
  writeln;
}
