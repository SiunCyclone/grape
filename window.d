module orange.window;

import std.exception : enforce;
import derelict.sdl2.sdl;
//import opengl.glew;
import derelict.opengl3.gl3;

import std.stdio;

shared int WINDOW_X;
shared int WINDOW_Y;

class Window {
  public:
    this(string name, int x, int y, int w, int h) {
      create(name, x, y, w, h);
      WINDOW_X = w;
      WINDOW_Y = h;
    }

    static ~this() {
      debug(tor) writeln("Windows dtor");
      SDL_GL_DeleteContext(_context); 
      SDL_DestroyWindow(_window);
    }
    
    void update() {
      SDL_GL_SwapWindow(_window);
      // other
      glClear(GL_COLOR_BUFFER_BIT);
      glClear(GL_DEPTH_BUFFER_BIT);
    }

    void should_close() {
      _flag = false;
    }

    @property {
      const bool is_open() {
        return _flag;
      }
    }

    alias _window this;
    static SDL_Window* _window;

  private:
    void create(string name, int x, int y, int w, int h) {
      _flag = true;
      // check last args
      _window = SDL_CreateWindow(cast(char*)name, x, y, w, h, SDL_WINDOW_OPENGL);
      _context = SDL_GL_CreateContext(_window);
      enforce(_window, "create_window() faild");
    }

    bool _flag;
    static SDL_GLContext _context;
}
