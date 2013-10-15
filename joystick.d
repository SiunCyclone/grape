module orange.joystick;

import derelict.sdl2.sdl;
import std.exception : enforce;
import std.stdio;

enum {
  MAX_AXIS_STATE = 32767.0
}

enum {
  PLAYER_1 = 0,
  PLAYER_2 = 1,  
  PLAYER_3 = 2,  
  PLAYER_4 = 3  
}

class Joystick {
  public:
    this(in int num) {
      _joystick = SDL_JoystickOpen(num);
      enforce(_joystick != null, "SDL_JoystickOpen() failed");

      set_num();
    }

    ~this() {
      if (SDL_JoystickGetAttached(_joystick))
        SDL_JoystickClose(_joystick);
    }

    float getAxis(in int axis) 
      in {
        assert(0 <= axis && axis <= _numAxes);
      }
        
      body {
        return SDL_JoystickGetAxis(_joystick, axis) / MAX_AXIS_STATE;
      }

    int getButton(in int button) 
      in {
        assert(0 <= button && button <= _numButtons);
      }

      body {
        return SDL_JoystickGetButton(_joystick, button);
      }

    // int getBall()

    int getHat(in int hat)
      in {
        assert(0 <= hat && hat <= _numHats);
      }

      body {
        return SDL_JoystickGetHat(_joystick, hat);
      }

    // rename show_info("num")etc...
    void show_info() {
      writef("axes:%d buttons:%d balls:%d hats:%d \n", _numAxes, _numButtons, _numBalls, _numHats);
      // writefln
    }

    @property {
      int numAxes() {
        return _numAxes;
      }

      int numButtons() {
        return _numButtons;
      }

      int numBalls() {
        return _numBalls;
      }

      int numHats() {
        return _numHats;
      }
    }
  private:
    void set_num() {
      _numAxes = SDL_JoystickNumAxes(_joystick);
      _numButtons = SDL_JoystickNumButtons(_joystick);
      _numBalls = SDL_JoystickNumBalls(_joystick);
      _numHats= SDL_JoystickNumHats(_joystick);
    }

    SDL_Joystick* _joystick;
    int _numAxes, _numButtons, _numBalls, _numHats;
}
