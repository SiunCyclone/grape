module grape.layer;

import std.variant;
import grape.camera;
import grape.mesh;
import grape.light;

class Layer {
  alias ActorType = Algebraic!(Camera, Mesh, Light);

  public:
    this() {
      _visible = true; 
    }

    void add(T)(T actor) {
      _actors ~= ActorType(actor);
    }

    void visible(in bool flag) {
      _visible = flag;
    }

  private:
    ActorType[] _actors;
    bool _visible;
}

