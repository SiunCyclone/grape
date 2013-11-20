module grape.renderer;

import derelict.opengl3.gl3;

import std.math;
import std.stdio;

import grape.buffer;
import grape.shader;
import grape.window;

public import grape.image : ImageRenderer;
public import grape.font : FontRenderer;

/**
 * 描画クラス
 *
 * デフォルトセットのRendererじゃ物足りない、自作のシェーダを使いたい
 * 等といった時にRendererを継承して新たなRendererのSubClass作成してください。
 */
abstract class Renderer {
  public:
    /**
     * Rendererの初期化
     *
     * Rendererを継承したSubClassは必ずこの関数をコンストラクタで呼ぶ必要があります。
     * dg:       Shaderのソース
     * locNames: Shaderのattributesの名前の配列
     * strides:  Shaderのattributesのストライド
     * drawMode: 描画モード
     *
     * TODO:
     * _iboはここで初期化されるべき
     * 引数を減らしたい
     */
    final void init(in void delegate(out string, out string) dg, in string[] locNames, in int[] strides, in DrawMode drawMode) {
      assert(strides.length == locNames.length);

      init_program(dg);
      _vboHdr = new VBOHdr(strides.length, _program); // TODO Detect the number of attributes from ShaderSource.
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

    /**
     * IBOをセット
     *
     * IBOを使って描画する場合、この関数を呼ぶ必要
     * _ibo must be initialized before calling this function, or cause segv.
     *
     * TODO:
     * final修飾子つけるか
     */
    void set_ibo(in int[] index) {
      _program.use();
      _ibo.create(index);
    }

    /**
     * Uniform変数のセット
     * 
     * name:    uniformの場所の名前
     * value:   セットする値
     * type:     
     * num:     
     */
    final void set_uniform(T)(in string name, in T value, in string type, in int num=1) {
      _program.use();
      _uniLoc.attach(name, value, type, num);
    }

    /**
     * 描画関数
     *
     * SubClassで必ずoverrideする必要があります。
     *
     * TODO:
     * ImageRendererでこれ使ってない
     */
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

      init_vbo();
      init_ibo();
      _program.use();
      set_uniform("tex", 0, "1i");
    }

    override void render() {
      _program.use();
      set_vbo(_mesh, _texCoord);
      _ibo.draw(_drawMode);
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

/**
 * GaussBlur用のRenderer
 * 
 * ユーザーが使うことはまずないと思われる
 *
 * TODO:
 * BlurFilter,GlowFilterの内部に移動させるか
 */
class GaussianRenderer : Renderer {
  public:
    this(in float[2] resolution) {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 2, 2 ];
      mixin GaussianShaderSource;
      init(GaussianShader, locNames, strides, DrawMode.Triangles);

      init_vbo();
      init_ibo();

      _program.use();
      float[8] weight = gauss_weight(50.0);
      set_uniform("tex", 0, "1i");
      set_uniform("weight", weight, "1fv", 8);
      set_uniform("resolution", resolution, "2fv");
    }

    void set_type(in int type) {
      _program.use();
      set_uniform("type", type, "1i");
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
    //init(NormalShader, locNames, strides, DrawMode.Points);
    //init(NormalShader, locNames, strides, DrawMode.LineStrip);
    init(NormalShader, locNames, strides, DrawMode.Triangles); // TODO

    _ibo = new IBO;
  }

  override void render() {
    _program.use();
    _ibo.draw(_drawMode);
  }
}

/**
 * 基本的なRenderer
 *
 * TODO:
 * どんなRendererにするか決まってない
 */
class BasicRenderer : Renderer {
  this() {
    string[] locNames = [ "pos", "color" ];
    int[] strides = [ 3, 4 ];
    mixin NormalShaderSource;
    //init(NormalShader, locNames, strides, DrawMode.Points);
    //init(NormalShader, locNames, strides, DrawMode.LineStrip);
    init(NormalShader, locNames, strides, DrawMode.Triangles); // TODO

    _ibo = new IBO;
  }

  override void render() {
    _program.use();
    _ibo.draw(_drawMode);
  }
}

/**
 * Textureを描画
 *
 * TODO:
 * ImageRendererとの区別
 */
class TextureRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin TextureShaderSource;
      init(TextureShader, locNames, strides, DrawMode.Triangles);

      init_ibo();

      _program.use();
      set_uniform("tex", 0, "1i");
    }

    override void render() {
      _program.use();
      _ibo.draw(_drawMode);
    }

  private:
    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }
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
