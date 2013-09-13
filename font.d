module orange.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;
import orange.buffer;
import orange.window;
import opengl.glew;
import orange.surface;

import std.stdio;

class FontHdr {
  public:
    this(GLuint program) {
      _vboHdr = new VboHdr(2, program);
      _texHdr = new TexHdr(program);
      _iboHdr = new IboHdr(1);
      _iboHdr.create_ibo([0, 1, 2, 2, 3, 0]);
      _surf = new Surface;

      _drawMode = DrawMode.Triangles;

      _tex = [ 0.0, 0.0,
               1.0, 0.0,
               1.0, 1.0,
               0.0, 1.0 ];        
      _locNames = ["pos", "texCoord"];
      _strides = [ 3, 2 ]; 
    }

    void load(string file, int[] sizeList...) {
      if (sizeList.length == 0) {
        sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                     15, 16, 17, 18, 20, 22, 24, 26,
                     28, 32, 36, 40, 48, 56, 64, 72 ];
      }

      foreach (size; sizeList)
        _font[size] = new Font(file, size);
    }

    void set_color(ubyte r, ubyte g, ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void draw(float x, float y, string text, int size) {
      enforce(size in _font, "font size error. you call wrong size of the font which is not loaded");

      _surf.create_ttf(_font[size], text, _color);
      _surf.convert();

      float[12] pos = set_pos(x, y, _surf);
      _vboHdr.create_vbo(pos, _tex);
      _vboHdr.enable_vbo(_locNames, _strides);

      _texHdr.create_texture(_surf, "tex");
      scope(exit) _texHdr.delete_texture();

      _iboHdr.draw(_drawMode);
    }

  private:
    float[12] set_pos(float x, float y, Surface surf) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = surf.w / (WINDOW_X/2.0);
      auto h = surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Surface _surf;
    Font[int] _font;
    SDL_Color _color;
    Surface _surf;

    float[8] _tex;
    string[2] _locNames;
    int[2] _strides;

    VboHdr _vboHdr;
    IboHdr _iboHdr;
    TexHdr _texHdr;
    DrawMode _drawMode;
}

class Font {
  public:
    this(string file, int size) {
      _font = TTF_OpenFont(cast(char*)file, size);
      enforce(_font != null, "_font is null");
    }

    ~this() {
      TTF_CloseFont(_font);
    }

    alias _font this;
    TTF_Font* _font; // TODO privateにできないのか
}

