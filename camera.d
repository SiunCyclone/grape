module orange.camera;

import opengl.glew;

class Camera {
  public :
    this() {

    }

  private:

}

/*
class Quaternion {
	public:
		void set(float[] elem) {
			_w = elem[3];
			_pos = [elem[0], elem[1], elem[2]];
		}

		float dot_product(T, S)(T[] a, S[] b) {
			float x = a[0]*b[0];
			float y = a[1]*b[1];
			float z = a[2]*b[2];
			return (x + y + z);
		}
		
		float[] cross_product(T, S)(T[] a, S[] b) {
			float x = a[1]*b[2] - a[2]*b[1];
			float y = a[2]*b[0] - a[0]*b[2];
			float z = a[0]*b[1] - a[1]*b[0];
			return [x, y, z];
		}

		Quaternion multiply(Quaternion a, Quaternion b) {
			Quaternion q = new Quaternion;
			float u = (a.w * b.w) - dot_product(a.pos, b.pos);
			float[] t = b.pos.map!(x => x*a.w).array;
			float[] s = a.pos.map!(x => x*b.w).array;
			float[] l = cross_product(a.pos, b.pos);
			t[] += s[];
			t[] += l[];
			q.set([t[0], t[1], t[2], u]);
			return q;
		}

		void rotate(T)(T[] vec, float rad) {
			Quaternion Q = new Quaternion;
			Quaternion R = new Quaternion;
			Q.set([vec[0]*sin(rad/2), vec[1]*sin(rad/2), vec[2]*sin(rad/2), cos(rad/2)]);
			R.set([-vec[0]*sin(rad/2), -vec[1]*sin(rad/2), -vec[2]*sin(rad/2), cos(rad/2)]);

			auto t = multiply(R, this);
			auto s = multiply(t, Q);
			_pos = s.pos.dup;
			_w = s.w;
		}

		@property {
			float w() { return _w; }
			float[] pos() { return _pos; }
		}

	private:
		float _w;
		float[] _pos;
}
*/
