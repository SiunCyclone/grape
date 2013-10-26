module orange.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import derelict.opengl3.gl3;

import std.stdio;
import std.string;
import std.exception : enforce;
import std.algorithm;
import std.array;
import std.conv;

import orange.buffer;
import orange.shader;
import orange.window;
import orange.surface;
import orange.renderer;

static immutable auto FontSizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                       15, 16, 17, 18, 20, 22, 24, 26,
                                       28, 32, 36, 40, 48, 56, 64, 72 ];

/* Cannot compile but I'm not sure... 
static immutable int[25] FontSizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                          15, 16, 17, 18, 20, 22, 24, 26,
                                          28, 32, 36, 40, 48, 56, 64, 72 ];
*/

private final class FontUnit {
  public:
    this(in string file, in int size) {
      _font = TTF_OpenFont(toStringz(file), size); 
      enforce(_font !is null, "TTF_OpenFont() failed");
    }
     
    ~this() {
      debug(tor) writeln("FontUnit dtor");
      TTF_CloseFont(_font);
    }
     
    //alias _font this;
    @property {
      TTF_Font* unit() {
        return _font;
      } 
    }

  private:
    TTF_Font* _font;
}

final class Font {
  public: 
    this() {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2ttf.load();
        if (TTF_Init() == -1)
          throw new Exception("TTF_Init() failed");
      }

      _texture = new Texture;
      _surf = new Surface;
      _instance ~= this;
    }

    this(in string file) {
      this();
      load(file);
    }

    ~this() {
      debug(tor) writeln("Font dtor");
      foreach (font; _units) destroy(font);
    }

    static ~this() {
      debug(tor) writeln("Font static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);
        TTF_Quit();
      }
    }

    void load(in string file) {
      foreach (size; FontSizeList)
        _units[size] = new FontUnit(file, size);
    }

    void create_texture(in int size, in string text, in SDL_Color color) {
      _surf.create({ return TTF_RenderUTF8_Solid(_units[size].unit, toStringz(text), color); });
      _surf.convert(SurfaceFormat.abgr8888);
      _texture.create(_surf);
    }

    @property {
      Texture texture() {
        return _texture;
      }
    }

  private:
    FontUnit[int] _units;
    Texture _texture;
    Surface _surf;
    static Font[] _instance;
    static bool _initialized = false;
}

