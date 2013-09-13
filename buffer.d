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

class VboHdr {
  public:
    this(in int num, in GLuint program) {
      _num = num;
      _vboList.length = _num;
      _program = program;
      glGenBuffers(num, _vboList.ptr);
    }

    ~this() {
      delete_vbo();
    }

    void create_vbo(T...)(T list) {
      assert(list.length == _num);
      delete_vbo();

      foreach(int i, data; list) {
        glBindBuffer(GL_ARRAY_BUFFER, _vboList[i]);
        // static draw is what?
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

    void draw(DrawMode mode) {
      //glDrawArrays(mode, 0, 3); // TODO
    }

  private:
    void bind_attLoc(string[] locNames) {
      foreach(int i, name; locNames) 
        glBindAttribLocation(_program, i, cast(char*)name);
    }

    void get_attLoc(string[] locNames) {
      foreach(name; locNames)
        _attLoc ~= glGetAttribLocation(_program, cast(char*)name);
    }

    void attach_attLoc_to_vbo(int[] strides) {
      foreach (int i, GLuint vbo; _vboList) {
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

class TexHdr {
  public:
    this(GLuint program) {
      _program = program; 
      _texture = new Texture;
    }

    void create_texture(Surface surf, string locName) {
      _texture.create(surf);
      set_location(locName);
    }

  private:
    void bind_texture(Surface surf) {
      glActiveTexture(GL_TEXTURE0); // TODO check here
      glGenTextures(1, &_tid);
      glBindTexture(GL_TEXTURE_2D, _tid);
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, surf.w, surf.h, 0, _mode, GL_UNSIGNED_BYTE, surf.pixels);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    void set_location(string locName){
      auto loc = glGetUniformLocation(_program, cast(char*)locName);
      glUniform1i(loc, 0); // TODO change last parameter
    }

    GLuint _program;
    GLuint _tid;
    int _mode;
    Texture _texture;
}

class Texture {
  public:
    this() {
      glGenTextures(1, &_tid);
    }

    ~this() {
      glDeleteTextures(1, &_tid);
    }

    void create(Surface surf) {
      set_draw_mode(surf);

      glActiveTexture(GL_TEXTURE0); // TODO 0以外も対応

      // TODO FBOに対応
      glBindTexture(GL_TEXTURE_2D, _tid);
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, surf.w, surf.h, 0, _mode, GL_UNSIGNED_BYTE, surf.pixels);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

  private:
    void set_draw_mode(Surface surf) {
      _mode = (surf.bytes_per_pixel == 4) ? GL_RGBA : GL_RGB;
    }

    uint _tid;
    int _mode;
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

      _camera = new Camera;
    }

    ~this() {
    }

    void init() {
      GLuint renderTex;
      glGenTextures(1, &renderTex);
      glActiveTexture(GL_TEXTURE0);
      glBindTexture(GL_TEXTURE_2D, renderTex);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderTex, 0);

      GLuint depthBuf;
      glGenRenderbuffers(1, &depthBuf);
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
      _iboHdr.draw(drawMode); // FIXME configからtopに戻るとsegvる

      quit();
    }

    void quit() {
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
      glViewport(0, 0, WINDOW_X, WINDOW_Y);
    }

  private:
    GLuint _fbo;

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

