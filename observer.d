module orange.observer;

import derelict.sdl2.sdl;

// window, joypad, surface
// Singleton
final class Observer {
  public:
    static ~this() {
      if (_initialized) SDL_Quit();
    }

    static void init() {
      _initialized = true;
      DerelictSDL2.load();

      if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
        throw new Exception("SDL_Init() failed");
    }

    void observe() {

    }

  private:
    static bool _initialized = false;
    //static _list;
}

