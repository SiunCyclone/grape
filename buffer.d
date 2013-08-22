module orange.buffer;

import opengl.glew;
import orange.shader;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import derelict.sdl2.ttf;
import std.stdio;

class VboHandler {
  public:
    this(in int num, in GLuint program) {
      _vboList.length = num;
      _program = program;
      glGenBuffers(num, _vboList.ptr);
    }

    ~this() {
      glDeleteBuffers(_vboList.length, _vboList.ptr);
    }

    void create_vbo(T...)(T list) {
      foreach(int i, data; list) {
        glBindBuffer(GL_ARRAY_BUFFER, _vboList[i]);
        // static draw is what?
        glBufferData(GL_ARRAY_BUFFER, data[0].sizeof*data.length, data.ptr, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
      }
    }

    void enable_vbo(string[] locNames, int[] strides) {
      bind_attLoc(locNames);
      get_attLoc(locNames);
      attach_attLoc_to_vbo(strides);
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

    GLuint[] _vboList;
    GLint[] _attLoc;
    GLuint _program;
}

class IboHandler {
  public:
    this(in int num) {
      glGenBuffers(num, &_ibo);
    }

    ~this() {
      // num 1
      glDeleteBuffers(1, &_ibo);
    }
    void create_ibo(int[] index) {
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, index[0].sizeof*index.length, index.ptr, GL_STATIC_DRAW);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

  private:
    GLuint _ibo;
}

class TextureHandler {
  public:
    this() {
      
    }

    ~this() {

    }

    void load_image(string file) {
      _image = IMG_Load(cast(char*) file);
      enforce(_image != null, "create_image() failed");
      set_draw_mode();
    }

    void create_texture() {
      glActiveTexture(GL_TEXTURE0);
      GLuint tid;
      glGenTextures(1, &tid);
      glBindTexture(GL_TEXTURE_2D, tid);
      glTexImage2D(GL_TEXTURE_2D, 0, _mode, _image.w, _image.h, 0, _mode, GL_UNSIGNED_BYTE, _image.pixels);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }

  private:
    void set_draw_mode() {
      if (_image.format.BytesPerPixel==4)
        _mode = GL_RGBA;
      else
        _mode = GL_RGB;
    }

    SDL_Surface* _image;
    int _mode;
}




