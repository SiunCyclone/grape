module grape.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;

import std.stdio;

enum SurfaceFormat {
  unknown = SDL_PIXELFORMAT_UNKNOWN,
  index1lsb = SDL_PIXELFORMAT_INDEX1LSB,
  index1msb = SDL_PIXELFORMAT_INDEX1MSB,
  index4lsb = SDL_PIXELFORMAT_INDEX4LSB,
  index4msb = SDL_PIXELFORMAT_INDEX4MSB,
  index8 = SDL_PIXELFORMAT_INDEX8,
  rgb332 = SDL_PIXELFORMAT_RGB332,
  rgb444 = SDL_PIXELFORMAT_RGB444,
  rgb555 = SDL_PIXELFORMAT_RGB555,
  bgr555 = SDL_PIXELFORMAT_BGR555,
  argb444 = SDL_PIXELFORMAT_ARGB4444,
  rgba4444 = SDL_PIXELFORMAT_RGBA4444,
  abgr4444 = SDL_PIXELFORMAT_ABGR4444,
  bgra4444 = SDL_PIXELFORMAT_BGRA4444,
  argb1555 = SDL_PIXELFORMAT_ARGB1555,
  rgba5551 = SDL_PIXELFORMAT_RGBA5551,
  abgr1555 = SDL_PIXELFORMAT_ABGR1555,
  bgra5551 = SDL_PIXELFORMAT_BGRA5551,
  rgb565 = SDL_PIXELFORMAT_RGB565,
  bgr565 = SDL_PIXELFORMAT_BGR565,
  rgb24 = SDL_PIXELFORMAT_RGB24,
  bgr24 = SDL_PIXELFORMAT_BGR24,
  rgb888 = SDL_PIXELFORMAT_RGB888,
  rgbx8888 = SDL_PIXELFORMAT_RGBX8888,
  bgr888 = SDL_PIXELFORMAT_BGR888,
  bgrx8888 = SDL_PIXELFORMAT_BGRX8888,
  argb8888 = SDL_PIXELFORMAT_ARGB8888,
  rgba8888 = SDL_PIXELFORMAT_RGBA8888,
  abgr8888 = SDL_PIXELFORMAT_ABGR8888,
  bgra8888 = SDL_PIXELFORMAT_BGRA8888,
  argb2101010 = SDL_PIXELFORMAT_ARGB2101010,

  yy12 = SDL_PIXELFORMAT_YV12,
  iyuv = SDL_PIXELFORMAT_IYUV,
  yuy2 = SDL_PIXELFORMAT_YUY2,
  uyyy = SDL_PIXELFORMAT_UYVY,
  yyyu = SDL_PIXELFORMAT_YVYU
}

final class Surface {
  public:
    ~this() {
      debug(dtor) writeln("Surface dtor");
      // free();
    }

    void create(in SDL_Surface* delegate() dg) {
      free();
      _surf = dg();
      enforce(_surf !is null, "Surface.create() failed.");
    }

    void convert(in SurfaceFormat flag) {
      auto tmp = SDL_ConvertSurfaceFormat(_surf, flag, 0);
      free();
      _surf = tmp;
      enforce(_surf !is null, "SDL_ConvertSurfaceFormat() failed.");
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
    void free() {
      if (_surf !is null)
        SDL_FreeSurface(_surf);
    }

    SDL_Surface* _surf;
}

