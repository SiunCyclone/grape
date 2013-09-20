module orange.shader;

import std.exception : enforce;
import opengl.glew;

import std.stdio;

enum ShaderProgramType {
  ClassicNormal = 0,
  ClassicTexture = 1,
  Font = 2,
  Normal = 3,
  Texture = 4,
  Diffuse = 5,
  ADS = 6,
  GaussianX = 7,
  GaussianY = 8,
}
// TODO name
enum {
  VertexShader = GL_VERTEX_SHADER,
  FragmentShader = GL_FRAGMENT_SHADER 
}

mixin template ClassicNormalShader() {
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
}

mixin template ClassicTextureShader() {
  auto vClassicTexture = q{
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

  auto fClassicTexture = q{
    uniform sampler2D tex;
    varying vec4 vColor;
    varying vec2 vTexCoord;

    void main() {
      vec4 smpColor = texture(tex, vTexCoord);
      // vec4 smpColor = texture(tex, vTexCoord);
      gl_FragColor = smpColor;
      //gl_FragColor = vColor * smpColor;
    }
  };
}

mixin template FontShader() {
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
      vec4 smpColor = texture(tex, vTexCoord);
      gl_FragColor = smpColor;
    }
  };
}

mixin template NormalShader() {
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

mixin template TextureShader() {
  auto vTexture = q{
    attribute vec3 pos;
    attribute vec4 color;
    attribute vec2 texCoord;
    varying vec4 vColor;
    varying vec2 vTexCoord;
    uniform mat4 pvmMatrix;

    void main() {
      vColor = color;
      vTexCoord = texCoord;
      gl_Position = pvmMatrix * vec4(pos, 1.0); 
    }
  };

  auto fTexture = q{
    uniform sampler2D tex;
    varying vec4 vColor;
    varying vec2 vTexCoord;

    void main() {
      vec4 smpColor = texture(tex, vTexCoord);
      //gl_FragColor = vColor;
      gl_FragColor = smpColor;
      //gl_FragColor = smpColor + vColor;
      //gl_FragColor = vec4(smpColor.rgb, vColor.a * smpColor.a);
    }
  };
}

mixin template DiffuseShader() {
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
}

mixin template ADSShader() {
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

mixin template GaussianXShader() {
  auto vGaussianX = q{
    attribute vec2 pos;
    attribute vec2 texCoord;
    varying vec2 vTexCoord;

    void main() {
      gl_Position = vec4(pos, 0.0, 1.0); 
      vTexCoord = texCoord;
    }
  };

  auto fGaussianX = q{
    uniform sampler2D tex;
    uniform float weight[8];
    varying vec2 vTexCoord;

    void main() {
      //vec2 t = vec2(1.0) / vec2(128.0);
      vec2 t = vec2(1.0) / vec2(256.0);
      //vec2 t = vec2(1.0) / vec2(512.0);
      vec4 color = texture(tex, vTexCoord) * weight[0];

      for (int i=1; i<weight.length(); ++i) {
        color += texture(tex, (gl_FragCoord.xy + vec2(-1.0*i, 0.0)) * t) * weight[i];
        color += texture(tex, (gl_FragCoord.xy + vec2(1.0*i, 0.0)) * t) * weight[i];
      }

      gl_FragColor = color;
    }
  };
}

mixin template GaussianYShader() {
  auto vGaussianY = q{
    attribute vec2 pos;
    attribute vec2 texCoord;
    varying vec2 vTexCoord;

    void main() {
      gl_Position = vec4(pos, 0.0, 1.0); 
      vTexCoord = texCoord;
    }
  };

  auto fGaussianY = q{
    uniform sampler2D tex;
    uniform int type;
    uniform float weight[8];
    varying vec2 vTexCoord;

    void main() {
      //vec2 t = vec2(1.0) / vec2(128.0);
      vec2 t = vec2(1.0) / vec2(256.0);
      //vec2 t = vec2(1.0) / vec2(512.0);
      vec4 color = texture(tex, vTexCoord) * weight[0];

      for (int i=1; i<weight.length(); ++i) {
        color += texture(tex, (gl_FragCoord.xy + vec2(0.0, -1.0*i)) * t) * weight[i];
        color += texture(tex, (gl_FragCoord.xy + vec2(0.0, 1.0*i)) * t) * weight[i];
      }

      gl_FragColor = color;
    }
  };
}

class Shader {
  public:
    this(T)(T type) {
      generate(type);
    };

    this(T)(T type, string shaderCode) {
      this(type);
      compile(shaderCode);
    }

    ~this() {
      eliminate();
    }

		void compile(string shaderCode) {
			auto fst = &shaderCode[0];
			int len = shaderCode.length;
			glShaderSource(_shader, 1, &fst, &len);
			glCompileShader(_shader);

			GLint result;
			glGetShaderiv(_shader, GL_COMPILE_STATUS, &result);
			enforce(result != GL_FALSE, "glCompileShader() faild");
		}

		alias _shader this; // TODO

  private:
		void generate(T)(T type) {
			_shader = glCreateShader(type);
			enforce(_shader, "glCreateShader() faild");
		}

    void eliminate() {
      glDeleteShader(_shader); 
    }

		GLuint _shader;
}

class ShaderProgram {
  public:
    this() {
      generate();
    }

    ~this() {
      eliminate();
    }

    GLuint attach(T)(T vs, T fs) {
			glAttachShader(_program, vs);
			glAttachShader(_program, fs);
			glLinkProgram(_program);

			int linked;
			glGetProgramiv(_program, GL_LINK_STATUS, &linked);
			enforce(linked != GL_FALSE, "glLinkProgram() faild");

      return _program;
    }

    void use() {
			glUseProgram(_program);
    }

    alias _program this;

  private:
    void generate() {
			_program = glCreateProgram();
			enforce(_program, "glCreateProgram() faild");
    }

    void eliminate() {
      glDeleteProgram(_program);
    }

    GLuint _program;
}

// TODO 軽量化
class ShaderProgramHdr {
	public:
    this(ShaderProgramType[] typeList...) {
      if (typeList.length == 0)
        typeList = [ ShaderProgramType.ClassicNormal,
                     ShaderProgramType.ClassicTexture,
                     ShaderProgramType.Font,
                     ShaderProgramType.Normal,
                     ShaderProgramType.Texture,
                     ShaderProgramType.Diffuse,
                     ShaderProgramType.ADS,
                     ShaderProgramType.GaussianX,
                     ShaderProgramType.GaussianY ];


      enable_program(typeList);
      //writeln(_list.length);
    }

		void use(ShaderProgramType type) {
      _current = type;
      _list[_current].use();
    }

    @property {
      GLuint current() {
        return _list[_current];
      }
    }

  private:
    // TODO delegate
    void enable_program(ShaderProgramType[] typeList) {
      foreach (type; typeList) {
        final switch (type) {
          case ShaderProgramType.ClassicNormal:
            mixin ClassicNormalShader;
            add_program(type, vClassicNormal, fClassicNormal);
            break;
          case ShaderProgramType.ClassicTexture:
            mixin ClassicTextureShader;
            add_program(type, vClassicTexture, fClassicTexture);
            break;
          case ShaderProgramType.Font:
            mixin FontShader;
            add_program(type, vFont, fFont);
            break;
          case ShaderProgramType.Normal:
            mixin NormalShader;
            add_program(type, vNormal, fNormal);
            break;
          case ShaderProgramType.Texture:
            mixin TextureShader;
            add_program(type, vTexture, fTexture);
            break;
          case ShaderProgramType.Diffuse:
            mixin DiffuseShader;
            add_program(type, vDiffuse, fDiffuse);
            break;
          case ShaderProgramType.ADS:
            mixin ADSShader;
            add_program(type, vADS, fADS);
            break;
          case ShaderProgramType.GaussianX:
            mixin GaussianXShader;
            add_program(type, vGaussianX, fGaussianX);
            break;
          case ShaderProgramType.GaussianY:
            mixin GaussianYShader;
            add_program(type, vGaussianY, fGaussianY);
            break;
        }
      } 
    }

    void add_program(T)(ShaderProgramType type, T vShaderSource, T fShaderSource) {
      Shader vs = new Shader(VertexShader, vShaderSource);
      Shader fs = new Shader(FragmentShader, fShaderSource);

      ShaderProgram program = new ShaderProgram;
      program.attach(vs, fs);
      _list[type] = program;
    }

    ShaderProgramType _current;
    ShaderProgram[ShaderProgramType] _list;
}

