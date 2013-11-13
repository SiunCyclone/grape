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

    this(in string file) {
      this();
      load(file);
    }

    static ~this() {
      debug(tor) writeln("Image dtor");
      if (_initialized)
        IMG_Quit();
    }

    void load(in string file) {
      enforce(exists(file), file ~ "does not exist");
      _surf.create({ return IMG_Load(toStringz(file)); });
      enforce(_surf !is null, "IMG_Load() failed");
    }

    void create_texture() {
      _texture.create(_surf);
    }

    @property {
      Texture texture() {
        return _texture;
      }
    }

  private:
    Texture _texture;
    Surface _surf;
    static bool _initialized = false;
}

class ImageRenderer : Renderer {
  public:
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

    void set_image(Image image) {
      _image = image;
    }

    override void render() {}

    // TODO scale is not implemented yet
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
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = _image.texture.w / (WINDOW_X/2.0);
      auto h = _image.texture.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Image _image;
    float[] _texCoord;
}

