module grape.manip;

import grape.math;

struct CoordinateSystem {
  void reset() {
    origin = Quat(0.0, Vec3(0, 0, 0));
    x = Quat(0.0, Vec3(1, 0, 0));
    y = Quat(0.0, Vec3(0, 1, 0));
    z = Quat(0.0, Vec3(0, 0, 1));
  }

  Quat origin = Quat(0.0, Vec3(0, 0, 0));
  Quat x = Quat(0.0, Vec3(1, 0, 0));
  Quat y = Quat(0.0, Vec3(0, 1, 0));
  Quat z = Quat(0.0, Vec3(0, 0, 1));
}

struct Manipulator {
  public:
    this(in Quat vertex) {
      add(vertex);
    }

    this(in Quat[] vertices) {
      _vertices = vertices.dup;
    }

    this(in Vec3 vertex) {
    } 

    this(in Vec3[] vertices) {
    } 

    this(in float[] vertices) {
    } 

    void add(in Quat vertex) {
      _vertices ~= vertex;
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
    }

    void scale() {
    }

  private:
    CoordinateSystem _localCS;
    Quat _quat;
    Quat _cquat;
    Quat[] _vertices;
}

alias Manipulator Manip;

