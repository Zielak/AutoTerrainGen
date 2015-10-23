package js;

#if web

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesOutput;
import js.html.Uint8Array;
import js.pako.Pako;

class BuildPNG {
	private static var o:BytesOutput;

	// shamelessly stolen and adapted from https://github.com/HaxeFoundation/format/tree/master/format/png
	public static function build(width:Int, height:Int, data:Bytes):Uint8Array {
		// create a stream of bytes
		o = new BytesOutput();
		o.bigEndian = true;

		// add the PNG front matter
		for(b in [137,80,78,71,13,10,26,10])
			o.writeByte(b);

		// add the header
		var b = new BytesOutput();
		b.bigEndian = true;
		b.writeInt32(width);
		b.writeInt32(height);
		b.writeByte(8);
		b.writeByte(6);
		b.writeByte(0);
		b.writeByte(0);
		b.writeByte(0);
		writeChunk("IHDR", b.getBytes());

		// format the data
		var rgba = Bytes.alloc(width * height * 4 + height);
		var w = 0, r = 0;
		for(y in 0...height) {
			rgba.set(w++, 0); // no filter for this scanline
			for(x in 0...width) {
				rgba.set(w++, data.get(r + 2)); // r
				rgba.set(w++, data.get(r + 1)); // g
				rgba.set(w++, data.get(r)); // b
				rgba.set(w++, data.get(r + 3)); // a
				r += 4;
			}
		}
		// deflate the data
		var bytesData:BytesData = rgba.getData();
		var arrForm:Uint8Array = new Uint8Array(bytesData);
		var deflated:Uint8Array = Pako.deflate(arrForm);
		var d = Bytes.alloc(deflated.length);
		for(i in 0...deflated.length) {
			d.set(i, deflated[i]);
		}
		writeChunk("IDAT", d);
		
		// write the end
		writeChunk("IEND", Bytes.alloc(0));

		// return the array of bytes!
		return new Uint8Array(o.getBytes().getData());
	}

	private static function writeChunk(id:String, data:Bytes) {
		o.writeInt32(data.length);
		o.writeString(id);
		o.write(data);
		var crc = new haxe.crypto.Crc32();
		for(i in 0...4)
			crc.byte(id.charCodeAt(i));
		crc.update(data, 0, data.length);
		o.writeInt32(crc.get());
	}
}

#end