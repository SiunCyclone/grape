module grape.buffer;

//import opengl.glew;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import derelict.sdl2.ttf;
import std.stdio;
import grape.window;
import grape.file;
import grape.math;
import grape.camera;
import grape.surface;
import grape.shader;

import std.math;

enum DrawMode {
  Points = GL_POINTS,
  Lines = GL_LINES,
  LineLoop = GL_LINE_LOOP,
  LineStrip = GL_LINE_STRIP,
  Triangles = GL_TRIANGLES,
  TriangleStrip = GL_TRIANGLE_STRIP,
  TriangleFan = GL_TRIANGLE_FAN,
  //Quads = GL_QUADS
}

alias void delegate() void_dg;

class Binder {
  public:
    this(void delegate(ref void_dg, ref void_dg, ref void_dg, ref void_dg) init) {
      init(_generate, _eliminate, _bind, _unbind);
      _generate();
    }

    ~this() {
      _eliminate();
    }

    void binded_scope(void_dg dg) {
      _bind();
      dg();
      _unbind();
    }

  protected:
    GLuint _id;
    void_dg _generate;
    void_dg _eliminate;
    void_dg _bind;
    void_dg _unbind;
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

    void create_vbo(in float[][] list...) {
      assert(list.length == _num);

      foreach(int i, data; list)
        _vboList[i].create(data);
    }

    void enable_vbo(in string[] locNames, in int[] strides) {
      assert(locNames.length == _num);
      assert(strides.length == _num);

      foreach (int i, vbo; _vboList)
        vbo.attach(locNames[i], strides[i], i);
    }

    void draw(in DrawMode mode, in int num) {
      glDrawArrays(mode, 0, num);
    }

  private:
    int _num;
    VBO[] _vboList;
}

class Location {
  public:
    this(in GLuint program, in void delegate(string) get) {
      _get = get;
      _program = program;
    }

  protected:
    GLuint _program;
    GLint _location;
    void delegate(string) _get;
}

class AttributeLocation : Location {
  public:
    this(in GLuint program) {
      auto get = (string name) { _location = glGetAttribLocation(_program, cast(char*)name); };
      super(program, get);
    }

    void attach(in string name, in int stride, in int i) {
      bind(name, i);
      _get(name);
      locate(stride);
    }

  private:
    void bind(in string name, in int i) {
      glBindAttribLocation(_program, i, cast(char*)name);
    }

    void locate(in int stride) {
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

    void locate(in string name, in int value, in string type, in int num, in GLint location) {
      _uniInt[type](location, value);
    }

    void locate(in string name, in float[] value, in string type, in int num, in GLint location) {
      _uniFloatV[type](location, value, num);
    }

  private:
    void init() {
      _uniInt["1i"] = (location, value) { glUniform1i(location, value); };
      _uniFloatV["1fv"] = (location, value, num) { glUniform1fv(location, num, value.ptr); };
      _uniFloatV["2fv"] = (location, value, num) { glUniform2fv(location, num, value.ptr); };
      _uniFloatV["3fv"] = (location, value, num) { glUniform3fv(location, num, value.ptr); };
      _uniFloatV["4fv"] = (location, value, num) { glUniform4fv(location, num, value.ptr); };
      _uniFloatV["mat4fv"] = (location, value, num) { glUniformMatrix4fv(location, num, GL_FALSE, value.ptr); };
    }

    // TODO ソースから判別
    void extract(string vShader, string fShader) {
    }

    void delegate(in GLint, in int)[string] _uniInt;
    //void delegate(int[])[string] _uniIntV;
    //void delegate(float)[string] _uniFloat;
    void delegate(in GLint, in float[], in int)[string] _uniFloatV;
}

class UniformLocation : Location {
  public:
    this(in GLuint program) {
      auto get = (string name) { _location = glGetUniformLocation(_program, cast(char*)name); };
      super(program, get);
      _uniform = new Uniform();
    }

    /*
    this(in GLuint program, in ShaderProgramType type) {
      auto get = (string name) { _location = glGetUniformLocation(_program, cast(char*)name); };
      super(program, get);
      init(type);
    }
    */

    void attach(T)(in string name, in T value, in string type, in int num=1) {
      _get(name);
      _uniform.locate(name, value, type, num, _location);
    }

  private:
    /*
    void init(in ShaderProgramType type) {
      string vShader, fShader;
      ShaderSource.load(type)(vShader, fShader);
      _uniform = new Uniform(vShader, fShader);
    }
    */

    Uniform _uniform;
}

class VBO : Binder {
  public:
    this(in GLuint program) {
      _attLoc = new AttributeLocation(program);

      auto init = (ref void_dg generate, ref void_dg eliminate, ref void_dg bind, ref void_dg unbind) {
        generate = { glGenBuffers(1, &_id); };
        eliminate = { glDeleteBuffers(1, &_id); };
        bind = { glBindBuffer(GL_ARRAY_BUFFER, _id); };
        unbind = { glBindBuffer(GL_ARRAY_BUFFER, 0); };
      };
      super(init);
    }

    void create(T)(in T data) {
      binded_scope({ glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STREAM_DRAW); });
    }

    void attach(in string name, in int stride, in int num) {
      binded_scope({ _attLoc.attach(name, stride, num); });
    }

  private:
    AttributeLocation _attLoc;
}

class IBO : Binder {
  public:
    this() {
      auto init = (ref void_dg generate, ref void_dg eliminate, ref void_dg bind, ref void_dg unbind) {
        generate = { glGenBuffers(1, &_id); };
        eliminate = { glDeleteBuffers(1, &_id); };
        bind = { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _id); };
        unbind = { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); };
      };
      super(init);
    }

    void create(in int[] index) { // const
      _index = index.dup;
      binded_scope({ glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index[0].sizeof*_index.length, _index.ptr, GL_STREAM_DRAW); });
    }

    void draw(in DrawMode mode) { 
      glDrawElements(mode, cast(int)_index.length, GL_UNSIGNED_INT, _index.ptr);
    }

  private: 
    int[] _index;
}

