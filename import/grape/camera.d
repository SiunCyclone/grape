module grape.camera;

import derelict.opengl3.gl3;

import std.math;
import std.stdio;

import grape.math;
import grape.manipulator;
import grape.window : WINDOW_WIDTH, WINDOW_HEIGHT;

/**
 * カメラ操作するクラス
 */
class Camera {
  public :
    this() {
      Vec3 eye = Vec3(0, 0, 1);
      Vec3 center = Vec3(0, 0, 0);
      Vec3 up = Vec3(0, 1, 0);

      perspective(45.0, cast(float)WINDOW_WIDTH/WINDOW_HEIGHT, 0.1, 100);
      look_at(eye, center, up);
    }

    /**
     * 初期化
     *
     * near:   一番近いz座標
     * far:    一番遠いz座標
     */
    this(in float near, in float far) {
      Vec3 eye = Vec3(0, 0, 1);
      Vec3 center = Vec3(0, 0, 0);
      Vec3 up = Vec3(0, 1, 0);

      perspective(45.0, cast(float)WINDOW_WIDTH/WINDOW_HEIGHT, near, far); //TODO
      look_at(eye, center, up);
    }

    void translate() {
    }

    /**
     * 回転操作
     *
     * vec3:    回転軸となるベクトル
     * rad:     回転する角度
     */
    void rotate(Vec3 vec3, in float rad) {
      _manip.rotate(vec3, rad); 
      look_at(_manip.origin.vec3, _center, _manip.vertices[0].vec3);
    }

    /*
    void scale() {
    }

    void ortho() {
    }
    */

    /**
     * 視界の設定
     *
     * GLUTのgluPerspectiveと同じです。
     * fovy:    視野角
     * aspect:  縦横比(通常は[画面幅/高さ]です）
     * near:   一番近いz座標
     * far:    一番遠いz座標
     */
    void perspective(in float fovy, in float aspect, in float near, in float far) {
      // translate to grape.math
      auto cot = delegate float(float x){ return 1 / tan(x); };
      auto f = cot(fovy/2);

      _proj.set( f/aspect, 0, 0, 0,
                 0, f, 0, 0,
                 0, 0, (far+near)/(near-far), -1,
                 0, 0, (2*far*near)/(near-far), 0 );
    }

    /**
     * 位置、姿勢の設定
     *
     * GLUTのgluLookAtと同じです。
     * eye:    視点
     * center: 注視点
     * up:     上方向
     */
    void look_at(Vec3 eye, Vec3 center, Vec3 up) {
      set(eye, center, up);

      Vec3 f = Vec3(center.x-eye.x, center.y-eye.y, center.z-eye.z);

      f.normalize;
      up.normalize;

      Vec3 s = f.cross(up);
      Vec3 u = s.cross(f);

      _view = Mat4( s.x, u.x, -f.x, 0,
                    s.y, u.y, -f.y, 0,
                    s.z, u.z, -f.z, 0,
                    0, 0, 0, 1 ).translate(-eye.x, -eye.y, -eye.z);
    }

    @property {
      /**
       * view, projection行列を掛け合わせたMat4型を返す
       *
       * 基本的にこれをuniformのpvmMatrixに送ります。
       */
      Mat4 pvMat4() {
        return _proj.multiply(_view);
      }
    }

  private:
    void set(Vec3 eye, Vec3 center, Vec3 up) {
      _manip = Manip(eye); // TODO 毎回作ってる
      _center = center;
      _manip.add(up); // TODO Manipを毎回作ってないと危険
    }

    Mat4 _proj, _view;
    Vec3 _center;
    Manip _manip;
}

