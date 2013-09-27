module orange.buffer;

import opengl.glew;
import orange.shader;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import derelict.sdl2.ttf;
import std.stdio;
import orange.window;
import orange.file;
import orange.math;
import orange.camera;
import orange.surface;

import std.math;

enum DrawMode {
  Points = GL_POINTS,
  Lines = GL_LINES,
  LineLoop = GL_LINE_LOOP,
  LineStrip = GL_LINE_STRIP,
  Triangles = GL_TRIANGLES,
  TriangleStrip = GL_TRIANGLE_STRIP,
  TriangleFan = GL_TRIANGLE_FAN,
  Quads = GL_QUADS
}

alias void delegate() dg;

class Binder {
  public:
    this(void delegate(ref dg, ref dg, ref dg, ref dg) init) {
      init(_generate, _eliminate, _bind, _unbind);
      _generate();
    }

    ~this() {
      _eliminate();
    }

    void bind() {
      _bind();
    }

    void unbind() {
      _unbind();
    }

  protected:
    GLuint _id;
    dg _generate;
    dg _eliminate;
    dg _bind;
    dg _unbind;
}

// TODO name
class VBOHdr {
  public:
    this(in int num, in GLuint program) {
      _num = num;
      _vboList.length = _num;
      for (int i; i<_num; ++i)
        _vboList[i] = new VBO(program);
    }

    void create_vbo(float[][] list...) {
      assert(list.length == _num);

      foreach(int i, data; list)
        _vboList[i].create(data);
    }

    void enable_vbo(string[] locNames, int[] strides) {
      assert(locNames.length == _num);
      assert(strides.length == _num);
      foreach (int i, vbo; _vboList)
        vbo.attach(locNames[i], strides[i], i);
    }

    void draw(DrawMode mode, int num) {
      glDrawArrays(mode, 0, num);
    }

  private:
    int _num;
    VBO[] _vboList;
}

class Location {
  public:
    this(GLuint program, void delegate(string) get) {
      _get = get;
      _program = program;
    }

  private:
    GLuint _program;
    GLint _location;
    void delegate(string) _get;
}

class AttributeLocation : Location {
  public:
    this(GLuint program) {
      auto get = (string name) { _location = glGetAttribLocation(_program, cast(char*)name); };
      super(program, get);
    }

    void attach(string name, int stride, int i) {
      bind(name, i);
      _get(name);
      locate(stride);
    }

  private:
    void bind(string name, int i) {
      glBindAttribLocation(_program, i, cast(char*)name);
    }

    void locate(int stride) {
      glEnableVertexAttribArray(_location);
      glVertexAttribPointer(_location, stride, GL_FLOAT, GL_FALSE, 0, null);
    }
}

class Uniform {
  public:
    this(){
      init();
    }

    this(string vShader, string fShader) {
      init();
      //extract(vShader, fShader);
    }

    void locate(string name, int value, string type, int num, GLint location) {
      _uniInt[type](location, value);
    }

    void locate(string name, float[] value, string type, int num, GLint location) {
      _uniFloatV[type](location, value, num);
    }

  private:
    void init() {
      _uniInt["1i"] = (GLint location, int value) { glUniform1i(location, value); };
      _uniFloatV["1fv"] = (GLint location, float[] value, int num) { glUniform1fv(location, num, value.ptr); };
      _uniFloatV["2fv"] = (GLint location, float[] value, int num) { glUniform2fv(location, num, value.ptr); };
      _uniFloatV["3fv"] = (GLint location, float[] value, int num) { glUniform3fv(location, num, value.ptr); };
      _uniFloatV["4fv"] = (GLint location, float[] value, int num) { glUniform4fv(location, num, value.ptr); };
      _uniFloatV["mat4fv"] = (GLint location, float[] value, int num) {
        glUniformMatrix4fv(location, num, GL_FALSE, value.ptr);
      };
    }

