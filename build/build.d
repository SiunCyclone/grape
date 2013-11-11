import std.process : system;
import std.file;
import std.stdio;

void main() {
  buildDerelict3();
  buildOrange();
}

void buildDerelict3() {
  try {
    string[] commands;

    string directory = "../Derelict3/build";
    commands ~= "git submodule init";
    commands ~= "git submodule update";
    commands ~= "dmd -of" ~ directory ~ "/build " ~ directory ~ "/build.d";
    commands ~= directory ~ "/build";
    
    execute(commands);
  }

  catch (Exception e) {
    writeln("buildDerelict3() failed");
  }
}

void buildOrange() {
  try {
    string[] commands;

    string target = "-of../lib/libOrange ";
    string ops = "-lib -O -release -inline ";
    string libs = "-I../Derelict3/import -L-L../Derelict3/lib/dmd ";
    string sources = "";
    foreach (file; dirEntries("../import/orange", "*.d", SpanMode.shallow))
      sources ~= file ~ " ";
    commands ~= "dmd " ~ ops ~ target ~ sources ~ libs;

    execute(commands);
  }

  catch (Exception e) {
    writeln("buildOrange() failed");
  }
}

void execute(string[] commands) {
  foreach (command; commands) {
    writeln(command);
    system(command);
  }
}

