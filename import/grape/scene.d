module grape.scene;

import grape.layer;

immutable LAYER_MAX_NUM = 20;

class Scene {
  public:
    this() {
      _current = 0;
      // Basic, Fog, LensFlare 
    }

    void add(Layer layer) {
      _layers[_current] = layer;
    }

    void set_current_layer(int n) {
      assert(n >= 0 && n < LAYER_MAX_NUM);
      _current = n;
    }

  private:
    Layer[LAYER_MAX_NUM] _layers;
    int _current;
}

