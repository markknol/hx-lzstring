package ;
import lzstring.LZString;

/**
	@author $author
**/
class Main {
	public static function main() {
		var input = "aaaaabaaaaacaaaaadaaaaaeaaaaaaa";
		var l = new LZString();
		var compressed = l.compressToUTF16(input);
		trace(compressed);
		var decompressed = l.decompressFromBase64(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		var compressed = l.decompressFromUTF16(input);
		trace(compressed);
		var decompressed = l.decompress(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		trace(Macro.test());
	}
}