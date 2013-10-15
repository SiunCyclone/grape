module orange.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;

import std.stdio;
import orange.font;

class Surface {
  public:
    ~this() {
      debug(tor) writeln("Surface dtor");
      //free(_surf);
    }

    void create_ttf(Font font, int size, string text, SDL_Color color) {
      free(_surf);

      _surf = TTF_RenderUTF8_Solid(font[size], cast(char*)text, color);
      enforce(_surf != null, "_surf is null");
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

