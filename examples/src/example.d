import grape;

void main() {
  Window window;
  Renderer renderer;
  Scene scene;
  Camera camera;

  int width = 640;
  int height = 480;
  bool loop = true;

  Geometry cubeG;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window("example", width, height);
      renderer = new Renderer;
      scene = new Scene;
      camera = new Camera(0.1, 100);
      camera.look_at(Vec3(0, 0, 4), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });
    };

    void delegate() initCube = {
      cubeG = new BoxGeometry(1, 1, 1);
      auto cubeM = new ColorMaterial(
        "color", [ 255, 0, 0 ],
        "wireframe", true
      );
      auto cube = new Mesh(cubeG, cubeM);

      scene.add(cube);
    };

    initCore();
    initCube();
  };

  void delegate() animate = {
    Vec3 axisX = Vec3(1, 0, 0);
    float rad = -PI/270;

    while (loop) {
      Input.poll();

      cubeG.rotate(axisX, rad);
      cubeG.yaw(rad);

      renderer.render(scene, camera);

      window.update();
    }
  };

  init();
  animate();
} 

