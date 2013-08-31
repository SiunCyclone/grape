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
        if (line[0] != 'v') continue;
        foreach (float coord; line.split[1..4].map!(x => to!(float)(x)).array)
          mesh ~= coord;
      }

      return mesh;
    }

    int[] make_index(string file) {
      int[] t;
      auto buf = appender(t);
      auto f = File(file, "r");

      foreach (string line; lines(f)) {
        if (line[0] != 'f') continue;

        int[] ary = line.split[1..$].map!(x => to!(int)(x)-1).array;
        buf.put([ary[0], ary[1], ary[2]]);
        if (ary.length > 3)
          buf.put([ary[0], ary[3], ary[2]]);
      }

      return buf.data;
    }
}
