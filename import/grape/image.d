module grape.image;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.stdio;
import std.string;
import std.file;
import std.exception : enforce;

import grape.buffer;
import grape.surface;
import grape.renderer;
import grape.shader;
import grape.window;

/**
 * 画像を管理するクラス
 */
class Image {
  public:
    this() {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2Image.load();
        int flags = IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF;
        if (IMG_Init(flags) == -1)
          throw new Exception("IMG_Init() failed");
      }

      _texture = new Texture;
      _surf = new Surface;
    }

    /** Imageの初期化
     *
     * 引数に画像のファイル名を渡すと読み込みます。
     * file: 画像のファイル名
     */
    this(in string file) {
      this();
      load(file);
    }

    static ~this() {
      debug(tor) writeln("Image dtor");
      if (_initialized)
        IMG_Quit();
    }

    /**
     * 画像の読み込み
     *
     * file:   画像のファイル名
     */
    void load(in string file) {
      enforce(exists(file), file ~ " does not exist");
      _surf.create({ return IMG_Load(toStringz(file)); });
      enforce(_surf !is null, "IMG_Load() failed");
    }

    /**
     * 画像テクスチャの作成
     *
     * 基本的にユーザーは使いません。
     */
    void create_texture() {
      _texture.create(_surf);
    }

    @property {
      /**
       * 画像テクスチャを返す
       *
       * 基本的にユーザーは使いません。
       */
      Texture texture() {
        return _texture;
      }
    }

  private:
    Texture _texture;
    Surface _surf;
    static bool _initialized = false;
}

// Cameraの影響をうけない
/**
 * 画像を描画するクラス
 *
 * TODO:
 * Camera使うか
 */
class ImageRenderer : Old_Renderer {
  public:
    /**
     * 初期化
     *
     * 引数に描画する画像を渡します。
     * 渡さなかった場合、描画する前に必ずset_image関数を呼ぶ必要があります。
     * image: 描画する画像
     */
    this(Image image) {
      this();
      set_image(image);
    }

    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];

      // TODO Weird name
      mixin FontShaderSource;
      init(FontShader, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
      set_uniform("tex", 0, "1i");
    }

    /**
     * 描画する画像のセット
     *
     * image: 描画する画像
     */
    void set_image(Image image) {
      _image = image;
    }

    override void render() {}

    /**
     * 描画
     *
     * x:      描画する左上のx座標
     * y:      描画する左上のy座標
     * scale:  倍率(未実装なので基本1.0を指定)
     *
     * TODO:
     * Rendererのrenderを使用してない
     * scale is not implemented yet
     */
    void render(in float x, in float y, in float scale) {
      _program.use();

      _image.create_texture();

      float[12] pos = set_pos(x, y);
      set_vbo(pos, _texCoord);
      _image.texture.texture_scope({ _ibo.draw(_drawMode); });
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
      auto w = _image.texture.w / (WINDOW_WIDTH/2.0);
      auto h = _image.texture.h / (WINDOW_HEIGHT/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Image _image;
    float[] _texCoord;
}

