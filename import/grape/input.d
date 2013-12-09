module grape.input;

import derelict.sdl2.sdl;
import std.stdio;
import grape.event;
public import grape.keyboard;

/**
 * ユーザーの入力を管理するクラス
 *
 * キーボード、ジョイパッド、マウス等のイベントは全てこのクラスが管理します。
 */
class Input {
  public:
    /**
     * 入力をpollし、実行
     *
     * 毎フレーム呼ぶことが推奨されます。
     */
    static void poll() {
      while (Event.is_happening) {
        switch (Event.type) {
          case KeyDown:
            if (Event.scancode in keyMap) {
              keyMap[Event.scancode]();
            }
            break;
          case JoyAxisMotion:
            writeln("motion");
            if (Event.axis in joyAxisMap) {
              joyAxisMap[Event.axis]();
            }
            break;
          case JoyButtonDown:
            writeln("down");
            if (Event.button in joyButtonMap) {
              joyButtonMap[Event.button]();
            }
            break;
          case JoyHatMotion:
            // joyHatMap();
            break;
          default: break;
        }
      }
    }

    static void key_down(in int key, in void delegate() callback) {
      keyMap[key] = callback;
    }

    static void axis_move(in int num, in void delegate() callback) {
      joyAxisMap[num] = callback;
    }

    static void button_down(in int num, in void delegate() callback) {
      joyButtonMap[num] = callback;
    }

    static void hat_down() {

    }

  private:
    static void delegate()[int] keyMap;
    static void delegate()[int] joyAxisMap;
    static void delegate()[int] joyButtonMap;
    static void delegate() joyHatMap;
}

