all: flat

clean:
	rm -f *.o flat FlatTestMsg_generated.h

CFLAGS=
LDFLAGS=

FlatTestMsg_generated.h: FlatTestMsg.fbs
	flatc --cpp FlatTestMsg.fbs

main.o: main.cc FlatTestMsg_generated.h
	g++ -g -Wall -pedantic -c $(CFLAGS) -std=c++17 -O3 main.cc -o main.o

flat: main.o
	g++ -g -Wall -pedantic main.o -o flat $(LDFLAGS) -lfmt
