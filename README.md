Grape
======

Grape is a Cross-Platform Game Library for D.

### Building

##### Requirement
* Dub or Git

##### Procedure
###### -- Recommended way (Require Dub)

Just add below code to your package.json
```
{
    "dependencies": {
        "grape": "~master"
    }
}
```

###### -- Another way (Require Git)  

`$GRAPE` is the path of the cloned grape directory.  

1, Clone the repos  
```
  git clone git://github.com:pabekkubb/grape.git
  cd $GRAPE
  git clone git://github.com/aldacron/Derelict3
```

2, Build Grape and Derelict3
```
  cd $GRAPE/build
  dmd build.d
  ./build
```

3, Add compiler options  
Linex:
```d
  -I$GRAPE/Derelict3/import
  -I$GRAPE/import
  $GRAPE/Derelict3/dmd/libDerelictSDL2.a
  $GRAPE/Derelict3/dmd/libDerelictGL3.a
  $GRAPE/Derelict3/dmd/libDerelictUtil.a
  $GRAPE/lib/libGrape.a
  -L-ldl
```
or
```d
  -I$GRAPE/Derelict3/import
  -I$GRAPE/import
  -L-L$GRAPE/Derelict3/lib/dmd
  $GRAPE/lib/libGrape.a  
  ------------------------------
  ### In your source code ###
  pragma(lib, "DerelictSDL2");
  pragma(lib, "DerelictGL3");
  pragma(lib, "DerelictUtil");
  pragma(lib, "dl");
```
Windows:  
TODO

### Documentation
TODO

### API Reference
* Japanese  
http://pabekkubb.github.io/grape/
(Work in progress)

