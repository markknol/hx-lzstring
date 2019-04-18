package lzstring;

#if js
import js.html.Uint8Array as UInt8Array;
#else
import haxe.io.UInt8Array;
#end
import haxe.ds.Map;

using StringTools;

/**
 * Ported from <https://github.com/pieroxy/lz-string/>
 * @author Mark Knol
 */
class LZString {
	static var keyStrBase64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	static var keyStrUriSafe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$";

	private var baseReverseDic:Map<String, Map<String, Int>> = new Map();

	public function new() {}

	function getBaseValue(alphabet:String, character:String) {
		if (!baseReverseDic.exists(alphabet)) {
			baseReverseDic[alphabet] = [
				for (i in 0...alphabet.length) alphabet.charAt(i) => i
			];
		}
		return baseReverseDic[alphabet][character];
	}

	public function compressToBase64(input):String {
		if (input == null)
			return "";
		var res = _compress(input, 6, a -> keyStrBase64.charAt(a));
		return switch (res.length % 4) { // To produce valid Base64
			case 0: res;
			case 1: res + "===";
			case 2: res + "==";
			case 3: res + "=";
			default: ""; // When could this happen ?
		}
	}

	public function decompressFromBase64(input):String {
		if (input == null) return "";
		if (input == "") return null;
		return _decompress(input.length, 32, index -> getBaseValue(keyStrBase64, input.charAt(index)));
	}

	public function compressToUTF16(input:String):String {
		if (input == null) return "";
		return _compress(input, 15, a -> String.fromCharCode(a + 32)) + " ";
	}

	public function decompressFromUTF16(compressed:String):String {
		if (compressed == null) return "";
		if (compressed == "") return null;
		return _decompress(compressed.length, 16384, index -> compressed.charCodeAt(index) - 32);
	}

	// compress into uint8array (UCS-2 big endian format)
	public function compressToUint8Array(uncompressed:String):UInt8Array {
		var compressed = compress(uncompressed);
		var buf = new UInt8Array(compressed.length * 2); // 2 bytes per character

		for (i in 0...compressed.length) {
			var current_value = compressed.charCodeAt(i);
			buf[i * 2] = current_value >>> 8;
			buf[i * 2 + 1] = current_value % 256;
		}
		return buf;
	}

	// decompress from uint8array (UCS-2 big endian format)
	public function decompressFromUint8Array(compressed:UInt8Array):String {
		if (compressed == null) {
			return decompress(null);
		} else {
			var result = new StringBuf();
			for (i in 0...Std.int(compressed.length / 2)) {
				result.add(String.fromCharCode(compressed[i * 2] * 256 + compressed[i * 2 + 1]));
			}
			return decompress(result.toString());
		}
	}

	// compress into a string that is already URI encoded
	public function compressToEncodedURIComponent(input:String):String {
		if (input == null) return "";
		return _compress(input, 6, a -> keyStrUriSafe.charAt(a));
	}

	// decompress from an output of compressToEncodedURIComponent
	public function decompressFromEncodedURIComponent(input:String):String {
		if (input == null) return "";
		if (input == "") return null;
		input = input.replace(" ", "+");
		return _decompress(input.length, 32, index -> getBaseValue(keyStrUriSafe, input.charAt(index)));
	}

	public function compress(uncompressed:String):String {
		return _compress(uncompressed, 16, a -> String.fromCharCode(a));
	}

