module orange.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;

import std.stdio;

class Surface {
  public:
    ~this() {
      SDL_FreeSurface(_surf);
    }

    void create_ttf(TTF_Font* font, string text, SDL_Color color) {
      _surf = TTF_RenderUTF8_Solid(font, cast(char*)text, color);
      enforce(_surf != null, "_surf is null");
    }

    void convert() {
      // TODO 一般化
      _surf = SDL_ConvertSurfaceFormat(_surf, SDL_PIXELFORMAT_ABGR8888, 0);
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
    SDL_Surface* _surf;
}

