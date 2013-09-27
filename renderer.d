module orange.renderer;

import orange.buffer;
import orange.shader;

import std.stdio;

class PostProcessing {
  public:

  private:
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
