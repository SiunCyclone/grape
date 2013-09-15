module orange.buffer;

import opengl.glew;
import orange.shader;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import derelict.sdl2.ttf;
import std.stdio;
import orange.window;
import orange.shader;
import orange.file;
import orange.math;
import orange.camera;
import orange.surface;

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

class BufferObject {
  public:
    this() {
      glGenBuffers(1, &_buffer);
    }

    ~this() {
      glDeleteBuffers(1, &_buffer);
    }

    void bind(T)(T type) { // TODO GL_ARRAY_BUFFER の enum作る
      glBindBuffer(type, _buffer);
    }

    void attach(T, S)(T type, S data) {
      glBufferData(type, data[0].sizeof*data.length, data.ptr, GL_STATIC_DRAW); //TODO static
    }

    void unbind(T)(T type) {
      glBindBuffer(type, 0);
    }

  private:
    GLuint _buffer;
}

class VBO {
  public:
    this() {
      _vbo = new BufferObject;
    }

    void create(T)(T data) {
      _vbo.bind(GL_ARRAY_BUFFER);
      _vbo.attach(GL_ARRAY_BUFFER, data);
      _vbo.unbind(GL_ARRAY_BUFFER);
    }

    void attach(GLuint location, int stride) {
      _vbo.bind(GL_ARRAY_BUFFER);
      glEnableVertexAttribArray(location);
      glVertexAttribPointer(location, stride, GL_FLOAT, GL_FALSE, 0, null);
      _vbo.unbind(GL_ARRAY_BUFFER);
    }

  private:
    BufferObject _vbo;
}

// TODO name
class VboHdr {
  public:
    this(in int num, in GLuint program) {
      _program = program;
      _num = num;
      _vboList.length = _num;
      for (int i; i<_num; ++i)
        _vboList[i] = new VBO;
    }

    void create_vbo(T...)(T list) {
      assert(list.length == _num);

      foreach(int i, data; list)
        _vboList[i].create(data);
    }

    void enable_vbo(string[] locNames, int[] strides) {
      assert(locNames.length == _num);
      assert(strides.length == _num);
      bind_attLoc(locNames);
      get_attLoc(locNames);
      attach_attLoc_to_vbo(strides);
    }

    /*
    void draw(DrawMode mode) {
      //glDrawArrays(mode, 0, 3);
    }
    */

  private:
    void bind_attLoc(string[] locNames) {
      foreach (int i, name; locNames) 
        glBindAttribLocation(_program, i, cast(char*)name);
    }

    void get_attLoc(string[] locNames) {
      foreach (name; locNames)
        _attLoc ~= glGetAttribLocation(_program, cast(char*)name);
    }

    void attach_attLoc_to_vbo(int[] strides) {
      foreach (int i, vbo; _vboList)
        vbo.attach(_attLoc[i], strides[i]);
    }

    int _num;
    VBO[] _vboList;
    GLint[] _attLoc;
    GLuint _program;
}

class IBO {
  public:
    this() {
      _ibo = new BufferObject;
    }

    void create(T)(T data) {
      _ibo.bind(GL_ELEMENT_ARRAY_BUFFER);
      _ibo.attach(GL_ELEMENT_ARRAY_BUFFER, data);
      _ibo.unbind(GL_ELEMENT_ARRAY_BUFFER);
    }

  private:
    BufferObject _ibo;
}

class IboHdr {
  public:
    this(in int num) { // TODO numいらないかも
      _ibo = new IBO;
    }

    void create_ibo(int[] index) {
      _index = index;
      _ibo.create(_index);
    }
    
    void draw(DrawMode mode) { 
      glDrawElements(mode, _index.length, GL_UNSIGNED_INT, _index.ptr);
    }

  private:
    IBO _ibo;
    int[] _index;
}

class Texture {
  public:
    this() {
      glGenTextures(1, &_tid);
    }

    ~this() {
      glDeleteTextures(1, &_tid);
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

    GLuint _tid;
    alias _tid this; // TODO private

  private:
    void set_draw_mode(int bytesPerPixel) {
      _mode = (bytesPerPixel == 4) ? GL_RGBA : GL_RGB;
    }

    void bind() {
      glBindTexture(GL_TEXTURE_2D, _tid);
    }

    void unbind() {
      glBindTexture(GL_TEXTURE_2D, 0);
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
      glUniform1i(loc, 0); // TODO change last parameter
    }

    GLuint _program;
    Texture _texture;
}


class UniHdr {
  public:


  private:
}

class FBO {
  public:
    this() {
      glGenFramebuffers(1, &_fbo);
    }

    ~this() {
      glDeleteFramebuffers(1, &_fbo);
    }

    void bind() {
      glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    }

    void unbind() {
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

  private:
    GLuint _fbo;
}

class RBO {
  public:
    this() {
      glGenRenderbuffers(1, &_rbo);
    }

    ~this() {
      glDeleteFramebuffers(1, &_rbo);
    }
    
    void bind() {
      glBindRenderbuffer(GL_RENDERBUFFER, _rbo);
    }

    void nanikore() {
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, 512, 512);
    }

  private:
    GLuint _rbo;

}

class FboHdr {
  public:
    this() {
      glGenFramebuffers(1, &_fbo);
      glBindFramebuffer(GL_FRAMEBUFFER, _fbo);

      glGenRenderbuffers(1, &depthBuf);
      _texture = new Texture;
      _camera = new Camera;
    }

    ~this() {
    }

    void init() {
      _texture.create(512, 512, null, GL_RGBA);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);

      glBindRenderbuffer(GL_RENDERBUFFER, depthBuf);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, 512, 512);
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuf);

      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);

      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void set(GLuint program) {
      _program = program;

      FileHdr _fileHdr = new FileHdr;
      string fileName = "./resource/sphere.obj";
      _mesh = _fileHdr.make_mesh(fileName);
      _index = _fileHdr.make_index(fileName);
      _locNames = ["pos", "color"];
      _strides = [ 3, 4 ]; 

      for (int i; i<_mesh.length/3; ++i)
        _color ~= [ 0.6, 0.8, 1.0, 1.0 ];

      _vboHdr = new VboHdr(2, _program);
      _iboHdr = new IboHdr(1);
      _iboHdr.create_ibo(_index);
    }

    void draw() {
      glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
      glViewport(0, 0, 512, 512);

      _camera.perspective(45.0, cast(float)512/512, 0.1, 100.0);

      Vec3 eye = Vec3(3, 3, 3);
      Vec3 center = Vec3(0, 0, 0);
      Vec3 up = Vec3(0, 1, 0);
      _camera.look_at(eye, center, up);
      auto loc = glGetUniformLocation(_program, "pvmMatrix");
      glUniformMatrix4fv(loc, 1, GL_FALSE, _camera.pvMat4.mat.ptr);

      _vboHdr.create_vbo(_mesh, _color);
      _vboHdr.enable_vbo(_locNames, _strides);
      auto drawMode = DrawMode.Triangles;

      _texture.enable();
      _iboHdr.draw(drawMode); 

      quit();
    }

    void quit() {
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
    }

  private:
    GLuint _fbo;
    GLuint depthBuf;

    Texture _texture;

    Camera _camera;
    GLuint _program;
    float[] _mesh;
    float[] _color;
    int[] _index;
    string[] _locNames;
    int[] _strides;
    VboHdr _vboHdr;
    IboHdr _iboHdr;
}

