all: lib shared

lib: lib/libmsgbuf.a

lib/libmsgbuf.a:
	dub build -b release-nobounds

shared: lib/libmsgbuf.so

lib/libmsgbuf.so:
	dub build -b release-nobounds -c shared

test:
	dub test

clean:
	dub clean
	rm -f msgbuf
	rm -f lib/libmsgbuf.*
