Orange
======

Building
--------

### Requirement ###  
* OpenGL
* SDL2
* SDL2TTF
* SDL2IMAGE

### Procedure ###  
`$ORANGE` is the path of the cloned orange directory  

1. Clone the repo  
```
git clone git://github.com:pabekkubb/orange.git
```

2. Initialize and update the submodule  
```
cd $ORANGE
git submodule init  
git submodule update  
```

3. Build Derelict3  
```
cd $ORANGE/Derelict3/build
dmd build.d
./build Util GL3 SDL2
```

4. Build Orange  
```
cd $ORANGE
make
```

5. Add compiler options  
Linex:
```
-I$ORANGE/Derelict3/import
-I$ORANGE/import
$ORANGE/Derelict3/dmd/libDerelictSDL2.a
$ORANGE/Derelict3/dmd/libDerelictGL3.a
$ORANGE/Derelict3/dmd/libDerelictUtil.a
-L-ldl
$ORANGE/lib/libOrange.a
```
or
```
-I$ORANGE/Derelict3/import
-I$ORANGE/import
-L-L$ORANGE/Derelict3/lib/dmd
$ORANGE/lib/libOrange.a

In your source code:
pragma(lib, "DerelictSDL2");
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictUtil");
pragma(lib, "dl");
```

Windows:  
TODO

