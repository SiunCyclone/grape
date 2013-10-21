module orange.filter;

import orange.buffer;
import orange.renderer;
import orange.window;
import derelict.opengl3.gl3;

class Filter {
  public:
    this(in int w, in int h) {
      _w = w;
      _h = h;
      init();
    }

    final void set_camera(in float[] mat) {
      _renderer.set_uniform("pvmMatrix", mat, "mat4fv");
    }

    final void apply(in void delegate() render) {
      _fbo.bind();
      glClear(GL_COLOR_BUFFER_BIT);
      glClear(GL_DEPTH_BUFFER_BIT);
      glViewport(0, 0, _w, _h);

      render();
      
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
      _fbo.unbind();
    }

    final void texture_enable() {
      _texture.enable();
    }

    final void texture_disable() {
      _texture.disable();
    }

    final void render() {
      texture_enable();
      _renderer.render(); // TODO 描画位置指定
      texture_disable();
    }

    void above() {
      _renderer.above();
    }

  protected:
    final void init() {
      _fbo = new FBO;
      _texture = new Texture; //TODO もらう
      _renderer = new FilterRenderer;

      _texture.create(_w, _h, null, GL_RGBA);
      _fbo.create(_texture);

      // TODO RBO
      _fbo.bind();
      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);
      _fbo.unbind();
    }

    FBO _fbo;
    Texture _texture;
    FilterRenderer _renderer;
    int _w, _h;
}

class BlurFilter {
  public:
    this() {
      _heightRenderer = new GaussHeightRenderer;
      _weightRenderer = new GaussWeightRenderer;

      _filter = new Filter(128, 128);
      _heightFilter= new Filter(128, 128);
      _weightFilter= new Filter(128, 128);
    }

    void set_camera(float[] mat) {
      /*
      _filter.set_camera(mat);
      _heightFilter.set_camera(mat);
      */
    }

    void apply(in void delegate() render) {
      _filter.apply(render);
      _heightFilter.apply({ 
        _filter.texture_enable();
        _heightRenderer.render();
        _filter.texture_disable();
      });
      _weightFilter.apply({ 
        _heightFilter.texture_enable();
        _weightRenderer.render();
        _heightFilter.texture_disable();
      });
      _weightFilter.render();
    }

  private:
    GaussHeightRenderer _heightRenderer;
    GaussWeightRenderer _weightRenderer;

    Filter _filter;
    Filter _heightFilter;
    Filter _weightFilter;
}

class GlowFilter : BlurFilter {
  public:
    this() {
      super();
      _highFilter = new Filter(1024, 1024);
      _highFilter.above();
    }

    override void apply(in void delegate() render) {
      _highFilter.apply(render);
      _filter.apply(render);
      _heightFilter.apply({ 
        _filter.texture_enable();
        _heightRenderer.render();
        _filter.texture_disable();
      });
      _weightFilter.apply({ 
        _heightFilter.texture_enable();
        _weightRenderer.render();
        _heightFilter.texture_disable();
      });

      glEnable(GL_BLEND);
      glBlendFunc(GL_ONE, GL_ONE); //add
      _highFilter.render();
      _weightFilter.render();
      glDisable(GL_BLEND);
    }

  private:
    Filter _highFilter;
}

