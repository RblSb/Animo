package;

import Types;

interface Mode {
	function select():Void;
	function clearHistory():Void;
	function undo():Void;
	function redo():Void;
	function onMouseDown(id:Int):Void;
	function onMouseMove(id:Int):Void;
	function onMouseUp(id:Int):Void;
	function onRightDown(id:Int):Void;
	function onRightUp(id:Int):Void;
	function onEnterFrame():Void;
	function update():Void;
}
