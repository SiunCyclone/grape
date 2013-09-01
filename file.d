module orange.file;

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
//import std.string;

// obj hdr
class FileHdr {
  public:
    float[] make_mesh(string file) {
      float[] mesh;
      auto f = File(file, "r");

      foreach (string line; lines(f)) {
        if (line.split[0] != "v") continue;
        foreach (float coord; line.split[1..4].map!(x => to!(float)(x)).array)
          mesh ~= coord;
      }

      return mesh;
    }

    float[] make_normal(string file) {
      float[][] normalBase;
      float[] normal;
      auto f = File(file, "r");

      foreach (string line; lines(f)) {
        if (line.split[0] == "vn") {
          normalBase ~= line.split[1..4].map!(x => to!(float)(x)).array;
        } else if (line[0] == 'f') {
          /*
          auto k = line.split[1..$].map!(x => x.split("//"));
          int[] index = k.map!(x => x[1]).map!(y => to!(int)(y)-1).array;
          */

          /*
          int l = line.split[1..$].length;
          int index = to!(int)(line.split[1].split("//")[1])-1;

          if (l > 3) {
            for (int i; i<6; ++i)
              normal ~= normalBase[index];
          } else {
            for (int i; i<3; ++i)
              normal ~= normalBase[index];
          }
          */

          /*
          normal ~= [normalBase[index[0]], normalBase[index[1]], normalBase[index[2]]];
          if (index.length > 3)
            normal ~= [normalBase[index[0]], normalBase[index[3]], normalBase[index[2]]];
            */
        }
      }

      //return normal;
      return [ 1.000000, -1.000000, -1.000000,
               1.000000, -1.000000, 1.000000,
               -1.000000, -1.000000, 1.000000,
               -1.000000, -1.000000, -1.000000,
               1.000000, 1.000000, -0.999999,
               0.999999, 1.000000, 1.000001,
               -1.000000, 1.000000, 1.000000,
               -1.000000, 1.000000, -1.000000 
             ];
    }

    int[] make_index(string file) {
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
