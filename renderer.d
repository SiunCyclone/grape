module orange.renderer;

import orange.buffer;
import orange.shader;
import orange.window;

import std.stdio;
import std.math;
import opengl.glew;

class Filter {
  public:
    this() {
      init();
    }

    final void apply(void delegate() render) {
      _fbo.bind();
      glClear(GL_COLOR_BUFFER_BIT);
      glClear(GL_DEPTH_BUFFER_BIT);
      glViewport(0, 0, 256, 256);

      render();
      
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
      _fbo.unbind();
    }

  protected:
    final void init() {
      _fbo = new FBO;
      _texture = new Texture;

      _texture.create(256, 256, null, GL_RGBA);
      _fbo.create(_texture);

      // TODO RBO
      _fbo.bind();
      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);
      _fbo.unbind();
    }

    FBO _fbo;
    Texture _texture;
}

class BlurFilter : Filter {
  public:
    this() {
      _renderer = new FilterRenderer;
    }

    void render() {
      _texture.enable();
      _renderer.render();
      _texture.disable();
    }

    // TODO 名前
    float[8] gauss_weight(float eRange) {
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

  private:
    FilterRenderer _renderer;
}

class Renderer {
  public:
    // TODO dgだけにする dgの名前
    final void init(void delegate(out string, out string) dg, int num, string[] locNames, int[] strides, DrawMode drawMode) {
      init_program(dg);
      _vboHdr = new VBOHdr(num, _program); // TODO シェーダのソースからattributeの数指定
      _uniLoc = new UniformLocation(_program);
      _locNames = locNames;
      _strides = strides;
      _drawMode = drawMode;
    }

    final void set_vbo(float[][] list...) {
      _program.use();
      _vboHdr.create_vbo(list);
      _vboHdr.enable_vbo(_locNames, _strides);
    }

    final void set_uniform(T)(string name, T value, string type, int num=1) {
      _program.use();
      _uniLoc.attach(name, value, type, num);
    }

    abstract void render();

  protected:
    ShaderProgram _program;

  private:
    final void init_program(void delegate(out string, out string) dg) {
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
    DrawMode _drawMode;
    string[] _locNames;
    int[] _strides;
}

class FilterRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
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

    void set_ibo(int[] index) {
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

    void set_ibo(int[] index) {
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
