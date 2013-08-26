module orange.event;

import derelict.sdl2.sdl;

enum {
  /*
  SDL_FIRSTEVENT,
  SDL_QUIT,
  SDL_WINDOWEVENT,
  SDL_SYSWMEVENT,
  */
  KeyDown = SDL_KEYDOWN,
  KeyUp = SDL_KEYUP,
  /*
  SDL_TEXTEDITING,
  SDL_TEXTINPUT,
  */
  MouseMotion = SDL_MOUSEMOTION,
  MouseButtonDown = SDL_MOUSEBUTTONDOWN,
  MouseButtonUp = SDL_MOUSEBUTTONUP,
  MouseWheel = SDL_MOUSEWHEEL,
  JoyAxisMotion = SDL_JOYAXISMOTION,
  JoyBallMotion = SDL_JOYBALLMOTION,
  JoyHatMotion = SDL_JOYHATMOTION,
  JoyButtonDown = SDL_JOYBUTTONDOWN,
  JoyButtonUp = SDL_JOYBUTTONUP,
  JoyDeviceAdded = SDL_JOYDEVICEADDED,
  JoyDeviceRemoved = SDL_JOYDEVICEREMOVED,
  /*
  SDL_CONTROLLERAXISMOTION,
  SDL_CONTROLLERBUTTONDOWN,
  SDL_CONTROLLERBUTTONUP,
  SDL_CONTROLLERDEVICEADDED,
  SDL_CONTROLLERDEVICEREMOVED,
  SDL_CONTROLLERDEVICEREMAPPED,
  SDL_FINGERDOWN,
  SDL_FINGERUP,
  SDL_FINGERMOTION,
  SDL_DOLLARGESTURE,
  SDL_DOLLARRECORD,
  SDL_MULTIGESTURE,
  SDL_CLIPBOARDUPDATE,
  SDL_DROPFILE,
  SDL_USEREVENT,
  SDL_LASTEVENT
  */
}

class Event {
  public:
    @property {
      bool is_happening() {
        return SDL_PollEvent(&_event) ? true : false;
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

  Uint8 hat() {
    return _event.jhat.hat;
  }

  Uint8 axis() {
    return _event.jaxis.axis;
  }
}
