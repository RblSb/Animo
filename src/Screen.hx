package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.Lib;

typedef Pointer = {
	?startX:Float,
	?startY:Float,
	?x:Float,
	?y:Float,
	?isDown:Bool,
	?used:Bool
}

class Screen extends Sprite {
	
	public static var screen:Screen; //текущий экран
	public static var blocks:Array<Sprite> = []; //части экрана
	public static var _fps:FPS_Mem;
	public static var _wh:Text;
	
	public var keys:Map<Int, Bool> = new Map();
	public var pointers:Map<Int, Pointer> = [for (i in 0...10) i => {startX:0, startY:0, x:0, y:0, isDown:false, used: false}];
	
	public function new() {
		super();
	}
	
	public function show():Void {
		if (screen != null) screen.hide();
		screen = this;
		
		var stage = Lib.current.stage;
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(Event.RESIZE, _onResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
		
		#if mobile
		screen.addEventListener(TouchEvent.TOUCH_BEGIN, _onTouchDown);
		screen.addEventListener(TouchEvent.TOUCH_MOVE, _onTouchMove);
		screen.addEventListener(TouchEvent.TOUCH_END, _onTouchUp);
		#else
		screen.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
		screen.addEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
		screen.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
		#end
		
		//#if debug
		_wh = new Text(""+stage.stageWidth+"x"+stage.stageHeight);
		_wh.x = stage.stageWidth - _wh.width;
		_wh.y = stage.stageHeight - _wh.height;
		screen.addChild(_wh);
		
		_fps = new FPS_Mem(0, 0);
		_fps.y = stage.stageHeight - _fps.height;
		screen.addChild(_fps);
		//#end
		
		//screen.mouseChildren = false;
		stage.addChildAt(screen, 0);
		_onResize();
	}
	
	public function hide():Void {
		var stage = Lib.current.stage;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
		stage.removeEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
		stage.removeEventListener(Event.RESIZE, _onResize);
		stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		#if mobile
		screen.removeEventListener(TouchEvent.TOUCH_BEGIN, _onTouchDown);
		screen.removeEventListener(TouchEvent.TOUCH_MOVE, _onTouchMove);
		screen.removeEventListener(TouchEvent.TOUCH_END, _onTouchUp);
		#else
		screen.removeEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
		screen.removeEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
		screen.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
		#end
		
		screen.removeChild(_wh);
		screen.removeChild(_fps);
		for (i in 0...blocks.length) stage.removeChild(blocks[i]);
		
		//stage.removeChildAt(0);
		stage.removeChild(this);
	}
	
	public static function addBlock(block:Sprite):Sprite {
		var i = blocks.push(block) - 1;
		Lib.current.stage.addChild(blocks[i]);
		return block;
	}
	
	public static function delBlock(block:Sprite):Void {
		blocks.remove(block);
		Lib.current.stage.removeChild(block);
	}
	
	function onEnterFrame(e:Event):Void {}
	
	function _onResize(?e:Event):Void {
		//var stage = Lib.current.stage;
		//#if debug
		_wh.text = ""+stage.numChildren+" | "+stage.stageWidth+"x"+stage.stageHeight;
		_wh.x = stage.stageWidth - _wh.width;
		_wh.y = stage.stageHeight - _wh.height;
		_fps.y = stage.stageHeight - _fps.height;
		//#end
		screen.graphics.beginFill(0, 0);
		screen.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		onResize();
	}
	
	function _onKeyDown(e:KeyboardEvent):Void {
		//trace("key: " + e.keyCode);
		e.preventDefault();
		keys[e.keyCode] = true;
		onKeyDown(e.keyCode);
	}

	function _onKeyUp(e:KeyboardEvent):Void {
		e.preventDefault();
		keys[e.keyCode] = false;
		onKeyUp(e.keyCode);
	}
	
	function _onMouseDown(e:MouseEvent):Void {
		pointers[0] = {
			startX: e.stageX,
			startY: e.stageY,
			x: e.stageX,
			y: e.stageY,
			isDown: true,
			used: true
		};
		onMouseDown(0);
	}
	
	function _onMouseMove(e:MouseEvent):Void {
		pointers[0].x = e.stageX;
		pointers[0].y = e.stageY;
		pointers[0].used = true;
		onMouseMove(0);
	}

	function _onMouseUp(e:MouseEvent):Void {
		pointers[0].x = e.stageX;
		pointers[0].y = e.stageY;
		pointers[0].isDown = false;
		onMouseUp(0);
	}
	
	function _onTouchDown(e:TouchEvent):Void {
		var id = e.touchPointID;
		if (id > 9) return;
		pointers[id] = {
			startX: e.stageX,
			startY: e.stageY,
			x: e.stageX,
			y: e.stageY,
			isDown: true,
			used: true
		};
		onMouseDown(id);
	}
	
	function _onTouchMove(e:TouchEvent):Void {
		var id = e.touchPointID;
		if (id > 9) return;
		pointers[id].x = e.stageX;
		pointers[id].y = e.stageY;
		//pointers[id].used = true;
		onMouseMove(id);
	}

	function _onTouchUp(e:TouchEvent):Void {
		var id = e.touchPointID;
		if (id > 9) return;
		pointers[id].x = e.stageX;
		pointers[id].y = e.stageY;
		pointers[id].isDown = false;
		onMouseUp(id);
	}
	
	function onResize():Void {}
	
	function onKeyDown(key:Int):Void {}
	
	function onKeyUp(key:Int):Void {}
	
	function onMouseDown(id:Int):Void {}
	
	function onMouseMove(id:Int):Void {}

	function onMouseUp(id:Int):Void {}
	
}
