module grape.input;

import std.stdio;
import derelict.sdl2.sdl;
import grape.event;
public import grape.keyboard;

class Input {
  public:
    static void poll() {
      while (Event.is_happening) {
        switch (Event.type) {
          case KeyDown:
            if (Event.scancode in _keyMap) {
              _keyMap[Event.scancode]();
            }
            break;
          case JoyAxisMotion:
            writeln("motion");
            if (Event.axis in _joyAxisMap) {
              _joyAxisMap[Event.axis]();
            }
            break;
          case JoyButtonDown:
            writeln("down");
            if (Event.button in _joyButtonMap) {
              _joyButtonMap[Event.button]();
            }
            break;
          case JoyHatMotion:
            // _joyHatMap();
            break;
          default: break;
        }
      }
    }

    static void key_down(in int key, in void delegate() callback) {
      _keyMap[key] = callback;
    }

    static void axis_move(in int num, in void delegate() callback) {
      _joyAxisMap[num] = callback;
    }

    static void button_down(in int num, in void delegate() callback) {
      _joyButtonMap[num] = callback;
    }

    static void hat_down() {

    }

  private:
    static void delegate()[int] _keyMap;
    static void delegate()[int] _joyAxisMap;
    static void delegate()[int] _joyButtonMap;
    static void delegate() _joyHatMap;
}

