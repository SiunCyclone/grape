module orange.renderer;

import orange.buffer;
import orange.shader;
import orange.window;

import std.stdio;
import std.math;
//import opengl.glew;
import derelict.opengl3.gl3;

abstract class Renderer {
  public:
    // TODO
    // Consider args
    // _ibo should be initialized here.
    final void init(in void delegate(out string, out string) dg, in string[] locNames, in int[] strides, in DrawMode drawMode) {
      assert(strides.length == locNames.length);

      init_program(dg);
      _vboHdr = new VBOHdr(cast(int)strides.length, _program); // TODO Detect the number of attributes from ShaderSource.
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

    // _ibo must be initialized before calling this function, or cause segv.
    void set_ibo(in int[] index) {
      _program.use();
      _ibo.create(index);
    }

    final void set_uniform(T)(in string name, in T value, in string type, in int num=1) {
      _program.use();
      _uniLoc.attach(name, value, type, num);
    }

    abstract void render();

  protected:
    ShaderProgram _program;
    DrawMode _drawMode;
    IBO _ibo; // Must be initialized in SubClass when rendering model using IBO.

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

    // TODO delete
    string[] _locNames;
    int[] _strides;
}

class FilterRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin FilterShaderSource;
      init(FilterShader, locNames, strides, DrawMode.Triangles);

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

    // TODO delete
    void above() {
      _mesh = [ -1.0, 1.0, 0.00001, 1.0, 1.0, 0.00001, 1.0, -1.0, 0.00001, -1.0, -1.0, 0.00001 ];
    }

    // TODO delete
    void above2() {
      _mesh = [ -1.0, 1.0, 0.00002, 1.0, 1.0, 0.00002, 1.0, -1.0, 0.00002, -1.0, -1.0, 0.00002 ];
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

    float[] _mesh;
    float[] _texCoord;
}

class GaussHeightRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
      mixin GaussianYShaderSource;
      init(GaussianYShader, locNames, strides, DrawMode.Triangles);

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

    float[] _mesh;
    float[] _texCoord;
}

class GaussWeightRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
      mixin GaussianXShaderSource;
      init(GaussianXShader, locNames, strides, DrawMode.Triangles);

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

    float[] _mesh;
    float[] _texCoord;
}

class NormalRenderer : Renderer {
  this() {
    string[] locNames = [ "pos", "color" ];
    int[] strides = [ 3, 4 ];
    mixin NormalShaderSource;
    init(NormalShader, locNames, strides, DrawMode.Points);

    _ibo = new IBO;
  }

  override void render() {
    _program.use();
    _ibo.draw(_drawMode);
  }
}

class TextureRenderer : Renderer {
  this() {
    string[] locNames = [ "pos", "texCoord" ];
    int[] strides = [ 3, 2 ];
    mixin NormalShaderSource;
    init(NormalShader, locNames, strides, DrawMode.Points);
  }

  override void render() {}
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
