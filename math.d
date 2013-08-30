module orange.math;

import std.math;

import std.stdio;

struct Vec3 {
  public:
    this(float x, float y, float z) {
      set(x, y, z);
    }

    void set(float x, float y, float z) {
      _x = x;
      _y = y;
      _z = z;
    }

    Vec3 cross(Vec3 vec) {
      return Vec3( _y*vec.z - _z*vec.y,
                   _z*vec.x - _x*vec.z,
                   _x*vec.y - _y*vec.x );
    }

    @property {
      float x() {
        return _x;
      }

      float y() {
        return _y;
      }

      float z() {
        return _z;
      }

      void normalize() {
        auto m = magnitude();
        if (m == 0) return;
        _x = _x / m;
        _y = _y / m;
        _z = _z / m;
      }

      float magnitude() {
        return sqrt(pow(_x, 2) + pow(_y, 2) + pow(_z, 2));
      }
    }

  private:
    float _x = 1;
    float _y = 1;
    float _z = 1;
}

struct Mat4 {
  public:
    this(float[] coords...) {
      set(coords);
    }

    void set(float[] coords...) {
      assert(coords.length == 16);
      _mat = coords;
    }

    Mat4 translate(float x, float y, float z) {
      Mat4 mat4 = Mat4( 1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        x, y, z, 1 );
      return multiply(mat4);
    }

    Mat4 multiply(Mat4 mat4) {
      auto a = _mat[0],  b = _mat[1],  c = _mat[2],  d = _mat[3],
           e = _mat[4],  f = _mat[5],  g = _mat[6],  h = _mat[7],
           i = _mat[8],  j = _mat[9],  k = _mat[10], l = _mat[11],
           m = _mat[12], n = _mat[13], o = _mat[14], p = _mat[15],
           A = mat4.mat[0],  B = mat4.mat[1],  C = mat4.mat[2],  D = mat4.mat[3],
           E = mat4.mat[4],  F = mat4.mat[5],  G = mat4.mat[6],  H = mat4.mat[7],
           I = mat4.mat[8],  J = mat4.mat[9],  K = mat4.mat[10], L = mat4.mat[11],
           M = mat4.mat[12], N = mat4.mat[13], O = mat4.mat[14], P = mat4.mat[15];
      return Mat4( A * a + B * e + C * i + D * m,
                   A * b + B * f + C * j + D * n,
                   A * c + B * g + C * k + D * o,
                   A * d + B * h + C * l + D * p,
                   E * a + F * e + G * i + H * m,
                   E * b + F * f + G * j + H * n,
                   E * c + F * g + G * k + H * o,
                   E * d + F * h + G * l + H * p,
                   I * a + J * e + K * i + L * m,
                   I * b + J * f + K * j + L * n,
                   I * c + J * g + K * k + L * o,
                   I * d + J * h + K * l + L * p,
                   M * a + N * e + O * i + P * m,
                   M * b + N * f + O * j + P * n,
                   M * c + N * g + O * k + P * o,
                   M * d + N * h + O * l + P * p );
    }

    @property {
      float[16] mat() {
        return _mat;
      }
    }

  private:
    float[16] _mat;
}
