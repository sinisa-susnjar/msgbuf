module common;

/// Type of message buffers - either Flat (similar to Flatbuffers) or Var (similar to Protobuf)
enum MsgBufferType {
	Flat = 0,
	Var = 1
}
