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
      free();
    }

    void bind(T)(T type) { //TODO typeの型
      free();
      glBindBuffer(type, _buffer);
    }

  private:
    void free() {
      if (&_buffer != null)
        glDeleteBuffers(1, &_buffer);
    }

    GLuint _buffer;
}

class VBO {
  public:
    this() {
      _vbo = new BufferObject;
    }

    void create(T)(T data) {
      _vbo.bind(GL_ARRAY_BUFFER);
      glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STATIC_DRAW); //TODO static
    }

    void attach(GLuint location, int stride) {
      _vbo.bind(GL_ARRAY_BUFFER);
      glEnableVertexAttribArray(location);
      glVertexAttribPointer(location, stride, GL_FLOAT, GL_FALSE, 0, null);
    }

  private:
    BufferObject _vbo;
}

// TODO naame
// XXX VBO class使うと表示されない
class VboHdr {
  public:
    this(in int num, in GLuint program) {
      _program = program;
      _num = num;
      _vboList.length = _num;
      glGenBuffers(num, _vboList.ptr);
      /*
      for (int i; i<_num; ++i)
        _vboList[i] = new VBO;
        */
    }

    void create_vbo(T...)(T list) {
      assert(list.length == _num);
      delete_vbo();

      foreach(int i, data; list) {
        //_vboList[i].create(data);
        glBindBuffer(GL_ARRAY_BUFFER, _vboList[i]);
        glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
      }
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
      foreach (int i, vbo; _vboList) {
        //vbo.attach(_attLoc[i], strides[i]);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glEnableVertexAttribArray(_attLoc[i]);
        glVertexAttribPointer(_attLoc[i], strides[i], GL_FLOAT, GL_FALSE, 0, null);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
      }
    }
    
    void delete_vbo() {
      if (_vboList.length > 0)
        glDeleteBuffers(_vboList.length, _vboList.ptr);
    }

    int _num;
    GLuint[] _vboList;
    //VBO[] _vboList;
    GLint[] _attLoc;
    GLuint _program;
}

class IboHdr {
  public:
    this(in int num) {
      glGenBuffers(num, &_ibo);
    }

    ~this() {
      delete_ibo();
    }

    void create_ibo(int[] index) {
      delete_ibo();

      _index = index;
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, _index[0].sizeof*_index.length, _index.ptr, GL_STATIC_DRAW);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    
    void draw(DrawMode mode) {
      glDrawElements(mode, _index.length, GL_UNSIGNED_INT, _index.ptr);
    }

  private:
    void delete_ibo() {
      // num 1
      glDeleteBuffers(1, &_ibo);
    }

    GLuint _ibo;
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
      unbind();
      bind();
      attach(w, h, pixels);
      filter();
      unbind();
    }

    void enable() {
      glActiveTexture(GL_TEXTURE0);
      bind();
    }

    GLuint _tid;
    alias _tid this;

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

class FboHdr {
  public:
    this() {
      glGenFramebuffers(1, &_fbo);
      glBindFramebuffer(GL_FRAMEBUFFER, _fbo);

      glGenTextures(1, &renderTex);
      glGenRenderbuffers(1, &depthBuf);
      //_texture = new Texture;
      _camera = new Camera;
    }

    ~this() {
    }

    void init() {
      //_texture.bind(512, 512, null, GL_RGBA);
      glActiveTexture(GL_TEXTURE1);
      glBindTexture(GL_TEXTURE_2D, renderTex);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderTex, 0);
      //glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);

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
    GLuint renderTex;

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

