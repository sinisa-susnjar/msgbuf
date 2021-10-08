[![ubuntu](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/ubuntu.yml) [![macos](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/macos.yml/badge.svg)](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/macos.yml) [![windows](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/windows.yml/badge.svg)](https://github.com/sinisa-susnjar/msgbuf/actions/workflows/windows.yml) [![coverage](https://codecov.io/gh/sinisa-susnjar/msgbuf/branch/main/graph/badge.svg?token=1C9K09MWJ5)](https://codecov.io/gh/sinisa-susnjar/msgbuf)

# D Message Buffers

I was pondering the use of either protobuf or flatbuffers for a private project of mine, and there are some good D modules out there that enable the use of those serialisation libraries from within D programs.

However, I was trying to find out if it would be possible to do a (de)serialisation without the use of external schema files that needed to be precompiled (i.e. *.proto or *.fbs) and instead use plain D data types directly.

This library is the result of this experiment.

It only uses D's brilliant meta programming capabilities to (de)serialise data from/to binary format. No external schema files or precompilation is required.

Tested with the following compilers:

* LDC2 1.26.0 (DMD v2.096.1, LLVM 11.0.1), 1.27.0 (DMD v2.097.1, LLVM 12.0.1)
* DMD64 D Compiler v2.097.0, v2.097.2-beta.1

LDC2 takes a bit longer to compile than DMD, but produces much faster code.

# What works, what doesn't?

## Works

* most structure based types should be ok (as long as the members are public)
* types with private members can define toMsgBuf()/fromMsgBuf() methods for custom (de)serialization
* static arrays
* dynamic arrays
* associative arrays
* all basic D types
* enum (only integers at the moment)
* nested structures
* as long as new fields are appended to the end, old programs can read new message formats and vice versa
* oneof (types in a oneof message must be unique)

## Doesn't work (yet)

* "any" (this should be easy to simulate using a ubyte[] member for the data and maybe a type / url / uuid field)
* adding/removing fields at arbitrary places (though adding new fields to the end is fine)
* D classes, unions (probably won't do)
* CI/CD

# Possible future improvements

* fixing stuff that doesn't work yet if sensible
* adding @attributes to D message structures and fields to specify e.g. field/version numbers
* adding a JSON encoding like e.g. proto3 does (see: https://developers.google.com/protocol-buffers/docs/proto3#json)

# Some Microbenchmarks, take with a grain of salt.

## Using Flat msgbuf (i.e. similar to Google Flatbuffers)

	serialized size: 130072 (Flat)
	performed 1000 rounds in 39 ms (3335179 bytes / ms)

## Using Variable msgbuf (i.e. similar to Google Protobuf)

	serialized size: 109919 (Var)
	performed 1000 rounds in 76 ms (1446302 bytes / ms)

## Google Protobuf

	serialized size: 109921
	performed 1000 rounds in 96 ms (1145010 bytes / ms)

## Google Flatbuffers (note: these figures need to be verified!)

	serialized size: 130096
	performed 1000 ops in 107 ms (7650790 bytes / ms)

I have never worked with flatbuffers before, so I welcome all
constructive criticism.

# Examples

Please refer to the `samples` directory.

# History

* v0.0.8 Added endianess (defaulting to little endian).