    // TODO ソースから判別
    void extract(string vShader, string fShader) {
    }

    void delegate(GLint, int)[string] _uniInt;
    //void delegate(int[])[string] _uniIntV;
    //void delegate(float)[string] _uniFloat;
    void delegate(GLint, float[], int)[string] _uniFloatV;
}

class UniformLocation : Location {
  public:
    this(GLuint program) {
      auto get = (string name) { _location = glGetUniformLocation(_program, cast(char*)name); };
      super(program, get);
      _uniform = new Uniform();
    }

    this(GLuint program, ShaderProgramType type) {
      auto get = (string name) { _location = glGetUniformLocation(_program, cast(char*)name); };
      super(program, get);
      init(type);
    }

    void attach(T)(string name, T value, string type, int num=1) {
      _get(name);
      _uniform.locate(name, value, type, num, _location);
    }

  private:
    void init(ShaderProgramType type) {
      string vShader, fShader;
      ShaderSource.load(type)(vShader, fShader);
      _uniform = new Uniform(vShader, fShader);
    }

    Uniform _uniform;
}

class VBO : Binder {
  public:
    this(GLuint program) {
      _attLoc = new AttributeLocation(program);
      auto init = (ref dg generate, ref dg eliminate, ref dg bind, ref dg unbind) {
        generate = { glGenBuffers(1, &_id); };
        eliminate = { glDeleteBuffers(1, &_id); };
        bind = { glBindBuffer(GL_ARRAY_BUFFER, _id); };
        unbind = { glBindBuffer(GL_ARRAY_BUFFER, 0); };
      };
      super(init);
    }

    void create(T)(T data) {
      bind();
      glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STREAM_DRAW);
      unbind();
    }

    void attach(string name, int stride, int num) {
      bind();
      _attLoc.attach(name, stride, num);
      unbind();
    }

  private:
    AttributeLocation _attLoc;
}

class IBO : Binder {
  public:
    this() {
      auto init = (ref dg generate, ref dg eliminate, ref dg bind, ref dg unbind) {
        generate = { glGenBuffers(1, &_id); };
        eliminate = { glDeleteBuffers(1, &_id); };
        bind = { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _id); };
        unbind = { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); };
      };
      super(init);
    }

    void create(int[] index) {
      _index = index;
      bind();
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index[0].sizeof*_index.length, _index.ptr, GL_STREAM_DRAW);
      unbind();
    }

    void draw(DrawMode mode) { 
      glDrawElements(mode, _index.length, GL_UNSIGNED_INT, _index.ptr);
    }

  private: 
    int[] _index;
}

class RBO : Binder {
  this() {
    auto init = (ref dg generate, ref dg eliminate, ref dg bind, ref dg unbind) {
      generate = { glGenRenderbuffers(1, &_id); };
      eliminate = { glDeleteRenderbuffers(1, &_id); };
      bind = { glBindRenderbuffer(GL_RENDERBUFFER, _id); };
      unbind = { glBindRenderbuffer(GL_RENDERBUFFER, 0); };
    };
    super(init);
  }

  void create(T)(T type, int w, int h) {
    bind();
    glRenderbufferStorage(GL_RENDERBUFFER, type, w, h);
    unbind();
  }

  void attach(T)(T type) {
    bind();
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, type, GL_RENDERBUFFER, _id);
    unbind();
  }
}

class FBO : Binder {
  this() {
    auto init = (ref dg generate, ref dg eliminate, ref dg bind, ref dg unbind) {
      generate = { glGenFramebuffers(1, &_id); };
      eliminate = { glDeleteFramebuffers(1, &_id); };
      bind = { glBindFramebuffer(GL_FRAMEBUFFER, _id); };
      unbind = { glBindFramebuffer(GL_FRAMEBUFFER, 0); };
    };
    super(init);
  }

  void create(T)(T texture) {
    bind();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    unbind();
  }
  
