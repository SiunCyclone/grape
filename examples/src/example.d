import grape;

void main() {
  Window window;
  Renderer2 renderer;
  Scene scene;
  Camera camera;

  int width = 640;
  int height = 480;
  bool loop = true;

  Geometry cuboidG;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window("example", width, height);
      renderer = new Renderer2;
      scene = new Scene;
      camera = new Camera(1, 100);
      camera.look_at(Vec3(0, 1, 3), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });
    };

    void delegate() initCuboid = {
      cuboidG = new BoxGeometry(0.5, 1, 0.5);
      cuboidG.set_position(Vec3(1, 0, 0));
      auto cuboidM = new ColorMaterial(
        "color", [ 255, 0, 255],
        "wireframe", true
      );
      auto cuboid = new Mesh(cuboidG, cuboidM);

      scene.add(cuboid);
    };

    initCore();
    initCuboid();
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 0, 1);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      cuboidG.rotate(axis, rad);
      cuboidG.yaw(rad);

      renderer.render(scene, camera);

      window.update();
    }
  };

  init();
  animate();
} 

