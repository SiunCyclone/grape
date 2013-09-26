module orange.renderer;

import orange.buffer;
import orange.shader;

import std.stdio;

class Renderer {
  public:
    this(ShaderProgramType type) {
      _prgType = type;
      _programHdr = new ShaderProgramHdr(_prgType);
      _programHdr.use(_prgType);

      _uniLoc = new UniformLocation(_programHdr.current, _prgType);

      _vboHdr = new VboHdr(2, _programHdr.current);
      _ibo = new IBO;
      _locNames = [ "pos", "color" ];
      _strides = [ 3, 4 ]; 
      _drawMode = DrawMode.Triangles;
    }

    void set_ibo(int[] index) {
      _programHdr.use(_prgType);
      _ibo.create(index);
    }

    void set_vbo(float[][] list...) {
      _programHdr.use(_prgType);
      _vboHdr.create_vbo(list);
    }

    void attach_uniform(T)(string name, T value, string type, int num=1) {
      _programHdr.use(_prgType);
      _uniLoc.attach(name, value, type, num);
    }

    void render() {
      _programHdr.use(_prgType);

      _vboHdr.enable_vbo(_locNames, _strides);
      _ibo.draw(_drawMode);
    }

  private:
    ShaderProgramType _prgType;
    ShaderProgramHdr _programHdr;
    UniformLocation _uniLoc;
    VboHdr _vboHdr;
    IBO _ibo;
    string[] _locNames;
    int[] _strides;
    DrawMode _drawMode;
}

