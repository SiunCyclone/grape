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

  auto vDiffuse = q{
    attribute vec3 pos;
    attribute vec3 normal;
    attribute vec4 color;

    uniform vec3 lightPos;

    uniform mat4 pvmMatrix;
    uniform mat4 invMatrix;

    varying vec4 vColor;
    
    void main() {
      vec3 invLight = normalize(invMatrix * vec4(lightPos, 0.0));
      float diffuse = clamp(dot(normal, invLight), 0.1, 1.0);
      vColor = color * vec4(vec3(diffuse), 1.0);
      gl_Position = pvmMatrix * vec4(pos, 1.0); 
    }
  };

  auto fDiffuse = q{
    varying vec4 vColor;

    void main() {
      gl_FragColor = vColor;
    }
  };

  auto vADS = q{
    attribute vec3 pos;
    attribute vec3 normal;
    attribute vec4 color;

    uniform vec3 lightPos;
    uniform vec3 eyePos;
    uniform vec4 ambientColor;

    uniform mat4 pvmMatrix;
    uniform mat4 invMatrix;

    varying vec4 vColor;
    
    void main() {
      vec3 invLight = normalize(invMatrix * vec4(lightPos, 0.0));
      vec3 invEye = normalize(invMatrix * vec4(eyePos, 0.0));
      vec3 halfLE = normalize(invLight + invEye);
      float diffuse = clamp(dot(normal, invLight), 0.0, 1.0);
      float specular = pow(clamp(dot(normal, halfLE), 0.0, 1.0), 50.0);
      vec4 light = color * vec4(vec3(diffuse), 1.0) + vec4(vec3(specular), 1.0);
      vColor = light + ambientColor;
      gl_Position = pvmMatrix * vec4(pos, 1.0); 
    }
  };

  auto fADS = q{
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
  Normal = 3,
  Diffuse = 4,
  ADS = 5,
}

class ShaderProgramHdr {
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
      add_program(vDiffuse, fDiffuse);
      add_program(vADS, fADS);
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
