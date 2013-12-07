module grape.material;

import std.variant;
import std.conv;
import std.stdio;

class Material {
  alias DataType = Algebraic!(int[], bool, string);

  public:
    this(T...)(T params) {
      set_param(params);
    }

  private:
    void set_param(T...)(T params) {
      static if (params.length) {
        auto key = to!string(params[0]);
        auto value = params[1];

        hash[key] = value;
        set_param(params[2..$]);
      } else {
        // TODO
      }
    }

    DataType[string] hash; 
}

