module grape.material;

import std.variant;
import std.stdio;
import grape.shader;

class Material {
  alias ParamType = Algebraic!(int[], bool, string);

  public:
    this(T...)(T params) {
      init();
      set_param(params);
    }

  protected:
    void init() {
      _params["vertexShader"] = "Set user's vertexShaderSource here";
      _params["fragmentShader"] = "Set user's fragmentShaderSource here";
    }

    void set_param(T...)(T params) {
      static if (params.length) {
        static assert(params.length % 2 == 0, "The number of material's parameter must be an even number.");
        auto key = params[0];
        static assert(is(typeof(key) : string), "The material parameter's key must be string.");
        assert(key in _params, "Wrong material parameter's key named \"" ~ key ~ "\"");
        auto value = params[1];

        _params[key] = value;
        set_param(params[2..$]);
      }
    }

    void create_program(in string vertexShaderSource, in string fragmentShaderSource) {
      Shader vs = new Shader(ShaderType.Vertex, vertexShaderSource);
      Shader fs = new Shader(ShaderType.Fragment, fragmentShaderSource);
      _program = new ShaderProgram(vs, fs);
    }

    ParamType[string] _params;
    ShaderProgram _program;
}

class ColorMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);

      immutable vertexShaderSource = q{
        attribute vec3 position;
        attribute vec4 color;
        varying vec4 vColor;

        void main() {
          vColor = color;
          gl_Position = vec4(position, 1.0);
        }
      };

      immutable fragmentShaderSource = q{
        varying vec4 vColor;

        void main() {
          gl_FragColor = vColor;
        }
      };

      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
    }
}

