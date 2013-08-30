module orange.shader;

import std.exception : enforce;
import opengl.glew;

// name
enum {
  VertexShader = GL_VERTEX_SHADER,
  FragmentShader = GL_FRAGMENT_SHADER 
}

mixin template ShaderSource() {
  auto vClassicNormal = q{
    attribute vec3 pos;
    attribute vec4 color;
    varying vec4 vColor;

    void main() {
      vColor = color;
      gl_Position = vec4(pos, 1.0);
    }
  };

  auto fClassicNormal = q{
    varying vec4 vColor;

    void main() {
      gl_FragColor = vColor;
    }
  };

  auto vClassicTex = q{
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

  auto fClassicTex = q{
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

  auto vFont = q{
    attribute vec3 pos;
    attribute vec2 texCoord;
    varying vec2 vTexCoord;

    void main() {
      vTexCoord = texCoord;
      gl_Position = vec4(pos, 1.0);
    }
  };

  auto fFont = q{
    uniform sampler2D tex;
    varying vec2 vTexCoord;

    void main() {
      vec4 smpColor = texture2D(tex, vTexCoord);
      gl_FragColor = smpColor;
    }
  };

  auto vNormal = q{
    attribute vec3 pos;
    attribute vec4 color;
    uniform mat4 pvmMatrix;
    varying vec4 vColor;

    void main() {
      vColor = color;
      gl_Position = pvmMatrix * vec4(pos, 1.0);
    }
  };

  auto fNormal = q{
    varying vec4 vColor;

    void main() {
      gl_FragColor = vColor;
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
  ClassicNormal = 0,
  ClassicTexture = 1,
  Font = 2,
  Normal = 3
}

class ShaderProgramHandler {
	public:
    this(string type) {
      // change
      if (type == "default")
        create_default_program();
    }

    ~this() {
      foreach (program; _list)
        glDeleteProgram(program);
    }

		void use(ShaderProgramType type) {
      _current = type;
			glUseProgram(_list[_current]);
    }

    @property {
      GLuint curProgram() {
        return _list[_current];
      }
    }

  private:
    // switch
    mixin ShaderSource;

    void create_default_program() {
      add_program(vClassicNormal, fClassicNormal);
      add_program(vClassicTex, fClassicTex);
      add_program(vFont, fFont);
      add_program(vNormal, fNormal);
    }

    void add_program(T)(T vShaderSource, T fShaderSource) {
      Shader vs = new Shader(VertexShader, vShaderSource);
      Shader fs = new Shader(FragmentShader, fShaderSource);
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
