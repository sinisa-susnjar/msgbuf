#include <chrono>

#include <fmt/core.h>

#include "FlatTestMsg_generated.h"

using namespace std::chrono_literals;
namespace sc = std::chrono;

using namespace PerfTest;

int
main(int argc, const char **argv)
{
	flatbuffers::FlatBufferBuilder builder(256 * 1024);

	auto rounds = 1000;
	if (argc == 2)
		rounds = std::stoi(argv[1]);

	std::vector<double> doubleData;
	std::vector<unsigned> intData;

	for (auto n = 0; n < 10000; n++) {
		doubleData.push_back(n);
		intData.push_back(n);
	}

	std::array<unsigned char, 10000> data;
	std::fill(data.begin(), data.end(), 42);

	auto s = builder.CreateString("Hello World!");
	auto hdr = CreateHeader(builder, 42, true, s, MsgType_MSG_TYPE_TEST);
	auto dbl = builder.CreateVector(doubleData);
	auto i = builder.CreateVector(intData);
	auto b = builder.CreateVector(data.data(), data.size());

	auto msg = CreateFlatTestMsg(builder, hdr, dbl, i, b);
	builder.Finish(msg);
	uint8_t *buf = builder.GetBufferPointer();
	int szMsg = builder.GetSize();

	fmt::print("serialized size: {}\n", szMsg);

	auto t = sc::system_clock::now();
	auto sz = 0u;
	for (auto n = 0; n < rounds; n++ ) {
		auto s = builder.CreateString("Hello World!");
		auto hdr = CreateHeader(builder, 42, true, s, MsgType_MSG_TYPE_TEST);
		auto dbl = builder.CreateVector(doubleData);
		auto i = builder.CreateVector(intData);
		auto b = builder.CreateVector(data.data(), data.size());
		auto msg = CreateFlatTestMsg(builder, hdr, dbl, i, b);
		builder.Finish(msg);
		uint8_t *buf = builder.GetBufferPointer();
		int szMsg = builder.GetSize();
		// auto s = msg.SerializeAsString();
		// fmt::print("sz: {}\n", s.size());
		// exit(1);
		sz += szMsg; // s.size();
		// ProtoTestMsg rcv;
		// rcv.ParseFromString(s);
		auto rcv = GetFlatTestMsg(buf);
	}
	auto d = sc::system_clock::now() - t;
	auto ms = sc::duration_cast<sc::milliseconds>(d).count();
	fmt::print("performed {} rounds in {} ms ({} bytes / ms)\n", rounds, ms, (int)((double)sz / ms));
}
