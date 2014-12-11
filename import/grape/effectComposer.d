module grape.effectComposer;

import std.variant;
import std.stdio;
import std.math;
import grape.renderer;
import grape.scene;
import grape.camera;
import grape.shader;
import grape.buffer;
import grape.geometry;
import grape.material;
import grape.mesh;
import derelict.opengl3.gl3;

class EffectComposer {
  public:
    this(Renderer renderer) {
      _renderer = renderer;

      _width = WINDOW_WIDTH;
      _height = WINDOW_HEIGHT;
    }

    void add_pass(Pass pass) {
      _passes ~= pass;

      auto tmp = new Texture;
      tmp.create(_width, _height, null, GL_RGBA);
      _textures ~= tmp;
    }

    void render() {
      foreach(i, pass; _passes) {
        auto writeTexture = _textures[i];
        auto readTexture = _textures[(i==0) ? i : i-1];

        pass.render(_renderer, writeTexture, readTexture);
      }
      _renderer.render(this.get_texture);
    }

    void reset() {
      _passes.length = 0;
    }

    void set_size(in int width, in int height) {
      _width = width;
      _height = height;
    }

    Texture get_texture(in size_t i) {
      assert(i < _textures.length);
      return _textures[i];
    }

    Texture get_texture() {
      return _textures[$-1];
    }

  private:
    Renderer _renderer;
    Pass[] _passes;
    Texture[] _textures;
    int _width, _height;
}

class Pass {
  public:
    this() {
      _fbo = new FBO;
    }

  protected:
    abstract void render(Renderer, Texture, Texture);

    void create_fbo(Texture writeTexture) {
      _fbo.create(writeTexture);
    }

    void binded_scope(in void delegate() dg, in int width, in int height) {
      _fbo.binded_scope({
        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ZERO); // DefaultBlend
        glViewport(0, 0, width, height);
        dg();
        glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
        glDisable(GL_BLEND);
      });
    }

    Scene _scene;
    Camera _camera;
    PlaneGeometry _geometry;
    Mesh _screen;

  private:
    FBO _fbo;
}

class RenderPass : Pass {
  public:
    this(Scene scene, Camera camera) {
      _scene = scene;
      _camera = camera;
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
      create_fbo(writeTexture);

      binded_scope({
        renderer.render(_scene, _camera);
      }, writeTexture.w, writeTexture.h);
    }
}

class BlurPass : Pass {
  public:
    this(int width, int height, in float weight=50.0) {
      _widthBlurTexture = new Texture;

      _scene = new Scene;
      _camera = new OrthographicCamera(-cast(float)width/height, cast(float)width/height, -1, 1, 1, 100);
      _geometry = new PlaneGeometry(2, 2);
      float[2] resolution = [ WINDOW_WIDTH, WINDOW_HEIGHT ];
      _material = new ShaderMaterial(
        "vertexShader", vertexShaderSource,
        "fragmentShader", fragmentShaderSource,
        "uniforms", [
          "tex": [ "type": UniformType("1i"), "value": UniformType(0) ],
          "weight": [ "type": UniformType("1fv"), "value": UniformType(gauss_weight(weight)) ],
          "type": [ "type": UniformType("1i"), "value": UniformType(0) ],
          "resolution": [ "type": UniformType("2fv"), "value": UniformType(resolution) ]
        ],
        "attributes", [
          "texCoord": [ "type": AttributeType(2), "value": AttributeType([ 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f ]) ]
        ]
      );
      _screen = new Mesh(_geometry, _material);
      _scene.add(_screen);
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
      auto widthBlur = {
        _widthBlurTexture.create(readTexture.w, readTexture.h, null, GL_RGBA);
        create_fbo(_widthBlurTexture);
        _material.set_param("map", readTexture);
        _material.set_uniform("type", 0);

        binded_scope({
          renderer.render(_scene, _camera);
        }, _widthBlurTexture.w, _widthBlurTexture.h);
      };

      auto heightBlur = {
        create_fbo(writeTexture);
        _material.set_param("map", _widthBlurTexture);
        _material.set_uniform("type", 1);

        binded_scope({
          renderer.render(_scene, _camera);
        }, writeTexture.w, writeTexture.h);
      };

     widthBlur();
     heightBlur();
    }

  private:
    float[8] gauss_weight(in float eRange) {
      float[8] weight;
      float t = 0.0;
      float d = eRange^^2 / 100;
      for (int i=0; i<weight.length; ++i) {
        float r = 1.0 + 2.0*i;
        float w = exp(-0.5 * r^^2 / d);
        weight[i] = w;
        if (i > 0) w *= 2.0;
          t += w;
      }
      for (int i=0; i<weight.length; ++i){
        weight[i] /= t;
      }
      return weight;
    }

    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        vTexCoord = texCoord;
        gl_Position = vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      uniform sampler2D tex;
      uniform float weight[8];
      uniform int type;
      uniform vec2 resolution;
      varying vec2 vTexCoord;

      void main() {
        vec2 t = vec2(1.0) / resolution;
        vec4 color = texture(tex, vTexCoord) * weight[0];

        if (type == 0) {
          for (int i=1; i<8; ++i) {
            color += texture(tex, (gl_FragCoord.xy + vec2(-1*i, 0)) * t) * weight[i];
            color += texture(tex, (gl_FragCoord.xy + vec2(1*i, 0)) * t) * weight[i];
          }

        } else if (type == 1) {
          for (int i=1; i<8; ++i) {
            color += texture(tex, (gl_FragCoord.xy + vec2(0, -1*i)) * t) * weight[i];
            color += texture(tex, (gl_FragCoord.xy + vec2(0, 1*i)) * t) * weight[i];
          }
        }

        gl_FragColor = color;
      }
    };

    ShaderMaterial _material;
    Texture _widthBlurTexture;
    int _width, _height;
}

class GlowPass : Pass {
  public:
    this(in int width, in int height, in int resX, in int resY) {
      _blurPass = new BlurPass(width, height);
      _blurTexture= new Texture;
      _blurTexture.create(WINDOW_WIDTH, WINDOW_HEIGHT, null, GL_RGBA);
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
      create_fbo(writeTexture);
      _blurPass.render(renderer, _blurTexture, readTexture);

      binded_scope({
        glBlendFunc(GL_ONE, GL_ONE);
        renderer.render(readTexture);
        renderer.render(_blurTexture);
      }, writeTexture.w, writeTexture.h);
    }

  private:
    TextureMaterial _material;
    BlurPass _blurPass;
    Texture _blurTexture;
}

class ShaderPass : Pass {
  public:
    this(Shader vShader, Shader fShader) {
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
    }

  private:
}

