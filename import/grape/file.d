module grape.file;

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
//import std.string;

import grape.math;
// obj hdr
/**
 * ファイル操作をするクラス
 *
 * TODO:
 * Rename
 */
class FileHdr {
  public:
    /**
     * objファイルから頂点を読み込む
     *
     * objファイルを読み込んで、頂点をVec3[]の配列にして返します。
     * file: objファイル名
     */
    Vec3[] make_vertices(in string file) {
      Vec3[] vertices;
      auto f = File(file, "r");

      float[] coord;
      foreach (string line; lines(f)) {
        if (line.split[0] != "v") continue;
        foreach (float value; line.split[1..$].map!(x => to!(float)(x)).array) {
          coord ~= value;
        }
        vertices ~= Vec3(coord);
        coord.length = 0;
      }

      return vertices;
    }

    /**
     * objファイルから法線を読み込む
     *
     * objを読み込んで、法線をVec3[]の配列にして返します。
     * file: objファイル名
     */
    // FIXME listの最後にnanが入ってる。
    Vec3[] make_normals(in string file) {
      Vec3[] list;
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

      for(int i; i<normal.length/3; ++i) {
        list ~= Vec3([normal[i*3], normal[i*3+1], normal[i*3+2]]);
      }

      return list;
    }


    /**
     * objファイルからインデックスを読み込む
     *
     * objを読み込んで、インデックスをint[]の配列にして返します。
     * file: objファイル名
     */
    int[] make_indices(in string file) {
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