	function _compress(uncompressed:String, bitsPerChar:Int, getCharFromInt:Int->String):String {
		if (uncompressed == null) return "";

		var context_dictionary:Map<String, Int> = [];
		var context_dictionaryToCreate:Map<String, Bool> = [];
		var value, context_c = "", context_wc = "", context_w = "", context_enlargeIn = 2.0, // Compensate for the first entry which should not count
		context_dictSize = 3, context_numBits = 2, context_data = new StringBuf(), context_data_val = 0, context_data_position = 0;

		inline function iter(count:Int, start:Void->Void, end:Void->Void) {
			for (i in 0...count) {
				start();
				if (context_data_position == bitsPerChar - 1) {
					context_data_position = 0;
					context_data.add(getCharFromInt(context_data_val));
					context_data_val = 0;
				} else {
					context_data_position++;
				}
				end();
			}
		}

		inline function end() {
			context_enlargeIn--;
			if (context_enlargeIn == 0) {
				context_enlargeIn = Math.pow(2, context_numBits);
				context_numBits++;
			}
		}

		for (ii in 0...uncompressed.length) {
			context_c = uncompressed.charAt(ii);
			if (!context_dictionary.exists(context_c)) {
				context_dictionary[context_c] = context_dictSize++;
				context_dictionaryToCreate[context_c] = true;
			}

			context_wc = context_w + context_c;
			if (context_dictionary.exists(context_wc)) {
				context_w = context_wc;
			} else {
				if (context_dictionaryToCreate.exists(context_w)) {
					if (context_w.charCodeAt(0) < 256) {
						iter(context_numBits, () -> context_data_val = (context_data_val << 1), () -> {});
						value = context_w.charCodeAt(0);
						iter(8, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
					} else {
						value = 1;
						iter(context_numBits, () -> context_data_val = (context_data_val << 1) | value, () -> value = 0);
						value = context_w.charCodeAt(0);
						iter(16, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
					}
					end();
					context_dictionaryToCreate.remove(context_w);
				} else {
					value = context_dictionary[context_w];
					iter(context_numBits, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
				}
				end();
				// Add wc to the dictionary.
				context_dictionary[context_wc] = context_dictSize++;
				context_w = context_c;
			}
		}

		// Output the code for w.
		if (context_w != "") {
			if (context_dictionaryToCreate.exists(context_w)) {
				if (context_w.charCodeAt(0) < 256) {
					iter(context_numBits, () -> context_data_val = (context_data_val << 1), () -> {});
					value = context_w.charCodeAt(0);
					iter(8, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
				} else {
					value = 1;
					iter(context_numBits, () -> context_data_val = (context_data_val << 1) | value, () -> value = 0);
					value = context_w.charCodeAt(0);
					iter(16, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
				}
				end();
				context_dictionaryToCreate.remove(context_w);
			} else {
				value = context_dictionary[context_w];
				iter(context_numBits, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);
			}
			end();
		}

		// Mark the end of the stream
		value = 2;
		iter(context_numBits, () -> context_data_val = (context_data_val << 1) | (value & 1), () -> value >>= 1);

		// Flush the last char
		while (true) {
			context_data_val = (context_data_val << 1);
			if (context_data_position == bitsPerChar - 1) {
				context_data.add(getCharFromInt(context_data_val));
				break;
			} else {
				context_data_position++;
			}
		}
		return context_data.toString();
	}

	public function decompress(compressed:String) {
		if (compressed == null)
			return "";
		if (compressed == "")
			return null;
		return _decompress(compressed.length, 32768, index -> compressed.charCodeAt(index));
	}

	function _decompress(length, resetValue, getNextValue):String {
		var next, enlargeIn = 4.0, dictSize = 4, numBits = 3, entry = "", result = new StringBuf(),
		w:Dynamic = null, // TODO: no Dynamic
		bits, resb, maxpower, power, c:Dynamic = null, data = {val: getNextValue(0), position: resetValue, index: 1};

		var dictionary:Map<Int, String> = [for (i in 0...3) i => '$i'];

		inline function iter(exp:Int) {
			bits = 0;
			maxpower = Math.pow(2, exp);
			power = 1;
			while (power != maxpower) {
				resb = data.val & data.position;
				data.position >>= 1;
				if (data.position == 0) {
					data.position = resetValue;
					data.val = getNextValue(data.index++);
				}
				bits |= (resb > 0 ? 1 : 0) * power;
				power <<= 1;
			}
		}
		inline function end() {
			if (enlargeIn == 0) {
				enlargeIn = Math.pow(2, numBits);
				numBits++;
			}
		}

		iter(2);

		switch (next = bits) {
			case 0:
				iter(8);
				c = String.fromCharCode(bits);
			case 1:
				iter(16);
				c = String.fromCharCode(bits);
			case 2:
				return "";
		}
		dictionary[3] = c;
		w = c;
		result.add(c);
		while (true) {
			if (data.index > length) {
				return "";
			}
			iter(numBits);
			switch (c = bits) {
				case 0:
					iter(8);
					dictionary[dictSize++] = String.fromCharCode(bits);
					c = dictSize - 1;
					enlargeIn--;
				case 1:
					iter(16);
					dictionary[dictSize++] = String.fromCharCode(bits);
					c = dictSize - 1;
					enlargeIn--;
				case 2:
					return result.toString();
			}

			end();

			if (dictionary.exists(c)) {
				entry = dictionary[c];
			} else {
				if (c == dictSize) {
					entry = w + w.charAt(0);
				} else {
					return null;
				}
			}
			result.add(entry);

			// Add w+entry[0] to the dictionary.
			dictionary[dictSize++] = w + entry.charAt(0);
			enlargeIn--;

			w = entry;

			end();
		}
	}
}
