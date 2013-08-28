module orange.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;
import orange.buffer;
import opengl.glew;

import std.stdio;
import derelict.sdl2.image;
import orange.window;

class FontHandler {
  public:
    this(GLuint program) {
      _program = program;

      _vboHandler = new VboHandler(2, _program);
      _iboHandler = new IboHandler(1);
      _texHandler = new TexHandler(_program);

      _drawMode = DrawMode.Triangles;
    }

    ~this() {
      // opened?
      // TTF_CloseFont(font);
    }

    void load(string file, int size) {
      _font = TTF_OpenFont(cast(char*)file, size);
      enforce(_font != null, "FontHandler.load() failed");
    }

    // it's not rgb. i guess grb
    void set_color(ubyte r, ubyte g, ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    void draw(float x, float y, string text) {
      /*
      _surf = IMG_Load("./resource/alpha.png");
      if (_surf == null)
        throw new Exception("_surf null");
        */
      SDL_Surface* surfBase = TTF_RenderUTF8_Solid(_font, cast(char*)text, _color);
      enforce(surfBase != null, "FontHandler.surfBase is null");
      _surf = SDL_ConvertSurfaceFormat(surfBase, SDL_PIXELFORMAT_ABGR8888, 0);
      SDL_FreeSurface(surfBase);

      float[12] pos = set_pos(x, y);
      float[8] tex = [ 0.0, 0.0,
                       1.0, 0.0,
                       1.0, 1.0,
                       0.0, 1.0 ];        
      auto locNames = ["pos", "texCoord"];
      auto strides = [ 3, 2 ]; 

      _vboHandler.create_vbo(pos, tex);
      _vboHandler.enable_vbo(locNames, strides);
      _iboHandler.create_ibo([0,1,2,2,3,0]);

      // "tex"
      _texHandler.create_texture(_surf, "tex");
      _iboHandler.draw(_drawMode);
      _texHandler.delete_texture();
    }

  private:
    float[12] set_pos(float x, float y) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = _surf.w / (WINDOW_X/2.0);
      auto h = _surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    GLuint _program;
    TTF_Font* _font;
    SDL_Color _color;
    SDL_Surface* _surf;

    VboHandler _vboHandler;
    IboHandler _iboHandler;
    TexHandler _texHandler;
    DrawMode _drawMode;
}

