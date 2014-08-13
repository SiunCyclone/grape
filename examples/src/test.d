import grape;

void main() {
  Window window;
  Renderer renderer;
  GlowFilter filter;
  Scene scene;
  Camera camera;

  int width = 640;
  int height = 480;
  bool loop = true;

  Geometry cubeG;
  Geometry cuboidG;
  Geometry sphereG;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window("test", width, height);
      renderer = new Renderer;
      renderer.enable_depth;
      renderer.enable_smooth;
      filter = new GlowFilter(width, height, 256, 256);
      //filter = new BlurFilter(width, height);
      scene = new Scene;
      camera = new Camera(1, 100);
      camera.look_at(Vec3(1, 1, 2), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });

    };

    void delegate() initCube = {
      cubeG = new BoxGeometry(1, 1, 1);
      auto cubeM = new ColorMaterial(
        "color", [ 250, 50, 150],
        "wireframe", true
      );
      auto cube= new Mesh(cubeG, cubeM);

      //scene.add(cube);
    };

    void delegate() initCubioid = {
      cuboidG = new BoxGeometry(0.5, 1, 0.5);
      cuboidG.set_position(Vec3(1.5, 0, 0));
      auto cubioidM = new DiffuseMaterial(
        "color", [ 200, 150, 250],
        "wireframe", true
      );
      auto cubioid = new Mesh(cuboidG, cubioidM);

      //scene.add(cubioid);
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
    initCube();
    initCubioid();
    initSphere();
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 0, 1);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      sphereG.yaw(rad/4);
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

