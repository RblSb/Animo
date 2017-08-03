package gif;

import openfl.display.BitmapData;
import openfl.net.FileReference;
import haxe.io.BytesOutput;
import haxe.io.UInt8Array;
import gif.GifEncoder;
#if js
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Blob;
import js.html.URL;
import js.Browser;
#end


class Gif {
	
	public var width:Int;
	public var height:Int;
	public var delay = 0.03;
	public var repeat = GifRepeat.Infinite;
	public var quality = GifQuality.VeryHigh;
	public var skip = 1;
	var output:BytesOutput;
	var encoder:GifEncoder;
	var count = 0;
	
	public function new(width:Int, height:Int, delay=0.03, repeat=-1, quality=10, skip=1) {
		#if flash return; #end
		this.width = width;
		this.height = height;
		this.delay = delay;
		this.repeat = repeat;
		this.quality = quality;
		this.skip = skip;
		count = 0;
		init();
	}
	
	function init():Void {
		output = new BytesOutput();
		encoder = new GifEncoder(width, height, delay, repeat, quality);
		encoder.start(output);
	}
	
	public function addFrame(bmd:BitmapData):Void {
		#if flash return; #end
		count++;
		if (count % skip != 0) return;
		
		var pixels = new UInt8Array(width * height * 3);
		var i = 0;
		
		for (iy in 0...height) {
			for (ix in 0...width) {
				var pixel:UInt = bmd.getPixel(ix, iy);
				pixels[i] = (pixel & 0xFF0000) >> 16;
				i++;
				pixels[i] = (pixel & 0x00FF00) >> 8;
				i++;
				pixels[i] = (pixel & 0x0000FF);
				i++;
			}
		}
			
		var frame:GifFrame = {
			delay: delay,
			flippedY: false,
			data: pixels
		}
		encoder.add(output, frame);
	}
	
	public function save(name:String):Void {
		#if flash return; #end
		encoder.commit(output);
		var bytes = output.getBytes();
		
		#if js
		var data = toArrayBuffer(bytes);
		var blob = new Blob([data], {
			type: "image/gif"
		});
		var url = URL.createObjectURL(blob);
		var a = Browser.document.createElement("a");
		untyped a.download = name;
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		Browser.document.body.appendChild(a);
		a.click();
		Browser.document.body.removeChild(a);
		URL.revokeObjectURL(url);
		#else
		
		var fr = new FileReference();
		fr.save(bytes, name);
		#end
	}
	
	#if js
	public function toArrayBuffer(bytes):ArrayBuffer {
		var buffer = new ArrayBuffer(bytes.length);
		var view = new DataView(buffer, 0, buffer.byteLength);
		for (i in 0...bytes.length) {
			view.setUint8(i, bytes.get(i));
		}
		return buffer;
	}
	#end
}
