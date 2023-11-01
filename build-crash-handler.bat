@echo off

cd crash-dialog
echo Building crash dialog...
haxelib run lime build windows
copy build\openfl\windows\bin\GrafexCrashHandler.exe ..\export\release\windows\bin\GrafexCrashHandler.exe
cd ..

@echo on