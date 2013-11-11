Orange
======

Orange is a Cross-Platform Game Library for D.

### Building

##### Requirement
* OpenGL
* SDL2
* SDL2TTF
* SDL2IMAGE
* Dub or Git

##### Procedure
###### -- Recommended way (Require Dub)

  Just add below code to your package.json
```
{
    "dependencies": {
        "orange": "~master"
    }
}
```

###### -- Another way (Require Git)  

`$ORANGE` is the path of the cloned orange directory.  

1, Clone the repos  
```
  git clone git://github.com:pabekkubb/orange.git
  cd $ORANGE
  git clone git://github.com/aldacron/Derelict3
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

