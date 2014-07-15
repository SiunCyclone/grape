import grape;

void main() {
  Window window;
  Renderer2 renderer;
  GlowFilter filter;
  Scene scene;
  Camera camera;

  int width = 640;
  int height = 480;
  bool loop = true;

  Geometry cubeG;
  Geometry cuboidG;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window("glow", width, height);
      renderer = new Renderer2;
      renderer.enable_smooth("line", "polygon");
      filter = new GlowFilter(width, height, 100, 100);
      scene = new Scene;
      camera = new Camera(1, 100);
      camera.look_at(Vec3(0, 1, 3), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });
    };

    void delegate() initCube = {
      cubeG = new BoxGeometry(1, 1, 1);
      auto cubeM = new ColorMaterial(
        "color", [ 100, 200, 250],
        "wireframe", true
      );
      auto cube = new Mesh(cubeG, cubeM);

      scene.add(cube);
    };

    void delegate() initCuboid = {
      cuboidG = new BoxGeometry(0.5, 1, 0.5);
      cuboidG.set_position(Vec3(1, 0, 0));
      auto cuboidM = new ColorMaterial(
        "color", [ 250, 200, 50],
        "wireframe", true
      );
      auto cuboid = new Mesh(cuboidG, cuboidM);

      scene.add(cuboid);
    };

    initCore();
    initCube();
    initCuboid();
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 0, 1);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      cubeG.yaw(rad);
      cuboidG.rotate(axis, rad);
      cuboidG.yaw(rad);

      filter.filter({
        renderer.render(scene, camera);
      });

      window.update();
    }
  };

  init();
  animate();
} 

