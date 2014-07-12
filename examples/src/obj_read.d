import grape;

void main() {
  Window window;
  Renderer2 renderer;
  Scene scene;
  Camera camera;

  int width = 640;
  int height = 480;
  bool loop = true;

  Geometry sphereG;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window("obj_read", width, height);
      renderer = new Renderer2;
      renderer.enable_smooth;
      renderer.enable_depth;
      scene = new Scene;
      camera = new Camera(1, 100);
      camera.look_at(Vec3(0, 1, 2), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });
    };

    void delegate() initSphere = {
      auto f = new FileHdr;
      auto vertices = f.make_vertices("../resource/sphere.obj");
      auto indices = f.make_indices("../resource/sphere.obj");
      auto normals = f.make_normals("../resource/sphere.obj");

      sphereG = new CustomGeometry(vertices, indices, vertices);
      auto sphereM = new ADSMaterial(
        "color", [ 200, 150, 250],
        "ambientColor", [ 0, 50, 150 ],
        "wireframe", true
      );
      auto sphere = new Mesh(sphereG, sphereM);

      scene.add(sphere);
    };

    initCore();
    initSphere();
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 0, 1);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      sphereG.yaw(rad/4);

      renderer.render(scene, camera);

      window.update();
    }
  };

  init();
  animate();
} 

