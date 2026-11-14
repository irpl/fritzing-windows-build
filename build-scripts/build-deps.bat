@echo off
set PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0
set INCLUDE=
set LIB=
set CPATH=
set C_INCLUDE_PATH=
set CPLUS_INCLUDE_PATH=
set PKG_CONFIG_PATH=
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" || exit /b 1
set B=D:\fritzing-build
set QT=%B%\Qt\6.8.3\msvc2022_64
set PATH=%QT%\bin;%PATH%

goto quazip
echo ===== libgit2 (shared)
cmake -S %B%\src\libgit2-1.7.1 -B %B%\obj\libgit2 -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_TESTS=OFF -DBUILD_CLI=OFF -DUSE_SSH=OFF -DUSE_BUNDLED_ZLIB=ON -DREGEX_BACKEND=builtin -DCMAKE_INSTALL_PREFIX=%B%\libgit2-1.7.1 || exit /b 2
cmake --build %B%\obj\libgit2 --target install || exit /b 3

:quazip
echo ===== zlib (static)
cmake -S %B%\src\zlib-1.3.1 -B %B%\obj\zlib -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=%B%\zlib || exit /b 9
cmake --build %B%\obj\zlib --target install || exit /b 9
echo ===== quazip
cmake -S %B%\src\quazip-1.4 -B %B%\obj\quazip -G Ninja -DCMAKE_BUILD_TYPE=Release -DQUAZIP_QT_MAJOR_VERSION=6 -DZLIB_INCLUDE_DIR=%B%\zlib\include -DZLIB_LIBRARY=%B%\zlib\lib\zlibstatic.lib -DCMAKE_PREFIX_PATH=%QT% -DBUILD_SHARED_LIBS=ON -DQUAZIP_BZIP2=OFF -DCMAKE_INSTALL_PREFIX=%B%\quazip-6.8.3-1.4intuisphere || exit /b 4
cmake --build %B%\obj\quazip --target install || exit /b 5

echo ===== clipper
cmake -S %B%\src\clipper\cpp -B %B%\obj\clipper -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=%B%\Clipper1-6.4.2 || exit /b 6
cmake --build %B%\obj\clipper --target install || exit /b 7

echo ===== ngspice headers
xcopy /E /I /Y /Q %B%\src\ngspice\Spice64_dll %B%\ngspice-42 >nul || exit /b 8
echo DEPS OK
