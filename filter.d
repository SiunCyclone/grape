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

    final void apply(in void delegate() dg) {
      _fbo.binded_scope({
        glClear(GL_COLOR_BUFFER_BIT);
        glClear(GL_DEPTH_BUFFER_BIT);
        glViewport(0, 0, _w, _h);
        dg();
        glViewport(0, 0, WINDOW_X, WINDOW_Y);
      });
    }

    final void render() {
      texture_scope({
        _renderer.render(); // TODO Specify a drawing area
      });
    }

    final void texture_scope(in void delegate() dg) {
      _texture.applied_scope({
        dg();
      });
    }

    void above() {
      _renderer.above();
    }

  protected:
    final void init() {
      _fbo = new FBO;
      _texture = new Texture; //TODO Get 
      _renderer = new FilterRenderer;

      _texture.create(_w, _h, null, GL_RGBA);
      _fbo.create(_texture);

      // TODO RBO
      _fbo.binded_scope({
        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);
      });
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
        _filter.texture_scope({
          _heightRenderer.render();
        });
      });
      _weightFilter.apply({ 
        _heightFilter.texture_scope({
          _weightRenderer.render();
        });
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
        _filter.texture_scope({
          _heightRenderer.render();
        });
      });
      _weightFilter.apply({ 
        _heightFilter.texture_scope({
          _weightRenderer.render();
        });
      });

      glEnable(GL_BLEND);
      glBlendFunc(GL_ONE, GL_ONE); // Add
      _highFilter.render();
      _weightFilter.render();
      glDisable(GL_BLEND);
    }

  private:
    Filter _highFilter;
}

