all: mbuf

mbuf: source/app.d
	dub build -b release-nobounds

clean:
	dub clean
	rm -f mbuf
