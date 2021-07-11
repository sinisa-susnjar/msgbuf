/// Common definitions.
module common;

/// Type of message buffers - either Flat (similar to Flatbuffers) or Var (similar to Protobuf)
enum MsgBufferType {
	/// Flat (similar to Flatbuffers) - no variable integer encoding/decoding.
	Flat = 0,
	/// Variable (similar to Protobuf) - integers are encoded/decoded as varints.
	Var = 1
}
