module orange.shader;

import std.exception : enforce;
//import opengl.glew;
import derelict.opengl3.gl3;

import std.stdio;
import std.traits : EnumMembers;

enum ShaderType {
  Vertex = GL_VERTEX_SHADER,
  Fragment = GL_FRAGMENT_SHADER 
}

enum ShaderProgramType {
  Custom = 1000,
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

mixin template ClassicNormalShaderSource() {
  void delegate(out string, out string) ClassicNormalShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec4 color;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = vec4(pos, 1.0);
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template ClassicTextureShaderSource() {
  void delegate(out string, out string) ClassicTextureShader = (out string vShader, out string fShader) {
    vShader = q{
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

    fShader = q{
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
  };
}

mixin template FontShaderSource() {
  void delegate(out string, out string) FontShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        vTexCoord = texCoord;
        gl_Position = vec4(pos, 1.0);
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
      }
    };
  };
}

mixin template NormalShaderSource() {
  void delegate(out string, out string) NormalShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec4 color;
      uniform mat4 pvmMatrix;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = pvmMatrix * vec4(pos, 1.0);
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template TextureShaderSource() {
  void delegate(out string, out string) TextureShader = (out string vShader, out string fShader) {
    vShader = q{
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

    fShader = q{
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
  };
}

mixin template DiffuseShaderSource() {
  void delegate(out string, out string) DiffuseShader = (out string vShader, out string fShader) {
    vShader = q{
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

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template ADSShaderSource() {
  void delegate(out string, out string) ADSShader = (out string vShader, out string fShader) {
    vShader = q{
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

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

// Weightにリネーム
mixin template GaussianXShaderSource() {
  void delegate(out string, out string) GaussianXShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec2 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        gl_Position = vec4(pos, 0.0, 1.0); 
        vTexCoord = texCoord;
      }
    };

    fShader = q{
      uniform sampler2D tex;
      uniform float weight[8];
      varying vec2 vTexCoord;

      void main() {
        vec2 t = vec2(1.0) / vec2(128.0);
        //vec2 t = vec2(1.0) / vec2(256.0);
        //vec2 t = vec2(1.0) / vec2(512.0);
        vec4 color = texture(tex, vTexCoord) * weight[0];

        for (int i=1; i<weight.length(); ++i) {
          color += texture(tex, (gl_FragCoord.xy + vec2(-1.0*i, 0.0)) * t) * weight[i];
          color += texture(tex, (gl_FragCoord.xy + vec2(1.0*i, 0.0)) * t) * weight[i];
        }

        gl_FragColor = color;
      }
    };
  };
}

mixin template GaussianYShaderSource() {
  void delegate(out string, out string) GaussianYShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec2 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        gl_Position = vec4(pos, 0.0, 1.0); 
        vTexCoord = texCoord;
      }
    };

    fShader = q{
      uniform sampler2D tex;
      uniform float weight[8];
      varying vec2 vTexCoord;

      void main() {
        vec2 t = vec2(1.0) / vec2(128.0);
        //vec2 t = vec2(1.0) / vec2(256.0);
        //vec2 t = vec2(1.0) / vec2(512.0);
        //vec4 color = texture(tex, vTexCoord);
        vec4 color = texture(tex, vTexCoord) * weight[0];

        for (int i=1; i<weight.length(); ++i) {
          color += texture(tex, (gl_FragCoord.xy + vec2(0.0, -1.0*i)) * t) * weight[i];
          color += texture(tex, (gl_FragCoord.xy + vec2(0.0, 1.0*i)) * t) * weight[i];
        }

        gl_FragColor = color;
      }
    };
  };
}

mixin template FilterShaderSource() {
  void delegate(out string, out string) FilterShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;
      //uniform mat4 pvmMatrix;

      void main() {
        //gl_Position = pvmMatrix * vec4(pos, 0.0, 1.0); 
        gl_Position = vec4(pos, 1.0); 
        vTexCoord = texCoord;
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
        //gl_FragColor = smpColor + vec4(0.2, 0.0, 0.0, 1.0);
      }
    };
  };
}

class ShaderSource {
  public:
    static this() {
      init();
    }

    static void delegate(out string, out string) load(ShaderProgramType type) {
      return _loader[type];
    }

    static void add(void delegate(out string, out string) CustomShader) {
      _loader[ShaderProgramType.Custom] = CustomShader;
    }

  private:
    static void init() {
      mixin ClassicNormalShaderSource;
      mixin ClassicTextureShaderSource;
      mixin FontShaderSource;
      mixin NormalShaderSource;
      mixin TextureShaderSource;
      mixin DiffuseShaderSource;
      mixin ADSShaderSource;
      mixin GaussianXShaderSource;
      mixin GaussianYShaderSource;

      _loader[ShaderProgramType.ClassicNormal] = ClassicNormalShader;
      _loader[ShaderProgramType.ClassicTexture] = ClassicTextureShader;
      _loader[ShaderProgramType.Font] = FontShader;
      _loader[ShaderProgramType.Normal] = NormalShader;
      _loader[ShaderProgramType.Texture] = TextureShader;
      _loader[ShaderProgramType.Diffuse] = DiffuseShader;
      _loader[ShaderProgramType.ADS] = ADSShader;
      _loader[ShaderProgramType.GaussianX] = GaussianXShader;
      _loader[ShaderProgramType.GaussianY] = GaussianYShader;
    }

    static void delegate(out string, out string)[ShaderProgramType] _loader;
}

class Shader {
  public:
    this(ShaderType type) {
      generate(type);
    };

    this(ShaderType type, string shaderCode) {
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
		void generate(ShaderType type) {
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

    this(Shader vs, Shader fs) {
      this();
      attach(vs, fs);
    }

    ~this() {
      eliminate();
    }

    void attach(T)(T vs, T fs) {
			glAttachShader(_program, vs);
			glAttachShader(_program, fs);
			glLinkProgram(_program);

			int linked;
			glGetProgramiv(_program, GL_LINK_STATUS, &linked);
			enforce(linked != GL_FALSE, "glLinkProgram() faild");
    }

    void use() {
			glUseProgram(_program);
    }

    alias _program this;
    GLuint _program;

  private:
    void generate() {
			_program = glCreateProgram();
			enforce(_program, "glCreateProgram() faild");
    }

    void eliminate() {
      glDeleteProgram(_program);
    }

}

// TODO いらない
class ShaderProgramHdr {
	public:
    this(ShaderProgramType[] typeList...) {
      if (typeList.length == 0) {
        foreach(type; EnumMembers!ShaderProgramType)
          typeList ~= type;
      }

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
    void enable_program(ShaderProgramType[] typeList) {
      string vShader, fShader;
      foreach (type; typeList) {
        ShaderSource.load(type)(vShader, fShader);
        add_program(type, vShader, fShader);
      } 
    }

    void add_program(T)(ShaderProgramType type, T vShaderSource, T fShaderSource) {
      Shader vs = new Shader(ShaderType.Vertex, vShaderSource);
      Shader fs = new Shader(ShaderType.Fragment, fShaderSource);
      ShaderProgram program = new ShaderProgram(vs, fs);
      _list[type] = program;
    }

    ShaderProgramType _current;
    ShaderProgram[ShaderProgramType] _list;
}

