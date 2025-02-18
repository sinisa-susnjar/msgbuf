/// Provide a discriminating union to be used inside a message buffer.
module oneof;

/// Create private anonymous union holding all requested types.
/// This has probably a fair share of TODOs, e.g. it cannot hold
/// multiple instances of the same type, the opEqual() is most
/// likely sub-optimal, and probably a bunch of other things that
/// I don't see as a D newbie.
struct Oneof(Types...) {

  /// Mixin some required operations like assignment, copy constructor, value getter.
  mixin GenOps;

  /// Return the TypeInfo of the type stored in the oneof union.
  const(TypeInfo) type() const
  {
    return _type;
  }

  /// To make testing for equality work for Oneof based types.
  bool opEquals(const ref typeof(this) other) const
  {
    if (_type is null && other.type is null)
      return true;
    if (_type is null || other.type is null)
      return false;
    static foreach (idx, SubType; Types) {
      if (this.has!SubType && other.has!SubType) {
        return this.value!SubType == other.value!SubType;
      }
    }
    return false;
  }

private:

  mixin template GenOps() {
    static foreach (idx, SubType; Types) {

      /// Assignment operator.
      ref typeof(this) opAssign(SubType value)
      {
        this.tupleof[idx] = value;
        _type = typeid(SubType);
        return this;
      }

      /// Return value of requested type.
      ref auto value(T : SubType)() const
      {
        assert(_type == typeid(T), "oneof doesn't hold a " ~ SubType.stringof);
        return this.tupleof[idx];
      }

      /// Create a Oneof given a value of a certain SubType.
      this(SubType value)
      {
        this.tupleof[idx] = value;
        _type = typeid(SubType);
      }
    }
  }

  /// Types this Oneof instance can hold.
  union {
    Types _data;
  }

  /// Specific type this Oneof instance currently holds.
  TypeInfo _type;
}

/// Test if Oneof of type T stores a value with the given SubType.
bool has(SubType, T)(ref T t)
{
  return (t._type == typeid(SubType));
}

/// Retrieve value with the given SubType from Oneof of type T.
const(SubType) get(SubType, T)(ref T t)
{
  return t.value!SubType;
}
