module orange.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;

import std.stdio;
import orange.font;

// TODO メモリ食ってる
class Surface {
  public:
    ~this() {
      // 最後まで呼ばれてない
      writeln("Surface destructor");
      SDL_FreeSurface(_surf);
    }

    void create_ttf(Font font, string text, SDL_Color color) {
      if (_surf != null) {
        SDL_FreeSurface(_surf);
      }

      _surf = TTF_RenderUTF8_Solid(font, cast(char*)text, color);
      enforce(_surf != null, "_surf is null");
    }

    void convert() {
      // TODO 一般化
      auto tmp = SDL_ConvertSurfaceFormat(_surf, SDL_PIXELFORMAT_ABGR8888, 0);
      SDL_FreeSurface(_surf);
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
    SDL_Surface* _surf;
}

