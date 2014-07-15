module grape.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import derelict.opengl3.gl3;

import std.stdio;
import std.string;
import std.exception : enforce;
import std.algorithm;
import std.array;
import std.conv;
import std.file;

import grape.buffer;
import grape.shader;
import grape.window;
import grape.surface;
import grape.renderer;

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

/**
 * Fontを管理するクラス
 *
 * FontRendererがあるのでFontをロードする機能くらいしか使いません。
 */
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

    /**
     * Fontの初期化
     *
     * 引数にTTFフォントのファイル名を渡すと読み込みます。
     */
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

    /**
     * Fontの読み込み
     *
     * file:   TTFフォントのファイル名
     */
    void load(in string file) {
      enforce(exists(file), file ~ " does not exist");
      foreach (size; FontSizeList)
        _units[size] = new FontUnit(file, size);
    }

    /**
     * 文字列テクスチャの作成
     *
     * 基本的にユーザーは使いません。
     * 受け取ったtextのテクスチャを作成します。
     * size:  文字の大きさ
     * text:  文字列
     * color: 文字列の色
     */
    void create_texture(in int size, in string text, in SDL_Color color) {
      _surf.create({ return TTF_RenderUTF8_Solid(_units[size].unit, toStringz(text), color); });
      _surf.convert(SurfaceFormat.abgr8888);
      //_surf.convert(SurfaceFormat.rgba8888);
      _texture.create(_surf);
    }

    @property {
      /**
       * 文字列テクスチャを返す
       *
       * 基本的にユーザーは使いません。
       */
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

/**
 * Fontを描画するクラス
 *
 * Fontの描画は全てこのクラスが行います。
 */
class FontRenderer : Old_Renderer {
  public:
    this() {
      string[] locNames = ["pos", "texCoord"];
      int[] strides = [ 3, 2 ]; 
      mixin FontShaderSource;
      init(FontShader, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
      set_uniform("tex", 0, "1i");

      debug(tor) writeln("FontHdr ctor");
    }

    this(Font font) {
      this();
      set_font(font);
    }

    /**
     * 描画するフォントのセット
     *
     * render関数を呼ぶ前に必ず呼ばれる必要があります。
     * font:  描画するフォント
     *
     * TODO:
     * コンストラクタでやるか
     */
    void set_font(Font font) {
      _font = font;
    }

    /**
     * 描画文字色の設定
     *
     * 0~255までの値を引数にとります。
     * r: 赤
     * g: 緑
     * b: 青
     *
     * TODO:
     * 引数の値範囲チェック
     */
    void set_color(in ubyte r, in ubyte g, in ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    override void render() {}

    /**
     * 描画関数
     *
     * x:      描画する左上のx座標
     * y:      描画する左上のy座標
     * text:   描画する文字列
     * size:   描画するフォントの大きさ
     *
     * TODO:
     * Rendererのrenderを使ってない
     */
    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void render(in float x, in float y, in string text, in int size) {
      enforce(!find(FontSizeList, size).array.empty, "Called wrong size of the font. These are available FontSizeList.\n" ~ FontSizeList.to!string);
      _program.use();

      _font.create_texture(size, text, _color);

      float[12] pos = set_pos(x, y);
      set_vbo(pos, _texCoord);
      _font.texture.texture_scope({
        glDepthFunc(GL_ALWAYS); // TODO
        _ibo.draw(_drawMode);
        glDepthFunc(GL_LESS);
      });
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
      auto startX = x / (WINDOW_WIDTH/2.0);
      auto startY = y / (WINDOW_HEIGHT/2.0);
      auto w = _font.texture.w / (WINDOW_WIDTH/2.0);
      auto h = _font.texture.h / (WINDOW_HEIGHT/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Font _font;
    SDL_Color _color;
    float[] _texCoord;
}

