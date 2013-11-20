import grape.window;
import grape.image;
import grape.input;

void main() {
  int width = 640;
  int height = 480;
  Window window = new Window("example_image", width, height);
  window.enable_alpha();

  Image image = new Image("./image.png");
  ImageRenderer renderer = new ImageRenderer(image);
  
  bool loop = true;
  Input.key_down(KEY_Q, {
    loop = false;
  });

  while (loop) {
    Input.poll();

    renderer.render(-width/2, height/2, 1.0);

    window.update();
  }
} 

