module orange.filter;

import orange.buffer;
import orange.renderer;
import orange.window;
import derelict.opengl3.gl3;

abstract class Filter {
  public:
    this(in int num, in int w, in int h) {
      _w = w;
      _h = h;
      _fbo = new FBO;
      _renderer = new FilterRenderer;

      _textures.length = num;
      for (int i; i<num; ++i) {
        _textures[i] = new Texture;
        _textures[i].create(_w, _h, null, GL_RGBA);
      }
    }

    /*
    final void set_camera(in float[] mat) {
      _renderer.set_uniform("pvmMatrix", mat, "mat4fv");
    }

    // Enables user to respecify a filtered area. Note that the area is the whole screen by default.
    final void set_area(in float x, in float y, in float w, in float h) {
    }
    */

    abstract void filter(in void delegate());

    final void render() {
      texture_scope(_textures.length-1, {
        _renderer.render(); // TODO Specify a drawing area
      });
    }

    final void filter_scope(in void delegate() dg) {
      texture_scope(_textures.length-1, dg);
    }

    /*
    @property {
      Texture texture() {
        return _textures[$-1];
      }
    }
    */

  protected:
    final void create_texture(in int i, in void delegate() dg) {
      attach(i);
      fbo_scope(dg);
    }

    final void texture_scope(in int i, in void delegate() dg) {
      _textures[i].texture_scope(dg);
    }

    Texture[] _textures; // privateでいいかも

  private:
    void attach(in int i) {
      _fbo.create(_textures[i]);

      // TODO RBO
      _fbo.binded_scope({
        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);
      });
    }

    void fbo_scope(in void delegate() dg) {
      _fbo.binded_scope({
        //glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glClear(GL_DEPTH_BUFFER_BIT);
        glViewport(0, 0, _w, _h);
        dg();
        glViewport(0, 0, WINDOW_X, WINDOW_Y);
      });
    }

    FBO _fbo;
    int _w, _h;
    FilterRenderer _renderer;
}

class BlurFilter : Filter {
  public:
    this(in int w, in int h) {
      super(3, w, h);
      _heightRenderer = new GaussHeightRenderer;
      _weightRenderer = new GaussWeightRenderer;
    }

    override void filter(in void delegate() render) {
      create_texture(0, render);
      create_texture(1, { texture_scope(0, { _heightRenderer.render(); }); });
      create_texture(2, { texture_scope(1, { _weightRenderer.render(); }); });
    }

  private:
    GaussHeightRenderer _heightRenderer;
    GaussWeightRenderer _weightRenderer;
}

class GlowFilter : Filter {
  public:
    this(in int w, in int h) {
      super(2, w, h);
      _blurFilter = new BlurFilter(w, h);
    }

    override void filter(in void delegate() render) {
      create_texture(0, render);
      _blurFilter.filter(render);

      create_texture(1, { 
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE); // Add

        render();
        _blurFilter.render();

        glDisable(GL_BLEND);
      });
    }

  private:
    BlurFilter _blurFilter;
}

/*
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

    @property {
      Texture texture() {
        return _texture;
      }
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

    //void set_camera(float[] mat) {
      //_filter.set_camera(mat);
      //_heightFilter.set_camera(mat);
    //}

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

    Texture create_texture(in void delegate() render) {
      return _gFilter.texture;
    }

  private:
    Filter _highFilter;
    Filter _gFilter;
}
*/

