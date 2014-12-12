module grape.renderer;

import derelict.opengl3.gl3;

import std.math;
import std.stdio;
import std.traits;
import std.conv;
import std.algorithm;
import std.array;
import std.range;

import grape.buffer;
import grape.shader;
import grape.window;
import grape.scene;
import grape.camera;
import grape.mesh;
import grape.geometry;
import grape.material;
import grape.filter;
import grape.math;

public import grape.image : ImageRenderer;
public import grape.font : FontRenderer;

class Renderer {
  public:
    this() {
      _ibo = new IBO;
      for (int i; i<MaxNumVBO; ++i) {
        _vboList ~= new VBO;
      }

      _renderImplCaller["shader"] = (program, geometry, material, camera) { render_impl_shader(program, geometry, material, camera); };
      _renderImplCaller["color"] = (program, geometry, material, camera) { render_impl_color(program, geometry, material, camera); };
      _renderImplCaller["diffuse"] = (program, geometry, material, camera) { render_impl_diffuse(program, geometry, material, camera); };
      _renderImplCaller["ads"] = (program, geometry, material, camera) { render_impl_ads(program, geometry, material, camera); };
    }

    void enable_smooth(in string[] names...) {
      if (cast(int)names.length == 0) {
        glEnable(GL_POLYGON_SMOOTH);
        glEnable(GL_LINE_SMOOTH);
        return;
      }

      foreach (name; names) {
        if (name == "polygon") glEnable(GL_POLYGON_SMOOTH);
        else if (name == "line") glEnable(GL_LINE_SMOOTH);
        else writeln("Warning: " ~ name ~ " is not a smooth parameter's name. Check the args of the enable_smooth()");
      }
    }

    void enable_depth() {
      glEnable(GL_DEPTH_TEST);
    }

    void disable_smooth(in string[] names...) {
      if (cast(int)names.length == 0) {
        glDisable(GL_POLYGON_SMOOTH);
        glDisable(GL_LINE_SMOOTH);
        return;
      }

      foreach (name; names) {
        if (name == "polygon") glDisable(GL_POLYGON_SMOOTH);
        else if (name == "line") glDisable(GL_LINE_SMOOTH);
        else writeln("Warning: " ~ name ~ " is not a smooth parameter's name. Check your disable_smooth()");
      }
    }

    void disable_depth() {
      glDisable(GL_DEPTH_TEST);
    }

    void set_point_size(in float size) {
      glPointSize(size);
    }

