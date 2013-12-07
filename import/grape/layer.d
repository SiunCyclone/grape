module grape.layer;

import std.variant;
import grape.camera;
import grape.mesh;
import grape.light;

class Layer {
  alias ActorType = Algebraic!(Camera, Mesh, Light);

  public:
    this() {
      
    }

    void add(T)(T actor) {
      _actors ~= ActorType(actor);
    }

  private:
    ActorType[] _actors;
}

