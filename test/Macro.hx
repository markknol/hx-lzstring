package;
import lzstring.LZString;

/**
 * ...
 * @author Mark Knol
 */
class Macro{

	public static macro function test() {
		var input = "aaaaabaaaaacaaaaadaaaaaeaaaaaaa";
		
		var l = new LZString();
		var compressed = l.compress(input);
		trace(compressed);
		var decompressed = l.decompress(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		var l = new LZString();
		var compressed = l.compressToEncodedURIComponent(input);
		trace(compressed);
		var decompressed = l.decompressFromEncodedURIComponent(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		var l = new LZString();
		var compressed = l.compressToUint8Array(input);
		trace(compressed);
		var decompressed = l.decompressFromUint8Array(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		var l = new LZString();
		var compressed = l.compressToBase64(input);
		trace(compressed);
		var decompressed = l.decompressFromBase64(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		var compressed = l.compressToUTF16(input);
		trace(compressed);
		var decompressed = l.decompressFromUTF16(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		
		return macro $v{compressed};
	}
	
}