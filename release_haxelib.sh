#!/bin/sh
rm -f LZString.zip
zip -r LZString.zip src haxelib.json *.md
haxelib submit LZString.zip $HAXELIB_PWD --always