module grape.file;

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
//import std.string;

// obj hdr
class FileHdr {
  public:
    float[] make_mesh(in string file) {
      float[] mesh;
      auto f = File(file, "r");

      foreach (string line; lines(f)) {
        if (line.split[0] != "v") continue;
        foreach (float coord; line.split[1..$].map!(x => to!(float)(x)).array)
          mesh ~= coord;
      }

      return mesh;
    }

    float[] make_normal(in string file) {
      float[][] randomNormal;
      float[] normal;
      auto f = File(file, "r");
      // optimize create normal
      auto memorize = delegate void() {
      };

      foreach (string line; lines(f)) {
        if (line.split[0] == "vn") {
          randomNormal ~= [line.split[1..$].map!(x => to!(float)(x)).array];
        }

        if (line.split[0] == "f" ) {
          if (normal.length == 0)
            normal.length = randomNormal.length * 3;
          foreach (index; line.split[1..$].map!(x => x.split("//")).map!(y => [to!(int)(y[0])-1, to!(int)(y[1])-1])) {
            for (int i; i<3; ++i)
              normal[index[0]*3+i] = randomNormal[index[1]][i];
          }
        }
      }

      return normal;
    }

    int[] make_index(in string file) {
      int[] t;
      auto buf = appender(t);
      auto f = File(file, "r");

      foreach (string line; lines(f)) {
        if (line.split[0] != "f") continue;

        string[] u = line.split[1..$];
        auto k = u.map!(x => x.split("//"));
        int[] index = (k[0].length < 2) ?
                      u.map!(x => to!(int)(x)-1).array :
                      k.map!(x => x[0]).map!(y => to!(int)(y)-1).array;

        buf.put([index[0], index[1], index[2]]);
        if (index.length > 3)
          buf.put([index[0], index[3], index[2]]);
      }

      return buf.data;
    }
}
