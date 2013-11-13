import std.process : system;
import std.file;
import std.stdio;

void main() {
  buildDerelict3();
  buildGrape();
}

void buildDerelict3() {
  try {
    string[] commands;

    string directory = "../Derelict3/build";
    commands ~= "dmd -of" ~ directory ~ "/build " ~ directory ~ "/build.d";
    commands ~= directory ~ "/build";
    
    execute(commands);
  }

  catch (Exception e) {
    writeln("buildDerelict3() failed");
  }
}

void buildGrape() {
  try {
    string[] commands;

    string target = "-of../lib/libGrape";
    string ops = "-lib -O -release -inline ";
    string libs = "-I../Derelict3/import ";
    string sources = "";
    foreach (file; dirEntries("../import/grape", "*.d", SpanMode.shallow))
      sources ~= file ~ " ";
    commands ~= "dmd " ~ ops ~ target ~ sources ~ libs;

    execute(commands);
  }

  catch (Exception e) {
    writeln("buildGrape() failed");
  }
}

void execute(string[] commands) {
  foreach (command; commands) {
    writeln(command);
    system(command);
  }
}

