package;

import openfl.display.StageScaleMode;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;

import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.geom.Rectangle;

import openfl.events.ProgressEvent;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Assets;
import openfl.Lib;
import Types;

class Loader extends Screen {
	
	var loadText:Text;
	
	public function new() {
		super();
	}
	
	public function preload():Void {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		#if flash
		stage.showDefaultContextMenu = false;
		#elseif js
		js.Browser.window.oncontextmenu = function(e) {
			e.stopPropagation();
			e.preventDefault();
			return false;
		};
		#end
		
		loadText = loading();
		addChild(loadText);
		
		stage.addEventListener(ProgressEvent.PROGRESS, onProgress);
		stage.addEventListener(Event.COMPLETE, onComplete);
	}
	
	public static function loading():Text {
		var stage = Lib.current.stage;
		var text = new Text(Lang.get("loading"));
		text.format.size = 50;
		text.update();
		text.x = stage.stageWidth/2 - text.width/2;
		text.y = stage.stageHeight/2 - text.height/2;
		text.blendMode = openfl.display.BlendMode.INVERT;
		return text;
	}
	
	function onProgress(e:ProgressEvent):Void {
		var percent = e.bytesLoaded / e.bytesTotal;
		//trace('loading: '+percent);
		loadText.alpha = 1 - percent;
	}
	
	function onComplete(e:Event):Void {
		trace("loading comlete");
		stage.removeEventListener(ProgressEvent.PROGRESS, onProgress);
		stage.removeEventListener(Event.COMPLETE, onComplete);
		
		var editor = new Editor();
		editor.init();
		editor.show();
	}
	
	public static function loadMap(path:String):Basis {
		var stage = Lib.current.stage;
		#if sys
		var text = sys.io.File.getContent(path);
		#else
		var text = '{"error": "not supported"}';
		#end
		var basis:Basis = haxe.Json.parse(text);
		return basis;
	}
	
	public static function loadExample(id:Int=0):Basis {
		var stage = Lib.current.stage;
		var text = Assets.getText("res/examples/"+id+".json");
		var basis:Basis = haxe.Json.parse(text);
		
		return basis;
	}
	
}
