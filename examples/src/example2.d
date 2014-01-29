import grape.window;
import grape.camera;
import grape.renderer;
import grape.input;
import grape.scene;
import grape.geometry;
import grape.material;
import grape.mesh;
import grape.math;

void main() {
  Window window;
  Renderer2 renderer;
  Scene scene;
  Camera camera;
  bool loop = true;

  void delegate() init = {
    int width = 640;
    int height = 480;
    window = new Window("example2", width, height);
    renderer = new Renderer2;
    scene = new Scene;
    camera = new Camera(1, 100);
    camera.look_at(Vec3(0, 0, 3), Vec3(0, 0, 0), Vec3(0, 1, 0));

    auto geometry = new CubeGeometry(1, 1, 1);
    auto material = new ColorMaterial(
      "color", [ 100, 100, 150],
      "wireframe", true
    );
    auto mesh = new Mesh(geometry, material);
    scene.add(mesh);

    Input.key_down(KEY_Q, {
      loop = false;
    });
  };

  void delegate() animate = {
    Vec3 axis = Vec3(0, 1, 0);
    float rad = PI_2 / 180.0;

    while (loop) {
      Input.poll();

      camera.rotate(axis, rad);
      renderer.render(scene, camera);

      window.update();
    }
  };

  init();
  animate();
} 

