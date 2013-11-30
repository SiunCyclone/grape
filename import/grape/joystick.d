module grape.joystick;

import derelict.sdl2.sdl;
import std.exception : enforce;
import std.stdio;

enum {
  MAX_AXIS_STATE = 32767.0
}

private final class JoystickUnit {
  public:
    this(in int deviceIndex) {
      _joystick = SDL_JoystickOpen(deviceIndex);
      enforce(_joystick != null, "SDL_JoystickOpen() failed");
    }

    ~this() {
      debug(tor) writeln("JoystickUnit dtor");
      if (SDL_JoystickGetAttached(_joystick))
        SDL_JoystickClose(_joystick);
    }

    float getAxis(in int axis) {
      return SDL_JoystickGetAxis(_joystick, axis) / MAX_AXIS_STATE;
    }

    int getButton(in int button) {
      return SDL_JoystickGetButton(_joystick, button);
    }

    /*
    int getBall(int ball) {
      return SDL_JoystickGetBall(_joystick, ball);
    }
    */

    int getHat(in int hat) {
      return SDL_JoystickGetHat(_joystick, hat);
    }

    int numAxes() {
      return SDL_JoystickNumAxes(_joystick);
    }

    int numButtons() {
      return SDL_JoystickNumButtons(_joystick);
    }

    int numBalls() {
      return SDL_JoystickNumHats(_joystick);
    }

    int numHats() {
      return SDL_JoystickNumBalls(_joystick);
    }

  private:
    SDL_Joystick* _joystick;
}

/**
 * ジョイパッドを管理するクラス
 */
class Joystick {
  public:
    /**
     * ジョイパッドの読み込み
     *
     * deviceIndex: 読み込むジョイパッドの番号
     */
    this(in int deviceIndex) {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2.load();

        if (SDL_InitSubSystem(SDL_INIT_JOYSTICK) != 0)
          throw new Exception("SDL_InitSubSystem(SDL_INIT_JOYSTICK) failed");
      }

      _joystick = new JoystickUnit(deviceIndex);
      set_num();
      _instance ~= this;
    }

    ~this() {
      debug(tor) writeln("Joystick dtor");
      destroy(_joystick);
    }

    static ~this() {
      debug(tor) writeln("Joystick static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);      
        SDL_QuitSubSystem(SDL_INIT_JOYSTICK);
      }
    }

    /**
     *
     */
    float getAxis(in int axis) 
      in {
        assert(0 <= axis && axis <= _numAxes);
      }
        
      body {
        return _joystick.getAxis(axis);
      }

    /**
     *
     */
    int getButton(in int button) 
      in {
        assert(0 <= button && button <= _numButtons);
      }

      body {
        return _joystick.getButton(button);
      }

      /*
    int getBall(int ball)
      in {
        assert(0 <= ball && ball <= _numBalls);
      }

      body {
        return _joystick.getBall(ball);
      }
      */

    /**
     *
     */
    int getHat(in int hat)
      in {
        assert(0 <= hat && hat <= _numHats);
      }

      body {
        return _joystick.getHat(hat);
      }

    // rename show_info("num")etc...
    /**
     * 情報の表示
     *
     * 軸の数、ボタンの数、ボールの数、ハットの数を表示します。
     */
    void show_info() {
      writef("axes:%d buttons:%d balls:%d hats:%d \n", _numAxes, _numButtons, _numBalls, _numHats);
      // writefln
    }

    @property {
      /**
       * Returns: 軸の総数
       */
      int numAxes() {
        return _numAxes;
      }

      /**
       * Returns: ボタンの総数
       */
      int numButtons() {
        return _numButtons;
      }

      /**
       * Returns: ボールの総数
       */
      int numBalls() {
        return _numBalls;
      }

      /**
       * Returns: ハットの総数
       */
      int numHats() {
        return _numHats;
      }
    }

  private:
    void set_num() {
      _numAxes = _joystick.numAxes();
      _numButtons = _joystick.numButtons();
      _numBalls = _joystick.numHats();
      _numHats= _joystick.numBalls();
    }

    JoystickUnit _joystick;
    static Joystick[] _instance;
    int _numAxes, _numButtons, _numBalls, _numHats;
    static bool _initialized = false;
}

