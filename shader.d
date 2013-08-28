module orange.shader;

import std.exception : enforce;
import opengl.glew;

// name
enum {
  VertexShader = GL_VERTEX_SHADER,
  FragmentShader = GL_FRAGMENT_SHADER 
}

mixin template ShaderSource() {
  // Normal
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

  // Texture
  auto vTexShader = q{
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

  auto fTexShader = q{
    uniform sampler2D tex;
    varying vec4 vColor;
    varying vec2 vTexCoord;

    void main() {
      vec4 smpColor = texture2D(tex, vTexCoord);
      // What's the difference between texture and texture2D ?????
      // vec4 smpColor = texture(tex, vTexCoord);
      gl_FragColor = smpColor;
      //gl_FragColor = vColor;
    }
  };

  // Font
  auto vFontShader = q{
    attribute vec3 pos;
    attribute vec2 texCoord;
    varying vec2 vTexCoord;

    void main() {
      vTexCoord = texCoord;
      gl_Position = vec4(pos, 1.0);
    }
  };

  auto fFontShader = q{
    uniform sampler2D tex;
    varying vec2 vTexCoord;

    void main() {
      vec4 smpColor = texture2D(tex, vTexCoord);
      gl_FragColor = smpColor;
    }
  };
}

class Shader {
  public:
    this(T)(T type, string shaderCode) {
      create_shader(type);
      attach_compile(shaderCode);
    }

    ~this() {
      glDeleteShader(_shader); 
    }

		alias _shader this;
		GLuint _shader;

  private:
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
}

enum ShaderProgramType {
  Normal = 0,
  Texture = 1,
  Font = 2
}

class ShaderProgramHandler {
	public:
    this(string type) {
      if (type == "default")
        create_default_program();
    }

    ~this() {
      foreach (program; _list)
        glDeleteProgram(program);
    }

		void enable(ShaderProgramType type) {
      _current = type;
    }

		void activate() {
			glUseProgram(_list[_current]);
		}

    @property {
      GLuint curProgram() {
        return _list[_current];
      }
    }

  private:
    mixin ShaderSource;

    void create_default_program() {
      Shader vs;
      Shader fs;

      vs = new Shader(VertexShader, vShader);
      fs = new Shader(FragmentShader, fShader);
      _list ~= create_program(vs, fs);

      vs = new Shader(VertexShader, vTexShader);
      fs = new Shader(FragmentShader, fTexShader);
      _list ~= create_program(vs, fs);

      vs = new Shader(VertexShader, vFontShader);
      fs = new Shader(FragmentShader, fFontShader);
      _list ~= create_program(vs, fs);
    }

    GLuint create_program(T)(T vs, T fs) {
			GLuint program = glCreateProgram();
			enforce(program, "glCreateProgram() faild");

			glAttachShader(program, vs);
			glAttachShader(program, fs);
			glLinkProgram(program);

			int linked;
			glGetProgramiv(program, GL_LINK_STATUS, &linked);
			enforce(linked != GL_FALSE, "glLinkProgram() faild");

      return program;
    }

    ShaderProgramType _current;
    GLuint[] _list;
}
