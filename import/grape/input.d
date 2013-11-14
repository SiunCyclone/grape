module grape.input;

import std.stdio;
import grape.event;
import derelict.sdl2.sdl;

class Input {
  public:
    static void poll() {
      while (Event.is_happening) {
        switch (Event.type) {
          case KeyDown:
            _keyMap[Event.scancode]();
            break;
          /*
          case JoyAxisMotion: _joyAxisMap(Event.axis); break;
          case JoyButtonDown: _joyButtonMap(); break;
          case JoyHatMotion: _joyHatMap(); break;
          */
          default: break;
        }
      }
    }

    static void key_down(in int key, in void delegate() callback) {
      _keyMap[key] = callback;
    }

    static void axis_move(in int num, in void delegate() callback) {

    }

    static void button_down() {

    }

    static void hat_down() {

    }

  private:
    static void delegate()[int] _keyMap;
    static void delegate() _joyAxisMap;
    static void delegate() _joyButtonMap;
    static void delegate() _joyHatMap;
}

