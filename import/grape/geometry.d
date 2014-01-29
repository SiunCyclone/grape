module grape.geometry;

import grape.math;

struct CoordinateSystem {
  void reset() {
    origin = Quat(Vec3(0, 0, 0));
    x = Quat(Vec3(1, 0, 0));
    y = Quat(Vec3(0, 1, 0));
    z = Quat(Vec3(0, 0, 1));
  }

  Quat origin = Quat(Vec3(0, 0, 0));
  Quat x = Quat(Vec3(1, 0, 0));
  Quat y = Quat(Vec3(0, 1, 0));
  Quat z = Quat(Vec3(0, 0, 1));
}

class Geometry {
  public:
    void forward(in float distance) {
    }

    void back(in float distance) {
    }

    void up(in float distance) {
    }

    void down(in float distance) {
    }

    void right(in float distance) {
    }

    void left(in float distance) {
    }

    void pitch(in float rad) {
    }

    void yaw(in float rad) {
    }

    void roll(in float rad) {
    }

    void translate(in Vec3 axis, in float distance) {
    }

    void rotate(in Vec3 axis, in float rad) {
      auto quat = Quat(axis, rad);

      // _localCS.originの回転 
      auto result = quat.conjugate * _localCS.origin * quat;
      _localCS.origin = result;

      // _localCS.xyzの回転 
      // _verticesの回転
    }

    void scale() {
    }

    @property {
      /*
      Quat origin() {
        return _localCS.origin;
      }
      */

      Vec3[] vertices() {
        return _vertices;
      }

      int[] indices() {
        return _indices;
      }
    }

  protected:
    CoordinateSystem _localCS;
    Vec3[] _vertices;
    int[] _indices;
    // normal;
}

class CubeGeometry : Geometry {
  public:
    this(in float width, in float height, in float depth) {
      auto x = width / 2;
      auto y = height / 2;
      auto z = depth / 2;

      _vertices = [ Vec3(x, -y, -z),
                    Vec3(x, -y, z),
                    Vec3(-x, -y, z),
                    Vec3(-x, -y, -z),
                    Vec3(x, y, -z),
                    Vec3(x, y, z),
                    Vec3(-x, y, z),
                    Vec3(-x, y, -z) ];
      _indices = [ 0, 1, 2, 0, 2, 3,
                   0, 1, 4, 1, 4, 5,
                   1, 2, 5, 2, 5, 6,
                   0, 3, 4, 3, 4, 7,
                   4, 5, 6, 4, 6, 7,
                   2, 3, 7, 2, 7, 6 ];
      /*
      _indices = [ 0, 1, 2, 1, 2, 3,
                   4, 7, 6, 7, 6, 5,
                   0, 4, 5, 4, 5, 1,
                   1, 5, 6, 5, 6, 2,
                   2, 6, 7, 6, 7, 3,
                   4, 0, 3, 0, 3, 7 ];
                   */
    }
}

