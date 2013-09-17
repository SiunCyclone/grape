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

  private:
    GLuint _id;
    dg _generate;
    dg _eliminate;
    dg _bind;
    dg _unbind;
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
      foreach (int i, vbo; _vboList)
        vbo.locate(_program, strides[i], i, locNames[i]);
    }

  private:
    int _num;
    VBO[] _vboList;
    GLuint _program;
}

class AttributeLocation {
  public:
    void bind(GLuint program, int num, string name) {
      glBindAttribLocation(program, num, cast(char*)name);
    }

    void get(GLuint program, string name) {
      _location = glGetAttribLocation(program, cast(char*)name);
    }

    void attach(int stride) {
      glEnableVertexAttribArray(_location);
      glVertexAttribPointer(_location, stride, GL_FLOAT, GL_FALSE, 0, null);
    }

  private:
    GLint _location;
}

class VBO : Binder {
  public:
    this() {
      _attLoc = new AttributeLocation;
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

    void locate(GLuint program, int stride, int num, string name) {
      bind();
      _attLoc.bind(program, num, name);
      _attLoc.get(program, name);
      _attLoc.attach(stride);
      unbind();
    }

    /*
    void draw(DrawMode mode) {
      glDrawArrays(mode, 0, 3);
    }
    */
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
      _rbo = new RBO;
      _fbo = new FBO;
      _camera = new Camera;
    }

    ~this() {
    }

    void init(Texture texture) {
      _fbo.create(texture);

      _fbo.bind();
      _rbo.create(GL_DEPTH_COMPONENT, 512, 512);
      _rbo.attach(GL_DEPTH_ATTACHMENT);

      GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
      glDrawBuffers(1, drawBufs.ptr);

      _fbo.unbind();
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
      _ibo = new IBO;
      _ibo.create(_index);
    }

    void draw() {
      _fbo.bind();
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

    Camera _camera;
    GLuint _program;
    float[] _mesh;
    float[] _color;
    int[] _index;
    string[] _locNames;
    int[] _strides;
    VboHdr _vboHdr;
    IBO _ibo;
}