class FontRenderer : Renderer {
  public:
    this() {
      string[] locNames = ["pos", "texCoord"];
      int[] strides = [ 3, 2 ]; 
      mixin FontShaderSource;
      init(FontShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
      set_uniform("tex", 0, "1i");

      debug(tor) writeln("FontHdr ctor");
    }

    void set_font(Font font) {
      _font = font;
    }

    void set_color(in ubyte r, in ubyte g, in ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    override void render() {}

    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void render(in float x, in float y, in string text, in int size) {
      enforce(!find(FontSizeList, size).array.empty, "Called wrong size of the font. These are available FontSizeList.\n" ~ FontSizeList.to!string);
      _program.use();

      _font.create_texture(size, text, _color);

      float[12] pos = set_pos(x, y);
      set_vbo(pos, _texCoord);
      _font.texture.applied_scope({ _ibo.draw(_drawMode); });
    }

  private:
    void init_vbo() {
      _texCoord = [ 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0 ];        
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    float[12] set_pos(in float x, in float y) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = _font.texture.w / (WINDOW_X/2.0);
      auto h = _font.texture.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Font _font;
    SDL_Color _color;
    float[] _texCoord;
}


/*
private final class FontUnit {
  public:
    this(string file, int size) {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2ttf.load();
        if (TTF_Init() == -1)
          throw new Exception("TTF_Init() failed");
      }
       
      _font = TTF_OpenFont(toStringz(file), size); 
      enforce(_font !is null, "TTF_OpenFont() failed");

      _instance ~= this;
    }
     
    ~this() {
      debug(tor) writeln("FontUnit dtor");
      TTF_CloseFont(_font);
    }
     
    static ~this() {
      debug(tor) writeln("FontUnit static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);
        TTF_Quit();
      }
    }

    //alias _font this;
    @property {
      TTF_Font* unit() {
        return _font;
      } 
    }

  private:
    static bool _initialized;
    static FontUnit[] _instance;
    TTF_Font* _font;
}
 
class Font {
  public:
    this(){}

    this(string file) {
      load(file);
    }

    ~this() {
      debug(tor) writeln("Font dtor");
      foreach (font; _fonts) destroy(font);
    }

    void load(string file) {
      foreach (size; _sizeList)
        _fonts[size] = new FontUnit(file, size);
    }

    //alias _fonts this;
    TTF_Font* unit(int size) {
      return _fonts[size].unit; 
    }

  private:
    FontUnit[int] _fonts;
    static immutable auto _sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                        15, 16, 17, 18, 20, 22, 24, 26,
                                        28, 32, 36, 40, 48, 56, 64, 72 ];
}
*/

/*
class Font {
  public:
    this(string file) {
      if (!_isLoaded) {
        _isLoaded = true;
        DerelictSDL2ttf.load();
        if (TTF_Init() == -1)
          throw new Exception("TTF_Init() failed");
      }
       
      foreach (size; _sizeList) {
        _list[size] = TTF_OpenFont(cast(char*)file, size);
        enforce(_list[size] != null, "TTF_OpenFont() failed");
      }

      _instance ~= this;
    }
     
    ~this() {
      debug(tor) writeln("Font dtor");
      foreach (font; _list)
        TTF_CloseFont(font);
    }
     
    static ~this() {
      debug(tor) writeln("Font static dtor");
      if (_isLoaded) {
        foreach (v; _instance) destroy(v);
        TTF_Quit();
      }
    }
     
    static immutable auto _sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                        15, 16, 17, 18, 20, 22, 24, 26,
                                        28, 32, 36, 40, 48, 56, 64, 72 ];
    //alias _list this; // Cause segv
    @property {
      TTF_Font* list(int size) {
        return _list[size];
      }
    }

    TTF_Font*[int] _list;
     
  private:
    static bool _isLoaded = false;
    static Font[] _instance;
}
*/

/*
class FontRenderer {
  public:
    this(in GLuint program) { //TODO Don't get program
      _vboHdr = new VBOHdr(2, program);
      _texHdr = new TexHdr(program);
      _ibo = new IBO;
      _ibo.create([0, 1, 2, 2, 3, 0]);
      _surf = new Surface;

      _drawMode = DrawMode.Triangles;

      _tex = [ 0.0, 0.0,
               1.0, 0.0,
               1.0, 1.0,
               0.0, 1.0 ];        
      _locNames = ["pos", "texCoord"];
      _strides = [ 3, 2 ]; 

      //debug(tor) writeln("FontHdr ctor");
    }

    ~this() {
      debug(tor) writeln("FontRenderer dtor");
    }

    void set_font(Font font) {
      _font = font;
    }

    void set_color(in ubyte r, in ubyte g, in ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void draw(in float x, in float y, in string text, in int size) {
      enforce(!find(FontSizeList, size).array.empty, "Called wrong size of the font. These are available FontSizeList.\n" ~ FontSizeList.to!string);

      _surf.create_ttf(_font, size, text, _color);
      _surf.convert();

      float[12] pos = set_pos(x, y, _surf);
      _vboHdr.create_vbo(pos, _tex);
      _vboHdr.enable_vbo(_locNames, _strides);

      _texHdr.create(_surf, "tex");
      _texHdr.applied_scope({ _ibo.draw(_drawMode); });
    }

  private:
    float[12] set_pos(in float x, in float y, Surface surf) {
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
    //Font[int] _font;
    Font _font;
    SDL_Color _color;

    float[8] _tex;
    string[2] _locNames;
    int[2] _strides;

    VBOHdr _vboHdr;
    IBO _ibo;
    TexHdr _texHdr;
    DrawMode _drawMode;
}
*/

/*
class FontRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin FontShaderSource;
      init(FontShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
    }

    void load(string file, int[] sizeList...) {
      if (sizeList.length == 0) {
        sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14, // TODO immutableにする
                     15, 16, 17, 18, 20, 22, 24, 26,
                     28, 32, 36, 40, 48, 56, 64, 72 ];
      }

      foreach (size; sizeList)
        _font[size] = new Font(file, size);
    }

    override void render() {
      _program.use();
      _ibo.draw(_drawMode);
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

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

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;

    Surface _surf;
    Font[int] _font;
    SDL_Color _color;
}
*/
