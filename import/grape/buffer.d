/**
 * このモジュールをユーザーが直接使用することはありません。
 */

module grape.buffer;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;
import std.math;

import grape.window;
import grape.file;
import grape.math;
import grape.camera;
import grape.surface;
import grape.shader;

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

class UniformN {
  public:
    static this() {
      _uniInt["1i"] = (location, value) { glUniform1i(location, value); };
      _uniFloatV["1fv"] = (location, value, num) { glUniform1fv(location, num, value.ptr); };
      _uniFloatV["2fv"] = (location, value, num) { glUniform2fv(location, num, value.ptr); };
      _uniFloatV["3fv"] = (location, value, num) { glUniform3fv(location, num, value.ptr); };
      _uniFloatV["4fv"] = (location, value, num) { glUniform4fv(location, num, value.ptr); };
      _uniFloatV["mat4fv"] = (location, value, num) { glUniformMatrix4fv(location, num, GL_FALSE, value.ptr); };
    }

    static void locate(in string name, in int value, in string type, in int num, in GLint location) {
      _uniInt[type](location, value);
    }

    static void locate(in string name, in float[] value, in string type, in int num, in GLint location) {
      _uniFloatV[type](location, value, num);
    }

  private:
    static void delegate(in GLint, in int)[string] _uniInt;
    static void delegate(in GLint, in float[], in int)[string] _uniFloatV;
    //static void delegate(in int[])[string] _uniIntV;
    //static void delegate(in float)[string] _uniFloat;
}

class UniformLocationN {
  public:
    static void attach(T)(in GLuint program, in string name, in T value, in string type, in int num=1) {
      auto location = glGetUniformLocation(program, cast(char*)name); 
      _uniformN.locate(name, value, type, num, location);
    }

  private:
    static UniformN _uniformN;
}

class AttributeLocationN {
  public:
    static void attach(in GLuint program, in string name, in int stride, in int i) {
      glBindAttribLocation(program, i, cast(char*)name);
      _location = glGetAttribLocation(program, cast(char*)name);
      locate(stride);
    }

  private:
    static void locate(in int stride) {
      glEnableVertexAttribArray(_location);
      glVertexAttribPointer(_location, stride, GL_FLOAT, GL_FALSE, 0, null);
    }

    static GLint _location;
}

class VBON {
  public:
    this() {
      glGenBuffers(1, &_id);
    }

    ~this() {
      glDeleteBuffers(1, &_id); 
    }

    void set(T)(in GLuint program, in T data, in string name, in int stride, in int i) {
      glBindBuffer(GL_ARRAY_BUFFER, _id); 
      glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STREAM_DRAW);
      AttributeLocationN.attach(program, name, stride, i);
      glBindBuffer(GL_ARRAY_BUFFER, 0); 
    }

  private:
    GLuint _id;
}

class IBO {
  public:
    this() {
      glGenBuffers(1, &_id);
    }

    ~this() {
      glDeleteBuffers(1, &_id);
    }

    void create(in int[] index) { // const
      _index = index.dup;
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _id); 
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index[0].sizeof*_index.length, _index.ptr, GL_STREAM_DRAW);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); 
    }

    void draw(in DrawMode mode) { 
      glDrawElements(mode, cast(int)_index.length, GL_UNSIGNED_INT, _index.ptr);
    }

  private: 
    GLuint _id;
    int[] _index;
}

class RBO {
  public: 
    this() {
      glGenRenderbuffers(1, &_id);
    }

    ~this() {
      glDeleteRenderbuffers(1, &_id);
    }

    void create(T)(in T type, in int w, in int h) {
      glBindRenderbuffer(GL_RENDERBUFFER, _id);
      glRenderbufferStorage(GL_RENDERBUFFER, type, w, h);
      glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }

    void attach(T)(in T type) {
      glBindRenderbuffer(GL_RENDERBUFFER, _id);
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, type, GL_RENDERBUFFER, _id);
      glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }

  private:
    GLuint _id;
}

