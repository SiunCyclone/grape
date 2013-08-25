module orange.font;

import derelict.sdl2.ttf;
import std.exception : enforce;
import orange.buffer;

class FontHandler {
  public:
    this() {

    }

    ~this() {
      // opened?
      // TTF_CloseFont(font);
    }

    void load_font(string file, int size) {
      _font = TTF_OpenFont(cast(char*)file, size);
      enforce(_font == null, "open_font() failed");
    }

    void draw(string text) {

    }

  private:
    TTF_Font* _font;
    TexHandler _texHandler;
}

