module orange.event;

import derelict.sdl2.sdl;

class Event {
  public:
    @property {
      bool is_happening() {
        if (SDL_PollEvent(&_event))
          return true;
        return false;
      }

      Uint32 type() {
        return _event.type;
      }

      mixin KeyEvent;
      mixin JoyEvent;
    }

  private:
    SDL_Event _event;
}

mixin template KeyEvent() {
  SDL_Keysym keysym() {
    return _event.key.keysym;
  }

  SDL_Scancode scancode() {
    return keysym.scancode;
  }

  SDL_Keycode keycode() {
    return keysym.sym;
  }
}

mixin template JoyEvent() {
  Uint8 button() {
    return _event.jbutton.button;
  }
}
