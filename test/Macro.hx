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
		var compressed = l.compressToUTF16(input);
		trace(compressed);
		var decompressed = l.decompressFromUTF16(compressed);
		trace(decompressed);
		trace(Std.int(compressed.length / input.length * 100) + "%");
		trace(decompressed == input);
		return macro $v{compressed};
	}
	
}