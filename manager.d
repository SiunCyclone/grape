module orange.manager;

import derelict.sdl2.sdl;

class Manager {
  public:
    this() {
      enable_sdl2();
    }

    ~this() {
      SDL_Quit();
    }

    void enable_sdl2() {
      DerelictSDL2.load();

      if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
        throw new Exception("SDL_Init() failed");
    }
    
    void enable_glew() {
      import opengl.glew;

      // create OpenGL context before call this
      if (glewInit() != GLEW_OK)
        throw new Exception("glewInit() failed");
    }

    void enable_sdl2ttf() {
      // you must quit....
      import derelict.sdl2.ttf;
      DerelictSDL2ttf.load();

      if (TTF_Init() == -1)
        throw new Exception("TTF_Init() failed");
    }

    void enable_sdl2image() {
      // you must quit
      import derelict.sdl2.image;
      DerelictSDL2Image.load();

      // get in args
      int flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
      if (IMG_Init(flags) == -1)
        throw new Exception("Image_Init() failed");
    }
  private:
}

