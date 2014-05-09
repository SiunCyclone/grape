import grape;

void main() {
  Window window;
  Renderer2 renderer;
  Scene scene;
  Camera camera;
  bool loop = true;

  Geometry cubeG;
  Geometry cuboidG;

  void delegate() init = {
    int width = 640;
    int height = 480;
    window = new Window("example", width, height);
    renderer = new Renderer2;
    scene = new Scene;
    camera = new Camera(1, 100);
    camera.look_at(Vec3(0, 1, 3), Vec3(0, 0, 0), Vec3(0, 1, 0));

    cubeG = new CubeGeometry(1, 1, 1);
    auto cubeM = new ColorMaterial(
      "color", [ 100, 200, 250],
      "wireframe", true
    );
    auto cube = new Mesh(cubeG, cubeM);
    scene.add(cube);

    cuboidG = new CubeGeometry(0.5, 1, 0.5);
    cuboidG.set_position(Vec3(1, 0, 0));
    auto cubioidM = new ColorMaterial(
      "color", [ 100, 250, 50],
      "wireframe", true
    );
    auto cubioid = new Mesh(cuboidG, cubioidM);
    scene.add(cubioid);

    Input.key_down(KEY_Q, {
      loop = false;
    });
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 0, 1);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      cubeG.yaw(rad);
      cuboidG.rotate(axis, rad);
      cuboidG.yaw(rad);
      renderer.render(scene, camera);

      window.update();
    }
  };

  init();
  animate();
} 

