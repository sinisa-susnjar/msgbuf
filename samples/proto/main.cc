#include <chrono>

#include <fmt/core.h>

#include "ProtoTestMsg.pb.h"

using namespace std::chrono_literals;
namespace sc = std::chrono;

int main(int argc, const char **argv) {
  ProtoTestMsg msg;

  auto rounds = 1000;
  if (argc == 2)
    rounds = std::stoi(argv[1]);

  auto &hdr = *msg.mutable_header();
  hdr.set_version(42);
  hdr.set_flag(true);
  hdr.set_name("Hello World!");
  hdr.set_type(ProtoTestMsg::MSG_TYPE_TEST);
  // auto &mapData = *msg.mutable_mapdata();
  for (auto n = 0; n < 10000; n++) {
    msg.add_doubledata(n);
    msg.add_intdata(n);
    // Flatbuffers does not support maps
    // mapData[std::to_string(n)] = n;
  }
  std::array<char, 10000> data;
  std::fill(data.begin(), data.end(), 42);
  msg.set_bytesdata(data.data(), data.size());

  auto &sub1 = *msg.mutable_sub1msg();
  sub1.set_greeting("Hello World!");
  sub1.set_answer(42);

  auto szMsg = msg.SerializeAsString();
  fmt::print("serialized size: {}\n", szMsg.size());

  auto t = sc::system_clock::now();
  auto sz = 0u;
  for (auto i = 0; i < rounds; i++) {
    auto s = msg.SerializeAsString();
    sz += s.size();
    ProtoTestMsg rcv;
    rcv.ParseFromString(s);
  }
  auto d = sc::system_clock::now() - t;
  auto ms = sc::duration_cast<sc::milliseconds>(d).count();
  fmt::print("performed {} rounds in {} ms ({} bytes / ms)\n", rounds, ms,
             (int)((double)sz / ms));
}
