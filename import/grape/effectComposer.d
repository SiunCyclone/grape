module grape.effectComposer;

import std.variant;
import grape.renderer;
import grape.scene;
import grape.camera;
import grape.shader;
import grape.buffer;
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
  protected:
    this() {
      _fbo = new FBO;
    }

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

  private:
    Scene _scene;
    Camera _camera;
}

class BlurPass : Pass {
  public:
    this(in int width, in int height) {
      _width = width;
      _height = height;
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
      auto widthBlur = {
        auto tmp = new Texture;
        tmp.create(writeTexture.w, writeTexture.h, null, GL_RGBA);

        create_fbo(tmp);

        binded_scope({
          renderer.render(readTexture);
        }, tmp.w, tmp.h);
      };

      auto heightBlur = {
        create_fbo(writeTexture);

        binded_scope({
          renderer.render(readTexture);
        }, writeTexture.w, writeTexture.h);
      };

      widthBlur();
      heightBlur();
    }

  private:
    int _width, _height;
}

/*
class GlowPass : Pass {
  public:
    this(in int w, in int h, in int resX, in int resY) {
    }

    override void render(Renderer renderer, Texture writeTexture, Texture readTexture) {
    }

  private:
}

class ShaderPass : Pass {
  public:
    this(Shader shader) {
    }

    override void render(Renderer renderer) {
    }

  private:
}
*/

