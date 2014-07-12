module grape.renderer;

import derelict.opengl3.gl3;

import std.math;
import std.stdio;

import grape.buffer;
import grape.shader;
import grape.window;

public import grape.image : ImageRenderer;
public import grape.font : FontRenderer;

class Renderer2 {
  import grape.scene;
  import grape.camera;
  import grape.mesh;
  import grape.geometry;
  import grape.material;
  import grape.filter;
  import grape.math;
  import std.conv;
  import std.algorithm;
  import std.array;
  import std.range;

  public:
    this() {
      _ibo = new IBO;
      for (int i; i<MaxNumVBO; ++i) {
        _vbon ~= new VBON;
      }
      
      _renderImplCaller["color"] = (program, geometry, material, camera) { render_impl_color(program, geometry, material, camera); };
      _renderImplCaller["diffuse"] = (program, geometry, material, camera) { render_impl_diffuse(program, geometry, material, camera); };
    }

    void enable_smooth(in string[] names...) {
      foreach (name; names) {
        if (name == "polygon") glEnable(GL_POLYGON_SMOOTH);
        else if (name == "line") glEnable(GL_LINE_SMOOTH);
        else writeln("Warning: " ~ name ~ " is not a smooth parameter's name. Check your enable_smooth()");
      }
    }

    void enable_depth() {
      glEnable(GL_DEPTH_TEST);
    }

    void disable_smooth(in string[] names...) {
      foreach (name; names) {
        if (name == "polygon") glDisable(GL_POLYGON_SMOOTH);
        else if (name == "line") glDisable(GL_LINE_SMOOTH);
        else writeln("Warning: " ~ name ~ " is not a smooth parameter's name. Check your disable_smooth()");
      }
    }

    void disable_depth() {
      glDisable(GL_DEPTH_TEST);
    }



    void set_MaxNumVBO(in int n) {
      MaxNumVBO = n;
      _vbon.length = 0;
      for (int i; i<MaxNumVBO; ++i) {
        _vbon ~= new VBON;
      }
    }

    void render(Scene scene, Camera camera) {
      foreach (i, mesh; scene.meshes) {
        auto geometry = mesh.geometry;
        auto material = mesh.material;
        auto program = material.program;
        program.use();

        _renderImplCaller[material.name](program, geometry, material, camera);
      }
    }

    /**
     * Viewportの設定
     *
     * 内部でOpenGLのglViewport関数を呼んでいるだけです。
     * x: 左下のx座標
     * y: 左下のy座標
     * w: 画面の幅
     * h: 画面の高さ
     */
    void viewport(in int x, in int y, in int w, in int h) {
      glViewport(x, y, w, h);
    }
    
  private:
    void render_impl_color(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      // VBO: Position
      float[] position;
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // VBO: Color
      auto colorPtr = material.params["color"].peek!(int[]);
      auto colorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*colorPtr)).array;
      float[3] tmp = colorRGB[] / ColorMax;
      float[4] colorBase = tmp ~ 1.0;
      float[] color = colorBase.cycle.take(colorBase.length * geometry.vertices.length).array;

      // Attach VBOs to the program
      _vbon[0].set(program, position, "position", 3, 0);
      _vbon[1].set(program, color, "color", 4, 1);

      // IBO Setting
      _ibo.create(geometry.indices);

      // Uniform Setting
      UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv", 1);

      // Wireframe Checking
      auto wireframePtr = material.params["wireframe"].peek!(bool);
      bool wireframe = *wireframePtr;
      if (wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      scope(exit) glPolygonMode( GL_FRONT_AND_BACK, GL_FILL); 

      _ibo.draw(DrawMode.Triangles);
    }

    void render_impl_diffuse(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      // VBO: Position
      float[] position;
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // VBO: Color
      auto colorPtr = material.params["color"].peek!(int[]);
      auto colorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*colorPtr)).array;
      float[3] tmp = colorRGB[] / ColorMax;
      float[4] colorBase = tmp ~ 1.0;
      float[] color = colorBase.cycle.take(colorBase.length * geometry.vertices.length).array;
      
      // VBO: Normal
      float[] normal;
      foreach (vec3; geometry.vertex_normals) {
        normal ~= vec3.coord;
      }

      // Attach VBOs to the program
      _vbon[0].set(program, position, "position", 3, 0);
      _vbon[1].set(program, color, "color", 4, 1);
      _vbon[2].set(program, normal, "normal", 3, 2);

      // IBO Setting
      _ibo.create(geometry.indices);

      // Uniform Setting
      UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv", 1);
      // TODO ModelMatrixのinvMatrixを設定する
      UniformLocationN.attach(program, "invMatrix", camera.pvMat4.inverse.mat, "mat4fv", 1);
      // TODO sceneの中にlight置くようにする
      UniformLocationN.attach(program, "lightPosition", [2.0f, 0.0f, 0.0f], "3fv", 1);

      // Wireframe Checking
      auto wireframePtr = material.params["wireframe"].peek!(bool);
      bool wireframe = *wireframePtr;
      if (wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      scope(exit) glPolygonMode( GL_FRONT_AND_BACK, GL_FILL); 

      _ibo.draw(DrawMode.Triangles);
    }

    static immutable ColorMax = 255;
    int MaxNumVBO = 10;
    VBON[] _vbon;
    IBO _ibo;
    static void delegate(ShaderProgram, Geometry, Material, Camera)[string] _renderImplCaller;
}

/**
 * 描画クラス
 *
 * デフォルトセットのRendererじゃ物足りない、自作のシェーダを使いたい
 * 等といった時にRendererを継承して新たなRendererのSubClass作成してください。
 */
deprecated abstract class Renderer {
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
      _vboHdr = new VBOHdr(strides.length, _program); // TODO Detect the number of attributes from a ShaderSource.
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

deprecated class FilterRenderer : Renderer {
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
deprecated class GaussianRenderer : Renderer {
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

deprecated class NormalRenderer : Renderer {
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
deprecated class BasicRenderer : Renderer {
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
deprecated class TextureRenderer : Renderer {
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

