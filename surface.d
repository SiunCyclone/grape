module orange.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;

import std.stdio;
import orange.font;

// TODO
class SurfaceUnit {
  public: 
    this() {
    }

    ~this() {
      if (_surf !is null) SDL_FreeSurface(_surf);
    }

  private:
    SDL_Surface* _surf;
}

class Surface {
  public:
    ~this() {
      debug(tor) writeln("Surface dtor");
      //free(_surf);
    }

    void create_ttf(Font font, in int size, in string text, in SDL_Color color) {
      free(_surf);

      _surf = TTF_RenderUTF8_Solid(font.unit(size), cast(char*)text, color);
      //_surf = TTF_RenderUTF8_Solid(font[size], cast(char*)text, color);
      enforce(_surf !is null, "_surf is null");
    }

    void convert() {
      // TODO 一般化
      auto tmp = SDL_ConvertSurfaceFormat(_surf, SDL_PIXELFORMAT_ABGR8888, 0);
      free(_surf);
      _surf = tmp;
    }

    @property {
      int w() {
        return _surf.w;
      }  

      int h() {
        return _surf.h;
      }

      void* pixels() {
        return _surf.pixels;
      }

      int bytes_per_pixel() {
        return _surf.format.BytesPerPixel;
      }
    }

  private:
    void free(SDL_Surface* surf) {
      if (surf != null)
        SDL_FreeSurface(surf);
    }

    SDL_Surface* _surf;
}