class FBO {
  public:
    this() {
      glGenFramebuffers(1, &_id);
    }

    ~this() {
      glDeleteFramebuffers(1, &_id);
    }

    void create(T)(in T texture) {
      glBindFramebuffer(GL_FRAMEBUFFER, _id);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void binded_scope(void delegate() dg) {
      glBindFramebuffer(GL_FRAMEBUFFER, _id);
      dg();
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

  // TODO Check whether fbo is certainly compiled 
  // glCheckFramebufferStatus 

  private:
    GLuint _id;
}

class Texture {
  public:
    this() {
      glGenTextures(1, &_id);
    }

    ~this() {
      glDeleteTextures(1, &_id);
    }

    // TODO divide
    void create(in int w, in int h, void* pixels, in int bytesPerPixel) {
      set_draw_mode(bytesPerPixel);
      _w = w;
      _h = h;

      glActiveTexture(GL_TEXTURE0); // TODO Cover other units

      glBindTexture(GL_TEXTURE_2D, _id);
      attach(w, h, pixels); filter();
      glBindTexture(GL_TEXTURE_2D, 0);
    }

    void create(Surface surf) {
      create(surf.w, surf.h, surf.pixels, surf.bytes_per_pixel);
    }

    // Provides a scope that a texture is enabled.
    void texture_scope(void delegate() dg) {
      glBindTexture(GL_TEXTURE_2D, _id);
      glActiveTexture(GL_TEXTURE0);
      dg();
      glActiveTexture(GL_TEXTURE0); // Need? It's only needed if dg() changes the texture-unit.
      glBindTexture(GL_TEXTURE_2D, 0);
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

    GLuint _id;
    int _mode;
    int _w;
    int _h;
}


/*******************ここから************************/
deprecated class VBOHdr {
  public:
    this(in size_t num, in GLuint program) {
      _num = num;
      _vboList.length = _num;
      for (int i; i<_num; ++i)
        _vboList[i] = new VBO(program);
    }

    void create_vbo(in float[][] list...) {
      assert(list.length == _num, "Doesn't match the number of vbo attributes");

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
    size_t _num;
    VBO[] _vboList;
}

deprecated class VBO {
  public:
    this(in GLuint program) {
      _attLoc = new AttributeLocation(program);
      glGenBuffers(1, &_id);
    }

    ~this() {
      glDeleteBuffers(1, &_id); 
    }

    void create(T)(in T data) {
      glBindBuffer(GL_ARRAY_BUFFER, _id); 
      glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STREAM_DRAW);
      glBindBuffer(GL_ARRAY_BUFFER, 0); 
    }

    void attach(in string name, in int stride, in int i) {
      glBindBuffer(GL_ARRAY_BUFFER, _id); 
      _attLoc.attach(name, stride, i);
      glBindBuffer(GL_ARRAY_BUFFER, 0); 
    }

  private:
    GLuint _id;
    AttributeLocation _attLoc;
}

deprecated class AttributeLocation {
  public:
    this(in GLuint program) {
      _program = program;
    }

    void attach(in string name, in int stride, in int i) {
      glBindAttribLocation(_program, i, cast(char*)name);
      _location = glGetAttribLocation(_program, cast(char*)name);
      locate(stride);
    }

  private:
    void locate(in int stride) {
      glEnableVertexAttribArray(_location);
      glVertexAttribPointer(_location, stride, GL_FLOAT, GL_FALSE, 0, null);
    }

    GLuint _program;
    GLint _location;
}

deprecated class Uniform {
  public:
    this(){
      init();
    }

    this(string vShader, string fShader) {
      this();
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

deprecated class UniformLocation {
  public:
    this(in GLuint program) {
      _program = program;
      _uniform = new Uniform;
    }

    void attach(T)(in string name, in T value, in string type, in int num=1) {
      _location = glGetUniformLocation(_program, cast(char*)name); 
      _uniform.locate(name, value, type, num, _location);
    }

  private:
    Uniform _uniform;
    GLuint _program;
    GLint _location;
}

/************************ここまでいらない*************/

