@ECHO OFF
ECHO building country.sys

REM cleanup any existing files to ensure new build
IF EXIST country.sys     DEL country.sys

REM perform the build
nasm -o country.sys country.asm

REM indicate results
IF     EXIST country.sys ECHO country successfully built
IF NOT EXIST country.sys ECHO ERROR! country.sys not built
