import std.stdio;
import std.math;

import grape.window;
import grape.camera;
import grape.renderer;
import grape.filter;
import grape.input;
import grape.math;
import grape.keyboard;
import derelict.opengl3.gl3;
//import derelict.sdl2.sdl;

void main() { 
  int width = 800;
  int height = 800;
  Window window = new Window("example", width, height);

  Camera camera = new Camera;

  glLineWidth(3);
  glEnable(GL_LINE_SMOOTH);

  NormalRenderer renderer = new NormalRenderer;
  GlowFilter filter = new GlowFilter(width, height, 50, 50);

  float[] coords = [ -0.5, 0.0, 0.0,
                     0.5, 0.0, 0.0,
                     0.0, 0.5, 0.0 ];
  float[] color = [ 1.0, 0.0, 0.0, 1.0,
                    0.0, 1.0, 0.0, 1.0,
                    0.0, 0.0, 1.0, 1.0 ];
  int[] index = [ 0, 1, 2 ];
  /*
  for (int i=-400; i<400; ++i) {
    coords ~= [i/400.0*1.7, sin((PI*2/400)*i*2)*0.4, 0.0];
  }

  for (int i; i<coords.length/3; ++i) {
    color ~= [ 0.4, 0.5, 0.9, 1.0 ];
    index ~= i;
  }
  */

  bool running = true;

  Input.key_down(KEY_Q, {
    running = false;
  });

  /*
  Input.axis_move(number, {

  });

  Input.button_down(number, {

  });

  Input.hat_down(direction, {

  });
  */

  while (running) {
    Input.poll();

    renderer.set_uniform("pvmMatrix", camera.pvMat4.mat, "mat4fv");
    renderer.set_ibo(index);
    renderer.set_vbo(coords, color);

    filter.filter({
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      renderer.render();
    });
    filter.render();

    window.update();
  }
}