class RBO : Binder {
  this() {
    auto init = (ref void_dg generate, ref void_dg eliminate, ref void_dg bind, ref void_dg unbind) {
      generate = { glGenRenderbuffers(1, &_id); };
      eliminate = { glDeleteRenderbuffers(1, &_id); };
      bind = { glBindRenderbuffer(GL_RENDERBUFFER, _id); };
      unbind = { glBindRenderbuffer(GL_RENDERBUFFER, 0); };
    };
    super(init);
  }

  void create(T)(in T type, in int w, in int h) {
    binded_scope({ glRenderbufferStorage(GL_RENDERBUFFER, type, w, h); });
  }

  void attach(T)(in T type) {
    binded_scope({ glFramebufferRenderbuffer(GL_FRAMEBUFFER, type, GL_RENDERBUFFER, _id); });
  }
}

class FBO : Binder {
  this() {
    auto init = (ref void_dg generate, ref void_dg eliminate, ref void_dg bind, ref void_dg unbind) {
      generate = { glGenFramebuffers(1, &_id); };
      eliminate = { glDeleteFramebuffers(1, &_id); };
      bind = { glBindFramebuffer(GL_FRAMEBUFFER, _id); };
      unbind = { glBindFramebuffer(GL_FRAMEBUFFER, 0); };
    };
    super(init);
  }

  void create(T)(in T texture) {
    binded_scope({ glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0); });
  }

  // TODO Check whether fbo is certainly compiled 
  // glCheckFramebufferStatus 
}

class Texture : Binder {
  public:
    this() {
      auto init = (ref void_dg generate, ref void_dg eliminate, ref void_dg bind, ref void_dg unbind) {
        generate = { glGenTextures(1, &_id); };
        eliminate = { glDeleteTextures(1, &_id); };
        bind = { glBindTexture(GL_TEXTURE_2D, _id); };
        unbind = { glBindTexture(GL_TEXTURE_2D, 0); };
      };
      super(init);
    }

    // TODO divide
    void create(in int w, in int h, void* pixels, in int bytesPerPixel) {
      set_draw_mode(bytesPerPixel);
      _w = w;
      _h = h;

      glActiveTexture(GL_TEXTURE0); // TODO Cover other units
      binded_scope({ attach(w, h, pixels); filter(); });
    }

    void create(Surface surf) {
      create(surf.w, surf.h, surf.pixels, surf.bytes_per_pixel);
    }

    // Provides a scope that a texture is enabled.
    void texture_scope(void_dg dg) {
      binded_scope({
        glActiveTexture(GL_TEXTURE0);
        dg();

        // Need? It's only needed if dg() changes the texture-unit.
        glActiveTexture(GL_TEXTURE0);
      });
    }

    alias _id this; // TODO private

    @property {
      int w() {
        return _w;
      }

      int h() {
        return _h;
      }
    }

  private:
    void set_draw_mode(in int bytesPerPixel) {
      _mode = (bytesPerPixel == 4) ? GL_RGBA : GL_RGB;
    }

    void attach(in int w, in int h, void* pixels) { // const
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, w, h, 0, _mode, GL_UNSIGNED_BYTE, pixels);
    }

    void filter() {
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    int _mode;
    int _w;
    int _h;
}

deprecated class TexHdr {
  public:
    this(in GLuint program) {
      _program = program; 
      _texture = new Texture;
    }

    void create(Surface surf, in string locName) { // const
      _texture.create(surf.w, surf.h, surf.pixels, surf.bytes_per_pixel);
      set_location(locName);
    }

    void applied_scope(void_dg dg) {
      _texture.texture_scope({ dg(); });
    }

  private:
    void set_location(in string locName){
      auto loc = glGetUniformLocation(_program, cast(char*)locName);
      glUniform1i(loc, 0); // TODO
    }

    GLuint _program;
    Texture _texture;
}

deprecated class FBOHdr {
  public:
    this() {
      _rbo = new RBO;
      _fbo = new FBO;
      _camera = new Camera;
    }

    void init(Texture texture) { //const
      _fbo.create(texture);

      _fbo.binded_scope({
        _rbo.create(GL_DEPTH_COMPONENT, 1024, 1024);
        _rbo.attach(GL_DEPTH_ATTACHMENT);

        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);
      });
    }

    void set(in GLuint program, in ShaderProgramType type) {
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

      //_uniLoc = new UniformLocation(_program, type);
      _uniLoc = new UniformLocation(_program);
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
      _fbo.binded_scope({
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
      });

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

deprecated class GaussHdr {
  public:
    this() {
      _rbo = new RBO;
      _fbo = new FBO;
    }

    void init(Texture texture) {
      _fbo.create(texture);

      _fbo.binded_scope({
        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);
      });
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

    void set(in GLuint program, in ShaderProgramType type) {
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

      //_uniLoc = new UniformLocation(_program, type);
      _uniLoc = new UniformLocation(_program);
      _uniLoc.attach("tex", 0, "1i");
      _uniLoc.attach("weight", weight, "1fv", 8);
    }

    void draw() {
      _fbo.binded_scope({
        glViewport(0, 0, 256, 256);

        _vboHdr.create_vbo(_mesh, _texCoord);
        _vboHdr.enable_vbo(_locNames, _strides);
        auto drawMode = DrawMode.Triangles;

        _ibo.draw(drawMode); 
      });

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

