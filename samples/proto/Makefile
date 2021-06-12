all: proto

clean:
	rm -f *.o proto *.pb.cc *.pb.h

CFLAGS=$(shell pkg-config --cflags protobuf)
LDFLAGS=$(shell pkg-config --libs protobuf)

ProtoTestMsg.pb.cc: ProtoTestMsg.proto
	protoc --cpp_out=. ProtoTestMsg.proto

ProtoTestMsg.pb.o: ProtoTestMsg.pb.cc
	g++ -Wall -pedantic -c $(CFLAGS) -std=c++17 -O3 ProtoTestMsg.pb.cc -o ProtoTestMsg.pb.o

main.o: main.cc
	g++ -Wall -pedantic -c $(CFLAGS) -std=c++17 -O3 main.cc -o main.o

proto: ProtoTestMsg.pb.o main.o
	g++ -Wall -pedantic ProtoTestMsg.pb.o main.o -o proto $(LDFLAGS) -lfmt