  // glCheckFramebufferStatus TODO fboがちゃんとコンパイルされているかチェック
}

class Texture : Binder {
  public:
    this() {
      auto init = (ref dg generate, ref dg eliminate, ref dg bind, ref dg unbind) {
        generate = { glGenTextures(1, &_id); };
        eliminate = { glDeleteTextures(1, &_id); };
        bind = { glBindTexture(GL_TEXTURE_2D, _id); };
        unbind = { glBindTexture(GL_TEXTURE_2D, 0); };
      };
      super(init);
    }

    // TODO 分ける
    void create(int w, int h, void* pixels, int bytesPerPixel) {
      set_draw_mode(bytesPerPixel);

      glActiveTexture(GL_TEXTURE0); // TODO 0以外も対応
      unbind(); // TODO diableがちゃんと呼ばれていれば必要ない。が、つけておくべきか
      bind();
      attach(w, h, pixels);
      filter();
      unbind();
    }

    void enable() {
      glActiveTexture(GL_TEXTURE0);
      bind();
    }

    void disable() {
      glActiveTexture(GL_TEXTURE0);
      unbind();
    }

    alias _id this; // TODO private

  private:
    void set_draw_mode(int bytesPerPixel) {
      _mode = (bytesPerPixel == 4) ? GL_RGBA : GL_RGB;
    }

    void attach(int w, int h, void* pixels) {
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, w, h, 0, _mode, GL_UNSIGNED_BYTE, pixels);
    }

    void filter() {
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    int _mode;
}

// TODO 必要あるのか
class TexHdr {
  public:
    this(GLuint program) {
      _program = program; 
      _texture = new Texture;
    }

    void create(Surface surf, string locName) {
      _texture.create(surf.w, surf.h, surf.pixels, surf.bytes_per_pixel);
      set_location(locName);
    }

    void enable() {
      _texture.enable();
    }

    void disable() {
      _texture.disable();
    }

  private:
    void set_location(string locName){
      auto loc = glGetUniformLocation(_program, cast(char*)locName);
      glUniform1i(loc, 0); // TODO
    }

    GLuint _program;
    Texture _texture;
}

class FBOHdr {
  public:
    this() {
      _rbo = new RBO;
      _fbo = new FBO;
      _camera = new Camera;
    }

    void init(Texture texture) {
      _fbo.create(texture);

      _fbo.bind();
      _rbo.create(GL_DEPTH_COMPONENT, 1024, 1024);
      _rbo.attach(GL_DEPTH_ATTACHMENT);

      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);

