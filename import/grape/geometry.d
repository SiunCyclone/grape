module grape.geometry;

import grape.math;
import std.stdio;
import std.algorithm;
import std.array;

struct CoordinateSystem {
  public:
    CoordinateSystem opBinary(string op)(Vec3 vec3) if (op == "+") {
      CoordinateSystem result;
      result.set_position( _list[0].vec3 + vec3,
                           _list[1].vec3 + vec3,
                           _list[2].vec3 + vec3,
                           _list[3].vec3 + vec3 );
      return result;
    }

    CoordinateSystem opBinaryRight(string op)(Vec3 vec3) if (op == "+") {
      return opBinary!op(vec3);
    }

    ref CoordinateSystem opOpAssign(string op)(Vec3 vec3) if (op == "+") {
      _list[0].set(_list[0].vec3 + vec3);
      _list[1].set(_list[1].vec3 + vec3);
      _list[2].set(_list[2].vec3 + vec3);
      _list[3].set(_list[3].vec3 + vec3);
      return this;
    }

    void set_position(Vec3 origin, Vec3 x, Vec3 y, Vec3 z) {
      _list = [ Quat(origin), Quat(x), Quat(y), Quat(z) ];
    }

    void set_position(Quat origin, Quat x, Quat y, Quat z) {
      _list = [ origin, x, y, z ];
    }

    void rotate(Quat rotQuat) {
      _list = map!(pos => rotQuat.conjugate * pos * rotQuat)(_list).array;
    }

    @property {
      Quat origin() {
        return _list[0];
      }

      Quat x() {
        return _list[1];
      }

      Quat y() {
        return _list[2];
      }

      Quat z() {
        return _list[3];
      }
    }

  private:
    Quat[] _list = [ Quat(Vec3(0, 0, 0)),
                     Quat(Vec3(1, 0, 0)),
                     Quat(Vec3(0, 1, 0)),
                     Quat(Vec3(0, 0, 1)) ];
}

class Geometry {
  public:
    void set_position(Vec3 vec3) {
      auto distance = vec3 - _localCS.origin.vec3;
      _localCS += distance;
      _vertices = map!(x => x + distance)(_vertices).array; 
    }

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
      auto rotQuat = Quat(axis, rad);

      // _localCSの回転 
      _localCS.rotate(rotQuat);

      // _verticesの回転
      auto tmp = map!(vec3 => Quat(vec3))(_vertices);
      _vertices = map!(pos => (rotQuat.conjugate * pos * rotQuat).vec3)(tmp).array;
    }

    void scale() {
    }

    @property {
      Quat origin() {
        return _localCS.origin;
      }

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
    }
}

