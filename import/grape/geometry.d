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
                           _list[2].vec3 + vec3 );
      return result;
    }

    CoordinateSystem opBinaryRight(string op)(Vec3 vec3) if (op == "+") {
      return opBinary!op(vec3);
    }

    ref CoordinateSystem opOpAssign(string op)(Vec3 vec3) if (op == "+") {
      _list[0].set(_list[0].vec3 + vec3);
      _list[1].set(_list[1].vec3 + vec3);
      _list[2].set(_list[2].vec3 + vec3);
      return this;
    }

    void set_position(Vec3 x, Vec3 y, Vec3 z) {
      _list = [ Quat(x), Quat(y), Quat(z) ];
    }

    void set_position(Quat x, Quat y, Quat z) {
      _list = [ x, y, z ];
    }

    void rotate(Quat rotQuat) {
      _list = map!(pos => rotQuat.conjugate * pos * rotQuat)(_list).array;
    }

    @property {
      Quat x() {
        return _list[0];
      }

      Quat y() {
        return _list[1];
      }

      Quat z() {
        return _list[2];
      }
    }

  private:
    Quat[] _list = [ Quat(Vec3(1, 0, 0)),
                     Quat(Vec3(0, 1, 0)),
                     Quat(Vec3(0, 0, 1)) ];
}

// TODO atomic
class Geometry {
  public:
    void set_position(Vec3 vec3) {
      auto distance = vec3 - _origin.vec3;
      _origin.set(_origin.vec3 + distance);
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
      rotate_impl(_localCS.x.vec3, rad, _origin.vec3);
    }

    void yaw(in float rad) {
      rotate_impl(_localCS.y.vec3, rad, _origin.vec3);
    }

    void roll(in float rad) {
      rotate_impl(_localCS.z.vec3, rad, _origin.vec3);
    }

    void translate(in Vec3 axis, in float distance) {
    }

    void rotate(in Vec3 axis, in float rad) {
      rotate_impl(axis, rad, Vec3(0, 0, 0));
    }

    void rotate(in Vec3 axis, in float rad, in Vec3 pos) {
      rotate_impl(axis, rad, pos);
    }

    void scale() {
    }

    @property {
      Quat origin() {
        return _origin;
      }

      Vec3[] vertices() {
        return _vertices;
      }

      int[] indices() {
        return _indices;
      }
    }

  protected:
    void rotate_impl(in Vec3 axis, in float rad, in Vec3 pos) {
      void delegate() impl = {
        auto rotQuat = Quat(axis, rad);

        // _originの回転
        if (pos != _origin.vec3) _origin = rotQuat.conjugate * _origin * rotQuat;

        // _localCSの回転 
        _localCS.rotate(rotQuat);

        // _verticesの回転
        auto tmp = map!(vec3 => Quat(vec3))(_vertices);
        _vertices = map!(pos => (rotQuat.conjugate * pos * rotQuat).vec3)(tmp).array;
      };

      _vertices = map!(x => x - pos)(_vertices).array;
      impl();
      _vertices = map!(x => x + pos)(_vertices).array;
    }

    CoordinateSystem _localCS;
    Quat _origin = Quat(Vec3(0, 0, 0));
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

unittest {
  import std.range : zip;

  bool nearly_equal(Vec3 a, Vec3 b) {
    foreach (v; zip(a.coord, b.coord))
      if (v[0] - v[1] > 0.001) return false;
    return true;
  }

  Geometry geometry = new CubeGeometry(1, 1, 1);
  assert(geometry.origin.vec3 == Vec3(0, 0, 0));
  assert(geometry.vertices == [ Vec3([0.5, -0.5, -0.5]), Vec3([0.5, -0.5, 0.5]), Vec3([-0.5, -0.5, 0.5]), Vec3([-0.5, -0.5, -0.5]), Vec3([0.5, 0.5, -0.5]), Vec3([0.5, 0.5, 0.5]), Vec3([-0.5, 0.5, 0.5]), Vec3([-0.5, 0.5, -0.5])]);

  geometry.set_position(Vec3(1, 0, 0));
  assert(geometry.origin.vec3 == Vec3(1, 0, 0));

  geometry.rotate(Vec3(0, 1, 0), PI);
  assert(nearly_equal(geometry.origin.vec3, Vec3(-1, 0, 0)));

  /*
  geometry.pitch(PI_2);
  geometry.yaw(PI_2);
  geometry.roll(PI_2);
  geometry.rotate(Vec3(0, 1, 0), PI, Vec3(1, 1, 1));
  */
}

