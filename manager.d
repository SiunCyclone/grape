module orange.manager;

import std.stdio;
import std.exception : enforce;

private final class SDL2 {
  import derelict.sdl2.sdl;

  ~this(){
    debug(tor) writeln("SDL2 dtor");
    if (isLoaded) SDL_Quit();
  }

  static void load() {
    debug(tor) writeln("SDL2 load");

    enforce(isLoaded != true, "SDL2 has loaded 2 times");
    isLoaded = true;

    DerelictSDL2.load();

    if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
      throw new Exception("SDL_Init() failed");
  }

  static bool isLoaded = false;
}

private final class SDL2TTF {
  import derelict.sdl2.ttf;

  ~this() {
    debug(tor) writeln("SDL2TTF dtor");
    if (isLoaded) TTF_Quit();
  }

  static void load() {
    debug(tor) writeln("SDL2TTF load");

    enforce(isLoaded != true, "SDL2TTF has loaded 2 times");
    isLoaded = true;

    DerelictSDL2ttf.load();

    if (TTF_Init() == -1)
      throw new Exception("TTF_Init() failed");
  }

  static bool isLoaded = false;
}

private final class SDL2IMAGE {
  import derelict.sdl2.image;

  ~this() {
    if (isLoaded) IMG_Quit();
  }

  static void load() {
    enforce(isLoaded != true, "SDL2IMAGE has loaded 2 times");
    isLoaded = true;

    DerelictSDL2Image.load();

    // TODO get in args
    int flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
    if (IMG_Init(flags) == -1)
      throw new Exception("Image_Init() failed");
  }

  static bool isLoaded = false;
}

private final abstract class GLEW {
  import opengl.glew;

  static void load() {
    enforce(isLoaded != true, "GLEW has loaded 2 times");
    isLoaded = true;
    // Create OpenGL context before call this.load()
    if (glewInit() != GLEW_OK)
      throw new Exception("glewInit() failed");
  }

  static bool isLoaded = false;
}

// TODO tmp
final class Manager {
  public:
    ~this() {
      debug(tor) writeln("Manager dtor");
    }

    void enable_sdl2() {
      tmp = new SDL2;
      tmp.load();
      //SDL2.load();
    }

    void enable_sdl2ttf() {
      tmp2 = new SDL2TTF;
      tmp2.load();
      //SDL2TTF.load();
    }

    void enable_sdl2image() {
      tmp3 = new SDL2IMAGE;
      tmp3.load();
      //SDL2IMAGE.load();
    }

    void enable_glew() {
      GLEW.load();
    }
  private:
    SDL2 tmp;
    SDL2TTF tmp2;
    SDL2IMAGE tmp3;
}