      _fbo.unbind();
    }

    void set(GLuint program, ShaderProgramType type) {
      _program = program;

      FileHdr _fileHdr = new FileHdr;

      string fileName = "./resource/ball.obj";
      _mesh = _fileHdr.make_mesh(fileName);
      _index = _fileHdr.make_index(fileName);
      _normal = _fileHdr.make_normal(fileName);

      _locNames = ["pos", "color", "normal"];
      _strides = [ 3, 4, 3 ]; 

      for (int i; i<_mesh.length/3; ++i)
        _color ~= [ 0.3, 0.4, 0.9, 1.0 ];
        //_color ~= [ 0.2, 0.5, 1.0, 1.0 ];
        //_color ~= [ 0.6, 0.8, 1.0, 1.0 ];

      _vboHdr = new VBOHdr(3, _program);
      _ibo = new IBO;
      _ibo.create(_index);

      float[] lightPos = [0, 0, 1];
      float[] eyePos = [0, 0, 1]; // _camera.eye
      float[] ambientColor = [0.1, 0.1, 0.1, 1.0];
      Mat4 invMat4 = Mat4( 1, 0, 0, 0,
                           0, 1, 0, 0,
                           0, 0, 1, 0,
                           0, 0, 0, 1 ).inverse;

      _uniLoc = new UniformLocation(_program, type);
      _uniLoc.attach("lightPos", lightPos, "3fv");
      _uniLoc.attach("eyePos", eyePos, "3fv");
      _uniLoc.attach("ambientColor", ambientColor, "4fv");
      _uniLoc.attach("invMatrix", invMat4.mat, "mat4fv");
    }

    /*
    void set(GLuint program) {
      _program = program;

      FileHdr _fileHdr = new FileHdr;
      string fileName = "./resource/ball.obj";
      _mesh = _fileHdr.make_mesh(fileName);
      _index = _fileHdr.make_index(fileName);
      _locNames = ["pos", "color"];
      _strides = [ 3, 4 ]; 

      for (int i; i<_mesh.length/3; ++i)
        _color ~= [ 0.6, 0.8, 1.0, 1.0 ];

      _vboHdr = new VBOHdr(2, _program);
      _ibo = new IBO;
      _ibo.create(_index);
    }
    */

    void draw() {
      _fbo.bind();
      glViewport(0, 0, 1024, 1024);

      _camera.perspective(45.0, cast(float)512/512, 0.1, 100.0);

      Vec3 eye = Vec3(0, 0, 3.0);
      Vec3 center = Vec3(0, 0, 0);
      Vec3 up = Vec3(0, 1, 0);
      _camera.look_at(eye, center, up);
      _uniLoc.attach("pvmMatrix", _camera.pvMat4.mat, "mat4fv");

      //_vboHdr.create_vbo(_mesh, _color);
      _vboHdr.create_vbo(_mesh, _color, _normal);
      _vboHdr.enable_vbo(_locNames, _strides);
      _ibo.draw(DrawMode.Triangles); 

      _fbo.unbind();
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
    }

  private:
    RBO _rbo;
    FBO _fbo;

    UniformLocation _uniLoc;

    float[] _normal;

    Camera _camera;
    GLuint _program;
    float[] _mesh;
    float[] _color;
    int[] _index;
    string[] _locNames;
    int[] _strides;
    VBOHdr _vboHdr;
    IBO _ibo;
}

class GaussHdr {
  public:
    this() {
      _rbo = new RBO;
      _fbo = new FBO;
    }

    void init(Texture texture) {
      _fbo.create(texture);

      _fbo.bind();
      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);
      _fbo.unbind();
    }

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

    void set(GLuint program, ShaderProgramType type, int num) {
      _program = program;

      _mesh = [ -1.0, 1.0,
                1.0, 1.0,
                1.0, -1.0,
                -1.0, -1.0 ];
      _index = [ 0, 1, 2,
                 0, 2, 3 ];
      _texCoord = [ 0.0, 1.0,
                    1.0, 1.0,
                    1.0, 0.0,
                    0.0, 0.0 ];
      _strides = [ 2, 2 ]; 
      _locNames = ["pos", "texCoord"];

      _vboHdr = new VBOHdr(2, _program);
      _ibo = new IBO;
      _ibo.create(_index);

      float[8] weight = gauss_weight(300.0);

      _uniLoc = new UniformLocation(_program, type);
      _uniLoc.attach("tex", 0, "1i");
      _uniLoc.attach("type", num, "1i");
      _uniLoc.attach("weight", weight, "1fv", 40);
    }

    void draw() {
      _fbo.bind();
      glViewport(0, 0, 256, 256);

      _vboHdr.create_vbo(_mesh, _texCoord);
      _vboHdr.enable_vbo(_locNames, _strides);
      auto drawMode = DrawMode.Triangles;

      _ibo.draw(drawMode); 

      quit();
    }

    void quit() {
      _fbo.unbind();
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
    }

  private:
    RBO _rbo;
    FBO _fbo;

    GLuint _program;

    UniformLocation _uniLoc;

    float[] _mesh;
    float[] _texCoord;
    int[] _index;
    string[] _locNames;
    int[] _strides;
    VBOHdr _vboHdr;
    IBO _ibo;
}
