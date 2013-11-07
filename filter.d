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

    // Enables user to respecify a filtered area. Note that the area is the whole screen by default.
    final void set_area(in float x, in float y, in float w, in float h) {

    }

    final void applied_scope(in void delegate() dg) {
      _fbo.binded_scope({
        glClear(GL_COLOR_BUFFER_BIT);
        glClear(GL_DEPTH_BUFFER_BIT);
        //glClearColor(0, 0, 0, 0.5);
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

    // TODO delete
    void above() {
      _renderer.above();
    }

    // TODO delete
    void above2() {
      _renderer.above2();
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

    /*
    void set_camera(float[] mat) {
      _filter.set_camera(mat);
      _heightFilter.set_camera(mat);
    }
    */

    void applied_scope(in void delegate() render) {
      _filter.applied_scope(render);

      _heightFilter.applied_scope({ 
        _filter.texture_scope({
          _heightRenderer.render();
        });
      });

      _weightFilter.applied_scope({ 
        _heightFilter.texture_scope({
          _weightRenderer.render();
        });
      });

      //_weightFilter.above2(); // TODO delete
      //glDepthFunc(GL_LEQUAL);
      _weightFilter.render();
      //glDepthFunc(GL_LESS);
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
      _gFilter = new Filter(1024, 1024);
    }

    override void applied_scope(in void delegate() render) {
      _highFilter.applied_scope(render);
      _filter.applied_scope(render);

      _heightFilter.applied_scope({ 
        _filter.texture_scope({
          _heightRenderer.render();
        });
      });

      _weightFilter.applied_scope({ 
        _heightFilter.texture_scope({
          _weightRenderer.render();
        });
      });

      _gFilter.applied_scope({
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE); // Add

        _highFilter.render();
        _weightFilter.render(); // fboでdepath bufferが有効になってないからaboveする必要がない

        glDisable(GL_BLEND);
      });

      _gFilter.render();
    }

  private:
    Filter _highFilter;
    Filter _gFilter;
}

