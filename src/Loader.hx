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
	
	public static function loadExample(id:Int=0):Basis { //fix
		var stage = Lib.current.stage;
		var text = Assets.getText("res/examples/"+id+".json");
		var basis:Basis = haxe.Json.parse(text);
		
		for (i in 0...basis.points.length) { //make point links to edges
			if (basis.points[i] == null) continue;
			basis.points[i].edges = [];
			for (i2 in 0...basis.edges.length) {
				if (basis.edges[i2] == null) continue;
				if (basis.edges[i2].p1 == i || basis.edges[i2].p2 == i) basis.points[i].edges.push(i2);
			}
		}
		
		for (i in 0...basis.edges.length) { //cache angles
			if (basis.edges[i] == null) continue;
			var e = basis.edges[i];
			var p = basis.points;
			e.ang = Math.atan2(p[e.p2].y - p[e.p1].y, p[e.p2].x - p[e.p1].x);
		}
		
		return basis;
	}
	
}
