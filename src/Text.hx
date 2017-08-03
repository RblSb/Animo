package;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;

class Text extends TextField { //добавить общий TextFormat
	//public var format(default, set) = new TextFormat("_sans", 14, 0x888888);
	public var format:TextFormat = new TextFormat("_sans", 14, 0x888888);
	
	public function new(?text:String, ?x:Float, ?y:Float) {
		super();
		defaultTextFormat = format;
		if (x != null) this.x = x;
		if (y != null) this.y = y;
		if (text != null) this.text = text;
		autoSize = TextFieldAutoSize.LEFT;
		selectable = false;
		//wordWrap = true;
		//multiline = true;
		
		#if debug
		border = true;
		borderColor = format.color;
		#end
	}
	
	/*function set_format(format:TextFormat):TextFormat {
		defaultTextFormat = format;
		setTextFormat(format);
		return format;
	}*/
	
	public function update():Void {
		defaultTextFormat = format;
		setTextFormat(format);
	}
	
}
