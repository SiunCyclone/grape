module orange.manager;

enum {
  LIBRARY_NUM = 4
}

class Library {}

class SDL2 : Library {
  import derelict.sdl2.sdl;

  this() {
    DerelictSDL2.load();

    if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
      throw new Exception("SDL_Init() failed");
  }

  ~this(){
    SDL_Quit();
  }
}

class SDL2TTF : Library {
  import derelict.sdl2.ttf;

  this() {
    DerelictSDL2ttf.load();

    if (TTF_Init() == -1)
      throw new Exception("TTF_Init() failed");
  }

  ~this() {
    TTF_Quit();
  }
}

class SDL2IMAGE : Library {
  import derelict.sdl2.image;

  this() {
    DerelictSDL2Image.load();

    // TODO get in args
    int flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
    if (IMG_Init(flags) == -1)
      throw new Exception("Image_Init() failed");
  }

  ~this() {
    IMG_Quit();
  }
}

class GLEW : Library {
  import opengl.glew;

  this() {
    // create OpenGL context before call this
    if (glewInit() != GLEW_OK)
      throw new Exception("glewInit() failed");
  }
}

class Manager {
  public:
    this() {
      _libraries.length = LIBRARY_NUM;
    }

    void enable_sdl2() {
      _libraries ~= new SDL2;
    }

    void enable_sdl2ttf() {
      _libraries ~= new SDL2TTF;
    }

    void enable_sdl2image() {
      _libraries ~= new SDL2IMAGE;
    }

    void enable_glew() {
      _libraries ~= new GLEW;
    }

  private:
    Library[] _libraries;
}

