import grape.window;
import grape.camera;
import grape.renderer;
import grape.input;
import grape.math;

void main() { 
  int width = 640;
  int height = 480;
  Window window = new Window("basic_example", width, height);

  Camera camera = new Camera;
  BasicRenderer renderer = new BasicRenderer;

  float[] coords = [ -0.4, -0.3, 0.0,
                     0.4, -0.3, 0.0,
                     0.0, 0.5, 0.0 ];
  float[] color = [ 1.0, 0.0, 0.0, 1.0,
                    0.0, 1.0, 0.0, 1.0,
                    0.0, 0.0, 1.0, 1.0 ];
  int[] index = [ 0, 1, 2 ];

  renderer.set_vbo(coords, color);
  renderer.set_ibo(index);

  bool loop = true;
  Input.key_down(KEY_Q, {
    loop = false;
  });

  Vec3 axis = Vec3(0, 1, 0);
  float rad = PI_2 / 180.0;

  while (loop) {
    Input.poll();

    camera.rotate(axis, rad);

    renderer.set_uniform("pvmMatrix", camera.pvMat4.mat, "mat4fv");
    renderer.render();

    window.update();
  }
}

