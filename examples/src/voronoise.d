import grape;
import std.range;
import std.stdio;
import std.datetime;

void main() {
  Window window;
  Renderer renderer;
  Camera camera;
  Scene scene;
  bool loop = true;
  float[2] resolution = [ 1280, 720 ];
  ShaderMaterial planeM;

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
      planeM = new ShaderMaterial(
        "vertexShader", q{
          attribute vec3 position;

          void main() {
            gl_Position = vec4(position, 1.0);
          }
        },
        "fragmentShader", q{
          uniform vec2 resolution;
          uniform float time;

          float rand(float n) {
            return fract(sin(n) * 43758.5453123);
          }

          vec2 rand2(in vec2 p) {
            return fract(vec2(sin(p.x * 591.32 + p.y * 154.077 + time), cos(p.x * 391.32 + p.y * 49.077 + time)));
          }

          float noise1(float p) {
            float fl = floor(p);
            float fc = fract(p);
            return mix(rand(fl), rand(fl + 1.0), fc);
          }

          float voronoi(in vec2 x) {
            vec2 p = floor(x);
            vec2 f = fract(x);
            
            vec2 res = vec2(8.0);
            for(int j = -1; j <= 1; j ++) {
              for(int i = -1; i <= 1; i ++) {
                vec2 b = vec2(i, j);
                vec2 r = vec2(b) - f + rand2(p + b);
                
                float d = max(abs(r.x), abs(r.y));
                
                if(d < res.x) {
                  res.y = res.x;
                  res.x = d;
                }
                else if(d < res.y) {
                  res.y = d;
                }
              }
            }
            return res.y - res.x;
          }

          float flicker = noise1(time * 2.0) * 0.8 + 0.4;

          void main(void) {
            vec2 uv = gl_FragCoord.xy / resolution.xy;
            uv = (uv - 0.5) * 2.0;
            vec2 suv = uv;
            uv.x *= resolution.x / resolution.y;
            
            float v = 0.0;
            
            //v = 1.0 - length(uv) * 1.3;
            
            float a = 0.6, f = 1.0;
            
            for(int i = 0; i < 3; i ++) { 
              float v1 = voronoi(uv * f + 5.0);
              float v2 = 0.0;
              
              if(i > 0) {
                v2 = voronoi(uv * f * 0.5 + 50.0 + time);
                
                float va = 0.0, vb = 0.0;
                va = 1.0 - smoothstep(0.0, 0.1, v1);
                vb = 1.0 - smoothstep(0.0, 0.08, v2);
                v += a * pow(va * (0.5 + vb), 2.0);
              }
              
              v1 = 1.0 - smoothstep(0.0, 0.3, v1);
              v2 = a * (noise1(v1 * 5.5 + 0.1));
              
              if(i == 0)
                v += v2 * flicker;
              else
                v += v2;
              
              f *= 3.0;
              a *= 0.7;
            }

            v *= exp(-0.6 * length(suv)) * 1.2;
            vec3 cexp = vec3(3.0, 2.0, 1.3) * 1.3;
            vec3 col = vec3(pow(v, cexp.x), pow(v, cexp.y), pow(v, cexp.z)) * 2.0;
            
            gl_FragColor = vec4(col, 1.0);
          }
        },
        "uniforms", [
          "resolution": [ "type": UniformType("2fv"), "value": UniformType(resolution) ],
          "time": [ "type": UniformType("1f"), "value": UniformType(0) ]
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
    float cnt = 0;
    while (loop) {
      Input.poll();

      planeM.set_uniform("time", cnt);
      renderer.render(scene, camera);
      //composer.render();

      window.update();
      cnt += 0.01;
    }
  };

  init();
  animate();
}

