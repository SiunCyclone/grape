module grape.material;

import derelict.opengl3.gl3;
import std.variant;
import std.stdio;
import grape.shader;
import grape.buffer;

alias AttributeType = Algebraic!(float[], int);
alias UniformType = Algebraic!(float[16], string, int, float[2], float[8], float);

class Material {
  alias ParamType = Algebraic!(int[], bool, string, int, DrawMode, Texture, AttributeType[string][string], UniformType[string][string]);
  public:
    this(T...)(T params) {
      init();
      set_param(params);
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

    @property {
      ShaderProgram program() {
        return _program;
      }

      ParamType[string] params() {
        return _params;
      }

      string name() {
        return _name;
      }
    }

  protected:
    void init() {
      _name = "none";
      _params["drawMode"] = DrawMode.Triangles;
    }

    void create_program(in string vertexShaderSource, in string fragmentShaderSource) {
      Shader vs = new Shader(ShaderType.Vertex, vertexShaderSource);
      Shader fs = new Shader(ShaderType.Fragment, fragmentShaderSource);
      _program = new ShaderProgram(vs, fs);
    }

    ParamType[string] _params;
    ShaderProgram _program;
    string _name;
}

class ColorMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _name = "color";
      _params["drawMode"] = DrawMode.Triangles;
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec4 color;
      uniform mat4 pvmMatrix;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = pvmMatrix * vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}

class DiffuseMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _name = "diffuse";
      _params["drawMode"] = DrawMode.Triangles;
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec3 normal;
      attribute vec4 color;

      uniform vec3 lightPosition;

      uniform mat4 pvmMatrix;
      uniform mat4 invMatrix;

      varying vec4 vColor;

      void main() {
        vec3 invLight = normalize(invMatrix * vec4(lightPosition, 0.0)).xyz;
        float diffuse = clamp(dot(normal, invLight), 0.1, 1.0);
        vColor = color * vec4(vec3(diffuse), 1.0);
        gl_Position = pvmMatrix * vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}

class ADSMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _name = "ads";
      _params["drawMode"] = DrawMode.Triangles;
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
      _params["ambientColor"] = [ 0, 0, 0 ];
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec3 normal;
      attribute vec4 color;

      uniform vec3 lightPosition;
      uniform vec3 eyePosition;
      uniform vec4 ambientColor;

      uniform mat4 pvmMatrix;
      uniform mat4 invMatrix;

      varying vec4 vColor;

      void main() {
        vec3 invLight = normalize(invMatrix * vec4(lightPosition, 0.0)).xyz;
        vec3 invEye = normalize(invMatrix * vec4(eyePosition, 0.0)).xyz;
        vec3 halfLE = normalize(invLight + invEye);
        float diffuse = clamp(dot(normal, invLight), 0.0, 1.0);
        float specular = pow(clamp(dot(normal, halfLE), 0.0, 1.0), 50.0);
        vec4 light = color * vec4(vec3(diffuse), 1.0) + vec4(vec3(specular), 1.0);
        vColor = light + ambientColor;
        gl_Position = pvmMatrix * vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}

class TextureMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _name = "texture";
      _params["drawMode"] = DrawMode.Triangles;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec2 position;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;
      //uniform mat4 pvmMatrix;

      void main() {
        vTexCoord = texCoord;
        gl_Position = vec4(position, 0.0, 1.0);
        //gl_Position = pvmMatrix * vec4(position, 0.0, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
      }
    };
}

class ShaderMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(*_params["vertexShader"].peek!(string), *_params["fragmentShader"].peek!(string));
    }

    void set_uniform(T)(string key, T value) {
      (*_params["uniforms"].peek!(UniformType[string][string]))[key]["value"] = value;
    }

  protected:
    override void init() {
      import grape.camera;

      _name = "shader";
      _params["drawMode"] = DrawMode.Triangles;
      _params["vertexShader"] = q{
        attribute vec3 position;
        uniform mat4 pvmMatrix;

        void main() {
          gl_Position = pvmMatrix * vec4(position, 1.0);
        }
      };
      _params["fragmentShader"] = q{
        void main() {
          gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
        }
      };
      _params["uniforms"] = [ "pvmMatrix": [ "type": UniformType("mat4v"), "value": UniformType((new Camera).pvMat4.mat) ] ];
      _params["attributes"] = [ "position": [ "type": AttributeType(3), "value": AttributeType([ 0.0f, 0.0f, 0.0f ]) ] ];
      _params["map"] = new Texture;
    }
}

