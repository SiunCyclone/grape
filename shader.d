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
  Gaussian = 7,
}
// name
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
      vec4 smpColor = texture2D(tex, vTexCoord);
      // What's the difference between texture and texture2D ?????
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
      vec4 smpColor = texture2D(tex, vTexCoord);
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
      vec4 smpColor = texture2D(tex, vTexCoord);
      //gl_FragColor = vColor;
      gl_FragColor = smpColor;
      //gl_FragColor = smpColor * vColor;
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

mixin template GaussianShader() {
  auto vGaussian = q{
    attribute vec2 pos;
    attribute vec2 texCoord;
    uniform mat4 pvmMatrix;
    varying vec2 vTexCoord;

    void main() {
      gl_Position = pvmMatrix * vec4(pos, 0.0, 1.0); 
      vTexCoord = texCoord;
    }
  };

  auto fGaussian = q{
    uniform sampler2D tex;
    uniform int type;
    uniform float weight[10];
    varying vec2 vTexCoord;

    void main() {
      vec2 t = vTexCoord / gl_FragCoord.xy;
      vec4 color = texture2D(tex, vTexCoord);

      int i;
      if (type == 1) {
        color *= weight[0];
        for (i=1; i<weight.length(); ++i) {
          color += texture2D(tex, (vTexCoord + vec2(-float(i), 0.0)) * t) * weight[i];
          color += texture2D(tex, (vTexCoord + vec2(float(i), 0.0)) * t) * weight[i];
        }
      } else if (type == 2) {
        color*= weight[0];
        for (i=1; i<weight.length(); ++i) {
          color += texture2D(tex, (vTexCoord + vec2(0.0, -float(i))) * t) * weight[i];
          color += texture2D(tex, (vTexCoord + vec2(0.0, float(i))) * t) * weight[i];
        }
      }
      gl_FragColor = color;
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
                     ShaderProgramType.Gaussian ];

      enable_program(typeList);
      //writeln(_list.length);
    }

    ~this() {
      foreach (program; _list)
        glDeleteProgram(program);
    }

    // delegate
    void enable_program(ShaderProgramType[] typeList...) {
      foreach (type; typeList) {
        switch (type) {
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
          case ShaderProgramType.Gaussian:
            mixin GaussianShader;
            add_program(type, vGaussian, fGaussian);
            break;
          default:
        }
      } 
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
    void add_program(T)(ShaderProgramType type, T vShaderSource, T fShaderSource) {
      Shader vs = new Shader(VertexShader, vShaderSource);
      Shader fs = new Shader(FragmentShader, fShaderSource);
      _list[type] = create_program(vs, fs);
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
    GLuint[ShaderProgramType] _list;
}
