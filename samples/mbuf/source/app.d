import std.stdio, std.conv, std.datetime.stopwatch;

import msgbuf;

alias Type = MsgBufferType.Var;

void main(string[] args)
{
	auto rounds = 1000;
	if (args.length == 2)
		rounds = to!int(args[1]);

	struct sub1 {
		string greeting = "Hello World!";
		uint answer = 42;
	}

	struct sub2 {
		uint answer = 42;
	}

	struct sub3 {
		double temp = 22.5;
	}

	struct MsgBufTestMsg {
		enum MsgType {
			MSG_TYPE_TEST = 0,
			MSG_TYPE_LIVE = 1
		}
		struct Header {
			uint release;
			bool flag;
			string name;
			MsgType type;
		}
		Header header;
		double[] doubleData;
		uint[] intData;
		ubyte[] bytesData;
		// Flatbuffers does not support associative arrays
		// ulong[string] mapData;
		Oneof!(ulong, sub1, sub2, sub3, uint, string, double) msg;
	}

	MsgBufTestMsg msg;
	msg.header.release = 42;
	msg.header.flag = true;
	msg.header.name = "Hello World!";
	msg.header.type = MsgBufTestMsg.MsgType.MSG_TYPE_TEST;
	foreach (n; 0..10_000) {
		msg.doubleData ~= n;
		msg.intData ~= n;
		msg.bytesData ~= 42;
		// msg.mapData[to!string(n)] = n;
	}
	msg.msg = sub1();

	auto buf = toMsgBuffer!(Type)(msg);
	writefln("serialized size: %s (%s)", buf.toBytes.length, Type.stringof);
	const msg2 = fromMsgBuffer!(MsgBufTestMsg, Type)(buf);
	assert(msg == msg2);

	auto sz = 0u;
	immutable sw = StopWatch(AutoStart.yes);
	foreach (n; 0..rounds) {
		auto data = toMsgBuffer!(Type)(msg);
		sz += data.toBytes.length;
		fromMsgBuffer!(MsgBufTestMsg, Type)(data);
	}
	auto ms = sw.peek.total!"msecs";
	writefln("performed %d rounds in %s ms (%s bytes / ms)", rounds, ms, to!uint(cast(double)sz / ms));
}
