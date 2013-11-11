orange
======

1. リポジトリのclone  
```
git clone git://github.com:pabekkubb/orange.git
```

2. submoduleの初期化,更新   
```
cd /path/to/orange  
git submodule init  
git submodule update  
```

3. Derelict3のbuild  
```
cd /path/to/orange/Derelict3/build
dmd build.d
./build
```

4. 静的リンク作成  
```
cd /path/to/orange
make
```

5. コンパイルオプションの追加   
```
-I./orange/Derelict3/import -L-L./orange/Derelict3/lib/dmd 
-I./orange/import ./orange/lib/libOrange.a
```

