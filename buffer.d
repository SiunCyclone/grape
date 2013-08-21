module orange.buffer;

import opengl.glew;
import orange.shader;

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
        glBufferData(GL_ARRAY_BUFFER, data.sizeof*data.length, data.ptr, GL_STATIC_DRAW);
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
    /*
    void bind(GLuint ibo, int[] index) {
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, index.sizeof*index.length, index.ptr, GL_STATIC_DRAW);
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
      // glDeleteBuffers(1, &ibo); // whre should i write...
    }
    */

  private:
}
