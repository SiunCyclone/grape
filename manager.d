module orange.manager;

import std.stdio;
import std.exception : enforce;

// TODO tmp
final class Manager {
  public:
    ~this() {
      debug(tor) writeln("Manager dtor");
    }

    void enable_sdl2() {
      SDL2.load();
    }

    void enable_sdl2image() {
      SDL2IMAGE.load();
    }

    void enable_opengl() {
      import derelict.opengl3.gl;

      DerelictGL.load();
      DerelictGL.reload(); // Create OpenGL context before you call reload()
    }

    void enable_opengl3() {
      import derelict.opengl3.gl3;

      DerelictGL3.load();
      DerelictGL3.reload(); // Create OpenGL context before you call reload()
    }

  private:
    final abstract class SDL2 {
      import derelict.sdl2.sdl;

      static ~this(){
        debug(tor) writeln("SDL2 dtor");
        if (isLoaded) SDL_Quit();
      }

      static void load() {
        debug(tor) writeln("SDL2 load");

        isLoaded = true;
        DerelictSDL2.load();

        if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
          throw new Exception("SDL_Init() failed");
      }

      static bool isLoaded = false;
    }

    final abstract class SDL2IMAGE {
      import derelict.sdl2.image;

      static ~this() {
        if (isLoaded) IMG_Quit();
      }

      static void load() {
        isLoaded = true;
        DerelictSDL2Image.load();

        // TODO get in args
        int flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
        if (IMG_Init(flags) == -1)
          throw new Exception("Image_Init() failed");
      }

      static bool isLoaded = false;
    }
}

