Orange
======

Orange is a Cross-Platform Game Library for D.

### Building

###### Requirement
* OpenGL
* SDL2
* SDL2TTF
* SDL2IMAGE
* Git

###### Procedure
`$ORANGE` is the path of the cloned orange directory.  

1, Clone the repo  
```
  git clone git://github.com:pabekkubb/orange.git
```
2, Build Orange   
```
  cd $ORANGE/build
  dmd build.d
  ./build
```
3, Add compiler options  
Linex:
```d
  -I$ORANGE/Derelict3/import
  -I$ORANGE/import
  $ORANGE/Derelict3/dmd/libDerelictSDL2.a
  $ORANGE/Derelict3/dmd/libDerelictGL3.a
  $ORANGE/Derelict3/dmd/libDerelictUtil.a
  $ORANGE/lib/libOrange.a
  -L-ldl
```
or
```d
  -I$ORANGE/Derelict3/import
  -I$ORANGE/import
  -L-L$ORANGE/Derelict3/lib/dmd
  $ORANGE/lib/libOrange.a  
  ------------------------------
  ### In your source code ###
  pragma(lib, "DerelictSDL2");
  pragma(lib, "DerelictGL3");
  pragma(lib, "DerelictUtil");
  pragma(lib, "dl");
```
Windows:  
TODO

