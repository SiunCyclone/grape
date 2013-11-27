module grape.filter;

import derelict.opengl3.gl3;
import grape.buffer;
import grape.renderer;
import grape.window;

/**
 * ポストエフェクト用クラス
 *
 * デフォルトセットのFilterじゃ物足りない、自作のポストエフェクトを使いたい
 * 等といった時はFilterを継承して新たなFilterのSubClassを作成してください。
 */
abstract class Filter {
  public:
    /**
     * Filterの初期化
     *
     * num:    Filterで使うtextureの数
     * w:      textureの幅
     * h:      textureの高さ
     */
    this(in size_t num, in int w, in int h) {
      _w = w;
      _h = h;
      _fbo = new FBO;
      _renderer = new FilterRenderer;

      _textures.length = num;
      for (int i; i<num; ++i) {
        _textures[i] = new Texture;
        _textures[i].create(_w, _h, null, GL_RGBA);
      }
    }

    /*
    final void set_camera(in float[] mat) {
      _renderer.set_uniform("pvmMatrix", mat, "mat4fv");
    }

    // Enables user to respecify a filtered area. Note that the area is the whole screen by default.
    final void set_area(in float x, in float y, in float w, in float h) {
    }
    */

    /**
     * ポストエフェクトの処理
     *
     * 実際にポストエフェクトをかける関数です。
     * 引数部分で下記のように描画処理をすれば、ポストエフェクトをかけたテクスチャが作成され、
     * Filter.render();で描画できます。
     * 
     * Examples:
     * ---------------
     * Filter.filter({
     *   Renderer.render();
     * });
     * ---------------
     */
    abstract void filter(in void delegate());

    /**
     * ポストエフェクトがかかったテクスチャの描画
     *
     * 単純にテクスチャを描画するだけです。
     *
     * TODO:
     * FilterRenderer所持してるけどどうするか
     */
    final void render() {
      render(_textures.length-1);
    }

    /**
     * Filterが内部に所持しているテクスチャの描画
     *
     * 基本的にユーザーが呼ぶことはありません。
     * 引数に受け取った番号のテクスチャを描画します。
     * BlurFilterならば、
     * 0:  renderした画面を格納したtexture
     * 1:  0を横Blurしたtexture
     * 2:  1を縦Blurしたtexture
     */
    final void render(in size_t i) {
      assert(i < _textures.length);

      glDisable(GL_DEPTH_TEST);
      filter_scope(i, { _renderer.render(); }); // TODO Specify a drawing area });
      glEnable(GL_DEPTH_TEST);
    }

    /**
     * ポストエフェクトがかかったテクスチャを適応したスコープ
     *
     */
    final void filter_scope(in size_t i, in void delegate() dg) {
      glEnable(GL_BLEND);
      glBlendFunc(GL_ONE, GL_ONE);
      _textures[i].texture_scope(dg);
      glDisable(GL_BLEND);
    }

  protected:
    final void create_filter(in int i, in void delegate() dg) {
      attach(i);
      fbo_scope(dg);
    }

  private:
    void attach(in int i) {
      _fbo.create(_textures[i]);

      // TODO RBO
      _fbo.binded_scope({
        GLenum[] drawBufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, drawBufs.ptr);
      });
    }

    void fbo_scope(in void delegate() dg) {
      _fbo.binded_scope({
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ZERO); // default blend
        glViewport(0, 0, _w, _h);
        dg();
        glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
        glDisable(GL_BLEND);
      });
    }

    FBO _fbo;
    int _w, _h;
    FilterRenderer _renderer;
    Texture[] _textures;
}

class BlurFilter : Filter {
  public:
    this(in int w, in int h) {
      super(3, w, h);
      _renderer = new GaussianRenderer([w, h]);
    }

    override void filter(in void delegate() dg) {
      create_filter(0, dg);
      create_filter(1, {
        filter_scope(0, {
          _renderer.set_type(0);
          _renderer.render();
        });
      });
      create_filter(2, {
        filter_scope(1, {
          _renderer.set_type(1);
          _renderer.render();
        });
      });
    }

  private:
    GaussianRenderer _renderer;
}

class GlowFilter : Filter {
  public:
    this(in int w, in int h) {
      this(w, h, w, h);
    }

    this(in int w, in int h, in int w2, in int h2) {
      super(2, w, h);
      _blurFilter = new BlurFilter(w2, h2);
    }

    override void filter(in void delegate() dg) {
      create_filter(0, dg);
      _blurFilter.filter(dg);

      create_filter(1, { 
        glBlendFunc(GL_ONE, GL_ONE);
        render(0);
        _blurFilter.render();
      });
    }

  private:
    BlurFilter _blurFilter;
}

