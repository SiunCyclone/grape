module grape.scene;

//import std.variant;
import derelict.opengl3.gl3;
import grape.mesh;
import grape.renderer;
import grape.filter;
import grape.camera;
import grape.window;

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

    void filter(Filter filter, Renderer2 renderer, Camera camera) {
      filter.filter({
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        renderer.render(this, camera);
      });
    }

    @property {
      Mesh[] meshes() {
        return _meshes;
      }
    }

  private:
    //ActorType[] _actors;
    Mesh[] _meshes;
    Filter _filter;
}

