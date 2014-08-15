import grape;
import std.range;
import std.stdio;

void main() {
  Window window;
  Renderer renderer;
  Camera camera;
  Scene scene;
  bool loop = true;
  float[2] resolution = [ 640, 480 ];

  EffectComposer composer;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window(cast(int)resolution[0], cast(int)resolution[1]);
      renderer = new Renderer;
      camera = new Camera(1, 100);
      scene = new Scene;
      camera.look_at(Vec3(0, 0, 3), Vec3(0, 0, 0), Vec3(0, 1, 0));

      Input.key_down(KEY_Q, {
        loop = false;
      });
    };

    void delegate() initCube = {
      auto cubeG = new BoxGeometry(1, 1, 1);
      auto cubeM = new ColorMaterial(
        "color", [ 100, 100, 200 ]
      );
      auto cube = new Mesh(cubeG, cubeM);
     //scene.add(cube);
    };

    void delegate() initPlane = {
      auto planeG = new PlaneGeometry(2, 2);
      auto planeM = new ShaderMaterial(
        "vertexShader", q{
          attribute vec3 position;
          attribute vec4 color;
          uniform mat4 pvmMatrix;
          varying vec4 vColor;

          void main() {
            vColor = color;
            gl_Position = vec4(position, 1.0);
          }
        },
        "fragmentShader", q{
          uniform vec2 resolution;
          varying vec4 vColor;

          void main() {
            vec2 uv = gl_FragCoord.xy / resolution.xy;
            uv = (uv - 0.5) * 2.0;
            uv.x *= resolution.x / resolution.y;

            float dist = length(uv);
            gl_FragColor = vColor * vec4(vec3(0.4 / dist), 1.0);
          }

        },
        "uniforms", [
          "resolution": [ "type": UniformType("2fv"), "value": UniformType(resolution) ]
        ],
        "attributes", [
          "color": [ "type": AttributeType(4), "value": AttributeType([ 0.312f, 0.434f, 0.754f, 1.0f ].cycle.take(4*4).array) ]
        ]
      );
      auto plane = new Mesh(planeG, planeM);
      scene.add(plane);
    };

    void delegate() initComposer = {
      composer = new EffectComposer(renderer);
      composer.add_pass(new RenderPass(scene, camera));
      composer.add_pass(new BlurPass(64, 64));
      //composer.add_pass(new GlowPass(640, 480, 128, 128));
    };

    initCore();
    initCube();
    initPlane();
    initComposer();
  };

  void delegate() animate = {
    while (loop) {
      Input.poll();

      renderer.render(scene, camera);
      //composer.render();

      window.update();
    }
  };

  init();
  animate();
}

