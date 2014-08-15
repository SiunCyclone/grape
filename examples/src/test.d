/*
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
*/

import grape;

void main() {
  Window window;
  Renderer renderer;
  Camera camera;
  Scene scene;
  bool loop = true;
  float[2] resolution = [ 1280, 720 ];

  EffectComposer composer;

  void delegate() init = {
    void delegate() initCore = {
      window = new Window(cast(int)resolution[0], cast(int)resolution[1]);
      renderer = new Renderer;
      renderer.enable_depth;
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
            gl_FragColor = vColor * vec4(vec3(2.0 / dist), 1.0);
          }
        },
        "uniforms", [
          "resolution": [ "type": UniformType("2fv"), "value": UniformType(resolution) ]
        ],
        "attributes", [
          "color": [ "type": AttributeType(4), "value": AttributeType([ 0.312f, 0.434f, 0.754f, 1.0f ]) ]
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

