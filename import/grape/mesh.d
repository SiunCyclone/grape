module grape.mesh;

import derelict.opengl3.gl3;
import grape.geometry;
import grape.material;
import grape.camera;

class Mesh {
  public:
    this(Geometry geometry, Material material) {
      _geometry = geometry;
      _material = material;
    }
    
    @property {
      Geometry geometry() {
        return _geometry;
      }

      Material material() {
        return _material;
      }
    }
    
  private:
    Geometry _geometry;
    Material _material;
}

