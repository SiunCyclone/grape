import grape.window;
import grape.camera;
import grape.renderer;
import grape.input;
import grape.keyboard;

void main() { 
  int width = 640;
  int height = 480;
  Window window = new Window("example", width, height);

  Camera camera = new Camera;
  camera.viewport(0, 0, width/2, height/2);

  NormalRenderer renderer = new NormalRenderer;

  float[] coords = [ -0.5, -0.5, 0.0,
                     0.5, -0.5, 0.0,
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

  while (loop) {
    Input.poll();

    renderer.set_uniform("pvmMatrix", camera.pvMat4.mat, "mat4fv");
    renderer.render();

    window.update();
  }
}

