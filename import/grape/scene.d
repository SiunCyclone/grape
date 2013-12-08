module grape.scene;

import grape.layer;

class Scene {
  public:
    this() {
      // Basic, Fog, LensFlare 
    }

    void add(Layer layer) {
      _layers ~= layer;
    }

    void remove(in int index) {
      _layers = _layers[0..index] ~ _layers[index..$];
    }

    void visible(in int index, in bool flag) {
      _layers[index].visible(flag);
    }

  private:
    Layer[] _layers;
}

