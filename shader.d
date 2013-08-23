module orange.shader;

import std.exception : enforce;
import opengl.glew;

// name
enum {
  VertexShader = GL_VERTEX_SHADER,
  FragmentShader = GL_FRAGMENT_SHADER 
}

/*
auto vShader = q{
	attribute vec3 pos;
	attribute vec4 color;
	varying vec4 vColor;

	void main() {
		vColor = color;
		gl_Position = vec4(pos, 1.0);
	}
};

auto fShader = q{
	varying vec4 vColor;

	void main() {
		gl_FragColor = vColor;
	}
};
*/

auto vShader = q{
	attribute vec3 pos;
	attribute vec4 color;
  attribute vec2 texCoord;
	varying vec4 vColor;
  varying vec2 vTexCoord;

	void main() {
		vColor = color;
    vTexCoord = texCoord;
		gl_Position = vec4(pos, 1.0);
	}
};

auto fShader = q{
  uniform sampler2D tex;
	varying vec4 vColor;
  varying vec2 vTexCoord;

	void main() {
    vec4 smpColor = texture2D(tex, vTexCoord);
    // What's the difference between texture and texture2D ?????
    // vec4 smpColor = texture(tex, vTexCoord);
		gl_FragColor = smpColor;
		//gl_FragColor = vColor * smpColor;
	}
};

class Shader {
  public:
    this(T)(T type, string shaderCode) {
      create_shader(type);
      attach_compile(shaderCode);
    }

    ~this() {
      glDeleteShader(_shader); 
    }

		void create_shader(T)(T type) {
			_shader = glCreateShader(type);
			enforce(_shader, "glCreateShader() faild");
		}

		void attach_compile(string shaderCode) {
			auto fst = &shaderCode[0];
			int len = shaderCode.length;
			glShaderSource(_shader, 1, &fst, &len);
			glCompileShader(_shader);

			GLint result;
			glGetShaderiv(_shader, GL_COMPILE_STATUS, &result);
			enforce(result != GL_FALSE, "glCompileShader() faild");
		}

		alias _shader this;
		GLuint _shader;
}

class ShaderProgram {
	public:
		this(T)(T vs, T fs) {
			_program = glCreateProgram();
			enforce(_program, "glCreateProgram() faild");

			glAttachShader(_program, vs);
			glAttachShader(_program, fs);
		}	

		void use() {
			glLinkProgram(_program);

			int linked;
			glGetProgramiv(_program, GL_LINK_STATUS, &linked);
			enforce(linked != GL_FALSE, "glLinkProgram() faild");

			glUseProgram(_program);
		}

		alias _program this;
		GLuint _program;
}
