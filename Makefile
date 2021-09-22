all: lib shared

lib: lib/libmsgbuf.a

lib/libmsgbuf.a:
	dub build -b release-nobounds

shared: lib/libmsgbuf.so

lib/libmsgbuf.so:
	dub build -b release-nobounds -c shared

test:
	dub test

cov:
	dub test -b unittest-cov

clean:
	dub clean
	rm -rf .dub
	rm -f *.lst .dub*.lst
	rm -f msgbuf-test-lib
	rm -f libmsgbuf.a libmsgbuf.so
