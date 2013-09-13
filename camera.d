module orange.camera;

import opengl.glew;
import std.math;
import orange.math;

import std.stdio;

class Camera {
  public :
    this() {

    }

    void translate() {

    }

    void rotate() {

    }

    void ortho() {
    }

    void perspective(float fovy, float aspect, float znear, float zfar) {
      // translate to orange.math
      auto cot = delegate float(float x){ return 1 / tan(x); };
      auto f = cot(fovy/2);

      _proj.set( f/aspect, 0, 0, 0,
                 0, f, 0, 0,
                 0, 0, (zfar+znear)/(znear-zfar), -1,
                 0, 0, (2*zfar*znear)/(znear-zfar), 0 );
    }

    void look_at(Vec3 eye, Vec3 center, Vec3 up) {
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
      Mat4 pvMat4() {
        return _proj.multiply(_view);
      }
    }

  private:
    Quaternion _quat;
    Mat4 _proj, _view;
}

struct Quaternion {
  public:

  private:
}

/*
class Camera {
	public:
		this() {
			axis_rad = [0.0, PI_2];
			quat = new Quaternion;
			quat.set([0.0, 0.0, 3.0, 0.0]);

			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			gluPerspective(45.0, DISPLAY_X/cast(float)DISPLAY_Y, 0.1, 100.0);
			glGetFloatv(GL_PROJECTION_MATRIX, proj_);
		}

		void main() {
			clear;
			rotate;
			zoom_up_out;
			set_view;
		}

		@property {
			GLfloat[16] projView() { 
				GLfloat[16] projView_;
			
				projView_ = mul(proj_, view_);
				return projView_;
			}
		}
	private:
		void clear() {
			glClear(GL_COLOR_BUFFER_BIT);
		}

		void rotate() {
			if (glfwGetKey('H')) quat.rotate([0.0, 1.0, 0.0], PI/180);	
			if (glfwGetKey('L')) quat.rotate([0.0, 1.0, 0.0], -PI/180);	
			if (glfwGetKey('J')) {
				//quat.rotate([axis_rad[0]], PI/180);		
			}
			if (glfwGetKey('K')) {
				//quat.rotate([axis[0], axis[1], axis[2]], -PI/180);		
			}
		}
		
		void zoom_up_out() {
			float t1 = 0.994, t2  = 1.006;
			if (glfwGetKey('Z')) quat.set([quat.pos[0]*t1, quat.pos[1]*t1, quat.pos[2]*t1, quat.w]);
			if (glfwGetKey('X')) quat.set([quat.pos[0]*t2, quat.pos[1]*t2, quat.pos[2]*t2, quat.w]);
		}

		void set_view() {
			glMatrixMode(GL_MODELVIEW);
			glLoadIdentity();
			gluLookAt(quat.pos[0],quat.pos[1],quat.pos[2], 0.0,0.0,0.0, 0.0,1.0,0.0);
			glGetFloatv(GL_MODELVIEW_MATRIX, view_);
		}

		GLfloat[16] view_, proj_;
		Quaternion quat;
		float[2] axis_rad;
}
*/

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
