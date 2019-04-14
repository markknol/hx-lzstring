# LZString
[![Build Status](https://travis-ci.org/markknol/hx-lzstring.svg?branch=master)](https://travis-ci.org/markknol/hx-lzstring) [![Haxelib Version](https://img.shields.io/github/tag/markknol/hx-lzstring.svg?label=haxelib)](http://lib.haxe.org/p/lzstring)
 
**LZ-based compression algorithm for Haxe.**

This is a port of lz-string <https://github.com/pieroxy/lz-string>. More info about the library can be found here http://pieroxy.net/blog/pages/lz-string/index.html.

This library should run on all Haxe targets. (but is mostly tested in JavaScript and Macro context).

### Dependencies

 * [Haxe](https://haxe.org/) 4.0+

### Install the library for your project

Install the library using haxelib

```
haxelib install lzstring
```

And add this to your compile arguments / build hxml file

```
-lib lzstring
```

### Using the library

Import the library in your code.

```haxe
import lzstring.LZString;
```

#### API

```haxe
compress(uncompressed:String):String
compressToBase64(input:String):String
compressToEncodedURIComponent(input:String):String
compressToUint8Array(uncompressed:String):UInt8Array
compressToUTF116(input:String):String

decompress(compressed:String):String
decompressToBase64(input:String):String
decompressToEncodedURIComponent(input:String):String
decompressToUint8Array(compressed:UInt8Array):String
decompressToUTF116(compressed:String):String
```

#### Usage
```haxe
var input = "aaaaabaaaaacaaaaadaaaaaeaaaaaaa";
var l = new LZString();

var compressed = l.compress(input);
trace(compressed);  // â†‰à£”ä†ã „í˜…ã–ˆè€€

var decompressed = l.decompress(compressed);
trace(decompressed); // aaaaabaaaaacaaaaadaaaaaeaaaaaaa

trace(input == decompressed); // true
```

#### Base64 

```haxe
var input = "aaaaabaaaaacaaaaadaaaaaeaaaaaaa";
var l = new LZString();
var compressed = l.compressToBase64(input);
trace(compressed); // IYkI1EGNOATWBTWIg===

var decompressed = l.decompressFromBase64(compressed);
trace(decompressed); // aaaaabaaaaacaaaaadaaaaaeaaaaaaa

trace(input == decompressed); // true
```

### Run test

Clone the repository and run 
```
haxe test.hxml
```

