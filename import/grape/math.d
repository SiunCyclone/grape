module grape.math;

public import std.math;
import std.stdio;
import std.algorithm;

alias Vector3 Vec3;
struct Vector3 {
  public:
    this(in float[] coord) {
      set(coord);
    }
    
    this(in float x, in float y, in float z) {
      set(x, y, z);
    }

    Vec3 opBinary(string op)(Vec3 vec3) if (op == "+") {
      auto tmp = new float[_coord.length];
      tmp[] = _coord[] + vec3.coord[];
      auto result = Vec3(tmp);
      return result;
    }

    Vec3 opBinary(string op)(Vec3 vec3) if (op == "-") {
      auto tmp = new float[_coord.length];
      tmp[] = _coord[] - vec3.coord[];
      auto result = Vec3(tmp);
      return result;
    }

    Vec3 opBinary(string op)(float ratio) if (op == "*") {
      auto tmp = new float[_coord.length];
      tmp[] = _coord[] * ratio;
      auto result = Vec3(tmp);
      return result;
    }

    Vec3 opBinaryRight(string op)(float ratio) if (op == "*") {
      return opBinary!op(ratio);
    }

    Vec3 opOpAssign(string op)(Vec3 vec3) if (op == "+") {
      auto tmp = new float[_coord.length];
      tmp[] = _coord[] + vec3.coord[];
      _coord = tmp;
      return this;
    }

    Vec3 opOpAssign(string op)(Vec3 vec3) if (op == "-") {
      auto tmp = new float[_coord.length];
      tmp[] = _coord[] - vec3.coord[];
      _coord = tmp;
      return this;
    }

    void set(in float[] coord) {
      _coord = coord.dup;
    }

    void set(in float x, in float y, in float z) {
      _coord = [x, y, z];
    }

    void set_x(in float x) {
      _coord[0] = x;
    }

    void set_y(in float y) {
      _coord[1] = y;
    }

    void set_z(in float z) {
      _coord[2] = z;
    }

    float dot(Vec3 vec3) {
      return ( _coord[0]*vec3.x + _coord[1]*vec3.y + _coord[2]*vec3.z );
    }

    Vec3 cross(Vec3 vec3) {
      return Vec3( _coord[1]*vec3.z - _coord[2]*vec3.y,
                   _coord[2]*vec3.x - _coord[0]*vec3.z,
                   _coord[0]*vec3.y - _coord[1]*vec3.x );
    }

    @property {
      float[] coord() {
        return _coord;
      }

      float x() {
        return _coord[0];
      }

      float y() {
        return _coord[1];
      }

      float z() {
        return _coord[2];
      }

      float magnitude() {
        return sqrt(pow(_coord[0], 2) + pow(_coord[1], 2) + pow(_coord[2], 2));
      }

      void normalize() {
        auto m = magnitude();
        if (m == 0) return;
        _coord[0] = _coord[0] / m;
        _coord[1] = _coord[1] / m;
        _coord[2] = _coord[2] / m;
      }
    }

  private:
    float[3] _coord;
}

alias Matrix4 Mat4;
struct Matrix4 {
  public:
    this(in float[] coords...) {
      set(coords);
    }

    void set(in float[] coords...) {
      assert(coords.length == 16);
      _mat[] = coords[];
    }

    Mat4 translate(in float x, in float y, in float z) {
      Mat4 mat4 = Mat4( 1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        x, y, z, 1 );
      return multiply(mat4);
    }

    Mat4 multiply(Mat4 mat4) {
      float a = _mat[0],  b = _mat[1],  c = _mat[2],  d = _mat[3],
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

    Mat4 inverse() {
      float a = _mat[0],  b = _mat[1],  c = _mat[2],  d = _mat[3],
            e = _mat[4],  f = _mat[5],  g = _mat[6],  h = _mat[7],
            i = _mat[8],  j = _mat[9],  k = _mat[10], l = _mat[11],
            m = _mat[12], n = _mat[13], o = _mat[14], p = _mat[15],
            q = a * f - b * e, r = a * g - c * e,
            s = a * h - d * e, t = b * g - c * f,
            u = b * h - d * f, v = c * h - d * g,
            w = i * n - j * m, x = i * o - k * m,
            y = i * p - l * m, z = j * o - k * n,
            A = j * p - l * n, B = k * p - l * o,
            ivd = 1 / (q * B - r * A + s * z + t * y - u * x + v * w);
      return Mat4( ( f * B - g * A + h * z) * ivd,
                   (-b * B + c * A - d * z) * ivd,
                   ( n * v - o * u + p * t) * ivd,
                   (-j * v + k * u - l * t) * ivd,
                   (-e * B + g * y - h * x) * ivd,
                   ( a * B - c * y + d * x) * ivd,
                   (-m * v + o * s - p * r) * ivd,
                   ( i * v - k * s + l * r) * ivd,
                   ( e * A - f * y + h * w) * ivd,
                   (-a * A + b * y - d * w) * ivd,
                   ( m * u - n * s + p * q) * ivd,
                   (-i * u + j * s - l * q) * ivd,
                   (-e * z + f * x - g * w) * ivd,
                   ( a * z - b * x + c * w) * ivd,
                   (-m * t + n * r - o * q) * ivd,
                   ( i * t - j * r + k * q) * ivd );
    }

    @property {
      float[16] mat() {
        return _mat;
      }

      Mat4 identity() {
        return Mat4( 1, 0, 0, 0,
                     0, 1, 0, 0,
                     0, 0, 1, 0,
                     0, 0, 0, 1 );
      }
    }

  private:
    float[16] _mat;
}

alias Quaternion Quat;
struct Quaternion {
  public:
    this(Vec3 vec3) {
      set(vec3, 0.0);
    }

    this(Vec3 vec3, in float rad) { // 回転行列の生成
      rotate(vec3, rad);
    }

    Quat opBinary(string op)(Quat quat) if (op == "*") {
      auto rad = _rad*quat.rad - _vec3.dot(quat.vec3);
      auto vec3 = _rad*quat.vec3 + quat.rad*_vec3 + _vec3.cross(quat.vec3);
      Quat result;
      result.set(vec3, rad);
      return result;
    }

    void set(in Vec3 vec3) {
      _vec3 = vec3;
    }

    void set(in float rad) {
      _rad = rad;
    }

    void set(in Vec3 vec3, in float rad) {
      _rad = rad;
      _vec3 = vec3;
    }

    void rotate(Vec3 vec3, in float rad) {
      vec3.normalize;

      _rad = cos(rad / 2);
      _vec3 = Vec3( vec3.x * sin(rad / 2),
                    vec3.y * sin(rad / 2),
                    vec3.z * sin(rad / 2) );
    }

    @property {
      Quat conjugate() {
        Quat quat;
        quat.set(Vec3(-_vec3.x, -_vec3.y, -_vec3.z), rad); // TODO
        return quat;
      }

      Mat4 to_mat4() {
        auto x = _vec3.x;
        auto y = _vec3.y;
        auto z = _vec3.z;
        auto w = _rad;
        return Mat4( 1-2*y^^2-2*z^^2, 2*x*y-2*w*z, 2*x*z+2*w*y, 0,
                     2*x*y+2*w*z, 1-2*x^^2-2*z^^2, 2*y*z-2*w*x, 0,
                     2*x*z-2*w*y, 2*y*z+2*w*x, 1-2*x^^2-2*y^^2, 0,
                     0, 0, 0, 1 );
      }

      float rad() {
        return _rad;
      }

      Vec3 vec3() {
        return _vec3;
      }
    }

  private:
    Vec3 _vec3;
    float _rad;
}

