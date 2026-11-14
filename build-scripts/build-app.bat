@echo off
set PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd
set INCLUDE=
set LIB=
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" || exit /b 1
set B=D:\fritzing-build
set QT=%B%\Qt\6.8.3\msvc2022_64
set PATH=%QT%\bin;%PATH%
if not exist %B%\obj\app mkdir %B%\obj\app
cd /d %B%\obj\app
echo ===== qmake
qmake %B%\fritzing-app\phoenix.pro "CONFIG-=debug_and_release" "CONFIG+=release" "QMAKE_CXXFLAGS+=/MP16" "boost_root=%B%\boost_1_85_0" || exit /b 2
echo ===== nmake
nmake /NOLOGO || exit /b 3
echo APP OK