    void set_MaxNumVBO(in int n) {
      MaxNumVBO = n;
      _vboList.length = 0;
      for (int i; i<MaxNumVBO; ++i) {
        _vboList ~= new VBO;
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

    void render(Texture texture, Material material = new TextureMaterial) {
      auto program = material.program;
      program.use();

      float[] position = [ -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0 ];
      float[] texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
      int[] index = [ 0, 1, 2, 0, 2, 3 ];

      _ibo.create(index);
      _vboList[0].set(program, position, "position", 2, 0);
      _vboList[1].set(program, texCoord, "texCoord", 2, 1);

      UniformLocationN.attach(program, "tex", 0, "1i");

      texture.texture_scope({
        auto drawModePtr = material.params["drawMode"].peek!(DrawMode);
        _ibo.draw(*drawModePtr);
      });
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
    void render_impl_shader(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      float[] position;

      // VBO: Position
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // IBO Setting
      _ibo.create(geometry.indices);

      // Attach VBOs to the program
      _vboList[0].set(program, position, "position", 3, 0);
      auto attributes = *material.params["attributes"].peek!(AttributeType[string][string]);
      int i = 1;
      foreach(name, data; attributes) {
        if (name == "position") break;
        _vboList[i].set(program, *data["value"].peek!(float[]), name, *data["type"].peek!(int), i);
        ++i;
      }

      // Uniform Setting
      //UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv");
      auto uniforms = *material.params["uniforms"].peek!(UniformType[string][string]);
      foreach(name, data; uniforms) {
        if (name == "pvmMatrix") break;
        auto value = data["value"];
        switch (value.type.toString) {
          case "int":
            UniformLocationN.attach(program, name, *value.peek!(int), *data["type"].peek!(string));
            break;
          case "float":
            UniformLocationN.attach(program, name, *value.peek!(float), *data["type"].peek!(string));
            break;
          case "float[2]":
            UniformLocationN.attach(program, name, *value.peek!(float[2]), *data["type"].peek!(string));
            break;
          case "float[8]":
            UniformLocationN.attach(program, name, *value.peek!(float[8]), *data["type"].peek!(string), 8);
            break;
          case "float[16]":
            UniformLocationN.attach(program, name, *value.peek!(float[16]), *data["type"].peek!(string));
            break;
          default:
            writeln("ShaderMaterial.uniforms setting is wrong");
            break;
        }
      }

      (*material.params["map"].peek!(Texture)).texture_scope({
        auto drawModePtr = material.params["drawMode"].peek!(DrawMode);
        _ibo.draw(*drawModePtr);
      });
    }

    void render_impl_color(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      float[] position;
      float[] color;

      // VBO: Position
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // VBO: Color
      auto colorPtr = material.params["color"].peek!(int[]);
      auto colorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*colorPtr)).array;
      float[3] tmp = colorRGB[] / ColorMax;
      float[4] colorBase = tmp ~ 1.0;
      color = colorBase.cycle.take(colorBase.length * geometry.vertices.length).array;

      // IBO Setting
      _ibo.create(geometry.indices);

      // Attach VBOs to the program
      _vboList[0].set(program, position, "position", 3, 0);
      _vboList[1].set(program, color, "color", 4, 1);

      // Uniform Setting
      UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv");

      // Wireframe Checking
      auto wireframePtr = material.params["wireframe"].peek!(bool);
      bool wireframe = *wireframePtr;
      if (wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      scope(exit) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

      auto drawModePtr = material.params["drawMode"].peek!(DrawMode);
      _ibo.draw(*drawModePtr);
    }

    void render_impl_diffuse(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      float[] position;
      float[] normal;
      float[] color;

      // VBO: Position
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // VBO: Normal
      foreach (vec3; geometry.normals) {
        normal ~= vec3.coord;
      }

      // VBO: Color
      auto colorPtr = material.params["color"].peek!(int[]);
      auto colorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*colorPtr)).array;
      float[3] tmp = colorRGB[] / ColorMax;
      float[4] colorBase = tmp ~ 1.0;
      color = colorBase.cycle.take(colorBase.length * geometry.vertices.length).array;

      // IBO Setting
      _ibo.create(geometry.indices);

      // Attach VBOs to the program
      _vboList[0].set(program, position, "position", 3, 0);
      _vboList[1].set(program, color, "color", 4, 1);
      _vboList[2].set(program, normal, "normal", 3, 2);

      // Uniform Setting
      UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv");
      UniformLocationN.attach(program, "invMatrix", camera.pvMat4.inverse.mat, "mat4fv");
      // TODO sceneの中にlight置くようにする
      UniformLocationN.attach(program, "lightPosition", [2.0f, 2.0f, -2.0f], "3fv");

      // Wireframe Checking
      auto wireframePtr = material.params["wireframe"].peek!(bool);
      bool wireframe = *wireframePtr;
      if (wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      scope(exit) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

      auto drawModePtr = material.params["drawMode"].peek!(DrawMode);
      _ibo.draw(*drawModePtr);
    }

    void render_impl_ads(ShaderProgram program, Geometry geometry, Material material, Camera camera) {
      float[] position;
      float[] color;
      float[] normal;

      // VBO: Position
      foreach (vec3; geometry.vertices) {
        position ~= vec3.coord;
      }

      // VBO: Color
      auto colorPtr = material.params["color"].peek!(int[]);
      auto colorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*colorPtr)).array;
      float[3] tmp = colorRGB[] / ColorMax;
      float[4] colorBase = tmp ~ 1.0;
      color = colorBase.cycle.take(colorBase.length * geometry.vertices.length).array;

      // VBO: Normal
      foreach (vec3; geometry.normals) {
        normal ~= vec3.coord;
      }

      // IBO Setting
      _ibo.create(geometry.indices);

      // Attach VBOs to the program
      _vboList[0].set(program, position, "position", 3, 0);
      _vboList[1].set(program, color, "color", 4, 1);
      _vboList[2].set(program, normal, "normal", 3, 2);

      // Uniform: ambientColor
      auto ambientColorPtr = material.params["ambientColor"].peek!(int[]);
      auto ambientColorRGB = map!(x => x > ColorMax ? ColorMax : x)(map!(to!float)(*ambientColorPtr)).array;
      float[3] tmp2 = ambientColorRGB[] / ColorMax;
      float[4] ambientColor = tmp2 ~ 1.0;

      // Uniform Setting
      UniformLocationN.attach(program, "pvmMatrix", camera.pvMat4.mat, "mat4fv");
      UniformLocationN.attach(program, "invMatrix", camera.pvMat4.inverse.mat, "mat4fv");
      // TODO sceneの中にlight置くようにする
      UniformLocationN.attach(program, "lightPosition", [2.0f, 2.0f, -2.0f], "3fv");
      // TODO camera実装してcameraの位置入れる
      UniformLocationN.attach(program, "eyePosition", [0.0f, 1.0f, 3.0f], "3fv");
      UniformLocationN.attach(program, "ambientColor", ambientColor, "4fv");

      // Wireframe Checking
      auto wireframePtr = material.params["wireframe"].peek!(bool);
      bool wireframe = *wireframePtr;
      if (wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
      scope(exit) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

      auto drawModePtr = material.params["drawMode"].peek!(DrawMode);
      _ibo.draw(*drawModePtr);
    }

    static immutable ColorMax = 255;
    int MaxNumVBO = 10;
    VBO[] _vboList;
    IBO _ibo;
    static void delegate(ShaderProgram, Geometry, Material, Camera)[string] _renderImplCaller;
}

/**
 * 描画クラス
 *
 * デフォルトセットのRendererじゃ物足りない、自作のシェーダを使いたい
 * 等といった時にRendererを継承して新たなRendererのSubClass作成してください。
 */
deprecated abstract class Old_Renderer {
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

deprecated class FilterRenderer : Old_Renderer {
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
deprecated class GaussianRenderer : Old_Renderer {
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

