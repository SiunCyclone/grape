module grape.manipulator;

import std.stdio;
import grape.math;

/**
 * ローカル座標系の構造体
 */
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

/**
 * 3Dオブジェクトを簡単に操作するクラス
 */
struct Manipulator {
  public:
    this(Vec3 vec3) {
      _localCS.origin = Quat(vec3);
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
      auto result = quat.conjugate * _localCS.origin * quat;
      _localCS.origin = result;

      // _localCS.xyzの回転 
      // _verticesの回転
    }

    void scale() {
    }

    @property {
      Quat origin() {
        return _localCS.origin;
      }

      Quat[] vertices() {
        return _vertices;
      }
    }

  private:
    CoordinateSystem _localCS;
    Quat[] _vertices;
}

alias Manipulator Manip;

