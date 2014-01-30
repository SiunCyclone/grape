module grape.manipulator;

import std.stdio;
import grape.math;
import grape.geometry;

/*
alias Manipulator Manip;
deprecated struct Manipulator {
  public:
    this(Vec3 vec3) {
      _localCS._origin = Quat(vec3);
    }

    void add(Vec3 vec3) {
      _vertices ~= Quat(vec3);
    }

    void remove() {
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
      auto quat = Quat(axis, rad);

      // _localCS.originの回転 
      auto result = quat.conjugate * _localCS._origin * quat;
      _localCS._origin = result;

      // _localCS.xyzの回転 
      // _verticesの回転
    }

    void scale() {
    }

    @property {
      Quat origin() {
        return _localCS._origin;
      }

      Quat[] vertices() {
        return _vertices;
      }
    }

  private:
    CoordinateSystem _localCS;
    Quat[] _vertices;
}
*/

