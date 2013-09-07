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
      //glDrawArrays(mode, 0, 3);
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
    }

    ~this() {

    }

    // args is weird
    void create_texture(SDL_Surface* surf, string locName) {
      _surf = surf;
      bind_texture();
      set_location(locName);
    }

    void delete_texture() {
      SDL_FreeSurface(_surf);
      glDeleteTextures(1, &_tid);
    }

  private:
    void set_draw_mode() {
      _mode = (_surf.format.BytesPerPixel == 4) ? GL_RGBA : GL_RGB;
    }
   
    void bind_texture() {
      set_draw_mode();

      // check here
      glActiveTexture(GL_TEXTURE0);
      glGenTextures(1, &_tid);
      glBindTexture(GL_TEXTURE_2D, _tid);
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, _surf.w, _surf.h, 0, _mode, GL_UNSIGNED_BYTE, _surf.pixels);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

    void set_location(string locName){
      auto location = glGetUniformLocation(_program, cast(char*)locName);
      glUniform1i(location, 0); // change last parameter
    }

    SDL_Surface* _surf;
    GLuint _program;
    GLuint _tid;
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
    }

    ~this() {
    }

    void set(GLuint program) {
      _program = program;

      FileHdr _fileHdr = new FileHdr;
      string fileName = "./resource/box.obj";
      _mesh = _fileHdr.make_mesh(fileName);
      _index = _fileHdr.make_index(fileName);
      _locNames = ["pos", "color"];
      _strides = [ 3, 4 ]; 

      for (int i; i<_mesh.length/3; ++i)
        _color ~= [ 0.5, 0.8, 0.0, 1.0 ];

      _vboHdr = new VboHdr(2, _program);
      _iboHdr = new IboHdr(1);
      _iboHdr.create_ibo(_index);
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

    void draw() {
      glBindFramebuffer(GL_FRAMEBUFFER, _fbo);

      glViewport(0, 0, 512, 512);
      Camera camera = new Camera;
      camera.perspective(45.0, cast(float)512/512, 0.1, 100.0);

      Vec3 eye = Vec3(2, 2, 2);
      Vec3 center = Vec3(0, 0, 0);
      Vec3 up = Vec3(0, 1, 0);
      camera.look_at(eye, center, up);
      auto loc = glGetUniformLocation(_program, "pvmMatrix");
      glUniformMatrix4fv(loc, 1, GL_FALSE, camera.pvMat4.mat.ptr);

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

    GLuint _program;
    float[] _mesh;
    float[] _color;
    int[] _index;
    string[] _locNames;
    int[] _strides;
    VboHdr _vboHdr;
    IboHdr _iboHdr;
}
