module orange.renderer;

import orange.buffer;
import orange.shader;
import orange.window;

import std.stdio;
import std.math;
//import opengl.glew;
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

    final void apply(void delegate() render) {
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

class Renderer {
  public:
    // TODO dgだけにする dgの名前
    final void init(in void delegate(out string, out string) dg, in int num, in string[] locNames, in int[] strides, in DrawMode drawMode) {
      init_program(dg);
      _vboHdr = new VBOHdr(num, _program); // TODO シェーダのソースからattributeの数指定
      _uniLoc = new UniformLocation(_program);
      _locNames = locNames.dup;
      _strides = strides.dup;
      _drawMode = drawMode;
    }

    final void set_vbo(in float[][] list...) {
      _program.use();
      _vboHdr.create_vbo(list);
      _vboHdr.enable_vbo(_locNames, _strides);
    }

    final void set_uniform(T)(in string name, in T value, in string type, in int num=1) {
      _program.use();
      _uniLoc.attach(name, value, type, num);
    }

    abstract void render();

  protected:
    ShaderProgram _program;
    DrawMode _drawMode;

  private:
    final void init_program(in void delegate(out string, out string) dg) {
      dg(_vShader, _fShader);
      Shader vs = new Shader(ShaderType.Vertex, _vShader);
      Shader fs = new Shader(ShaderType.Fragment, _fShader);
      _program = new ShaderProgram(vs, fs);
    }

    string _vShader;
    string _fShader;
    UniformLocation _uniLoc;
    VBOHdr _vboHdr;

    // TODO 消す
    string[] _locNames;
    int[] _strides;
}

class FilterRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin FilterShaderSource;;
      init(FilterShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
      set_uniform("tex", 0, "1i");
    }

    override void render() {
      _program.use();
      set_vbo(_mesh, _texCoord);
      _ibo.draw(_drawMode);
    }

    void above() {
      _mesh = [ -1.0, 1.0, 0.0001, 1.0, 1.0, 0.0001, 1.0, -1.0, 0.0001, -1.0, -1.0, 0.0001 ];
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;
}

class GaussHeightRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
      mixin GaussianYShaderSource;
      init(GaussianYShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();

      float[8] weight = gauss_weight(50.0);
      set_uniform("tex", 0, "1i");
      set_uniform("weight", weight, "1fv", 8);
    }

    override void render() {
      _program.use();
      set_vbo(_mesh, _texCoord);
      _ibo.draw(_drawMode);
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    // TODO 名前
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

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;
}

class GaussWeightRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
      mixin GaussianXShaderSource;
      init(GaussianXShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();

      float[8] weight = gauss_weight(50.0);
      set_uniform("tex", 0, "1i");
      set_uniform("weight", weight, "1fv", 8);
    }

    override void render() {
      _program.use();
      set_vbo(_mesh, _texCoord);
      _ibo.draw(_drawMode);
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    // TODO 名前
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

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;
}

class NormalRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "color" ];
      int[] strides = [ 3, 4 ];
      mixin NormalShaderSource;
      init(NormalShader, 2, locNames, strides, DrawMode.Points);

      _ibo = new IBO;
    }

    void set_ibo(in int[] index) {
      _program.use();
      _ibo.create(index);
    }

    override void render() {
      _program.use();
      _ibo.draw(_drawMode);
    }

  private:
    IBO _ibo;
}

class TextureRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin NormalShaderSource;
      init(NormalShader, 2, locNames, strides, DrawMode.Points);

      _ibo = new IBO;
    }

    void set_ibo(in int[] index) {
      _program.use();
      _ibo.create(index);
    }

  private:
    IBO _ibo;
}

/*
class Renderer {
  public:
    this(ShaderProgramType type, int num) {
      _prgType = type;
      _programHdr = new ShaderProgramHdr(_prgType);
      _programHdr.use(_prgType);

      _uniLoc = new UniformLocation(_programHdr.current, _prgType);
      _vboHdr = new VBOHdr(num, _programHdr.current);
      _ibo = new IBO;
    }

    void init(string[] locNames, int[] strides, DrawMode drawMode) {
      _locNames = locNames;
      _strides = strides;
      _drawMode = drawMode;
    }

    void set_ibo(int[] index) {
      _programHdr.use(_prgType);
      _ibo.create(index);
    }

    void set_vbo(float[][] list...) {
      _programHdr.use(_prgType);
      _vboHdr.create_vbo(list);
      _vboHdr.enable_vbo(_locNames, _strides);
    }

    void set_uniform(T)(string name, T value, string type, int num=1) {
      _programHdr.use(_prgType);
      _uniLoc.attach(name, value, type, num);
    }

    void render() {
      _programHdr.use(_prgType);
      _ibo.draw(_drawMode);
    }

  private:
    ShaderProgramType _prgType;
    ShaderProgramHdr _programHdr;
    UniformLocation _uniLoc;
    VBOHdr _vboHdr;
    IBO _ibo;

    string[] _locNames;
    int[] _strides;
    DrawMode _drawMode;
}
*/
