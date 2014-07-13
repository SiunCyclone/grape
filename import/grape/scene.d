module grape.scene;

//import std.variant;
import derelict.opengl3.gl3;
import grape.mesh;

class Scene {
  //alias ActorType = Algebraic!(Camera, Mesh, Light);
  //alias ActorType = Algebraic!(Mesh);

  public:
    this() {
      // Basic, Fog, LensFlare 
    }

    //void add(T)(T actor) {
    void add(Mesh mesh) {
      _meshes ~= mesh;
      //_actors ~= ActorType(actor);
    }

    void remove() {
    }

    @property {
      Mesh[] meshes() {
        return _meshes;
      }
    }

  private:
    //ActorType[] _actors;
    Mesh[] _meshes;
}

