package;

import openfl.display.Sprite;
import openfl.net.SharedObject;
import openfl.net.FileReference;
//import openfl.net.FileFilter;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.Lib;
import Interfaces.Mode;
import Types;

class Editor extends Screen {
	
	public var theme:Theme;
	var themeLight = {
		bg: 0xF0F0F0,
		color: 0x303030,
		hover: 0xD05050,
		hoverLine: 0x905050,
		hoverParent: 0x909050,
		lines: [0x908B85, 0x7E8176, 0x6F6065, 0x967C7F],
		panel: { on: 0xDDDDDD, off: 0xC0C0C0 },
		grid: 0xD0D0D0,
		hint: 0xFFFFFF
	}
	var themeDark = {
		bg: 0x303030,
		color: 0xC0C0C0,
		hover: 0xD05050,
		hoverLine: 0x905050,
		hoverParent: 0x909050,
		lines: [0x2C6E7A, 0x4E8693, 0x6F8D8D, 0x238F99],
		panel: { on: 0x202020, off: 0x404040 },
		grid: 0x404040,
		hint: 0x0
	}
	var sharedObject = SharedObject.getLocal("animo");
	var DEF_FRAME:Frame = {edges: []};
	var framePanel:FramePanel;
	var menuPanel:MenuPanel;
	var editMode:EditMode;
	var animMode:AnimMode;
	var playMode:PlayMode;
	var mode:Mode;
	
	public var playState = 0;
	public var isTouch = false;
	public var isGrid = true;
	public var DEF_SCALE = 10;
	public var scale = 10;
	public var basis:Basis;
	public var frameId = -1;
	public var grid = new Sprite();
	public var prevView = new Sprite();
	public var sbasis = new Sprite();
	public var sInfo = new Sprite();
	public var visual = new Sprite();
	public var pointHint = new Sprite();
	
	public function new() {
		super();
	}
	
	public function init():Void {
		var stage = Lib.current.stage;
		
		#if html5
		var window = js.Browser.window;
		window.ondragenter = function(e) {
			e.preventDefault();
		};
		window.ondragover = function(e) {
			e.preventDefault();
		};
		window.ondrop = drop;
		isTouch = untyped __js__('"ontouchstart" in window');
		#elseif mobile
		isTouch = true;
		#end
		
		var sets = sharedObject.data;
		setTheme(sets.theme);
		
		editMode = new EditMode(this);
		animMode = new AnimMode(this);
		playMode = new PlayMode(this);
		mode = editMode;
		
		framePanel = new FramePanel(this);
		framePanel.init();
		menuPanel = new MenuPanel(this);
		menuPanel.init();
		resetBasis();
		basis = Loader.loadExample();
		resetBoard();
		
		addChild(grid);
		addChild(prevView);
		prevView.alpha = 0.25;
		addChild(sbasis);
		addChild(sInfo);
		addChild(visual);
		addChild(pointHint);
		
		addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightDown);
		addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightUp);
		
		addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
			Screen.addBlock(menuPanel);
			Screen.addBlock(framePanel);
		});
	}
	
	override function onResize():Void {
		onMouseMove(0);
		mode.update();
		framePanel.update();
	}
	
	override function onMouseDown(id:Int):Void {
		if (keys[Keyboard.CONTROL] || keys[Keyboard.ALTERNATE]) {
			onRightDown();
			return;
		}
		framePanel.mouseChildren = false;
		framePanel.mouseEnabled = false;
		menuPanel.mouseChildren = false;
		menuPanel.mouseEnabled = false;
		mode.onMouseDown(0);
	}
	
	override function onMouseMove(id:Int):Void {
		mode.onMouseMove(0);
	}
	
	override function onMouseUp(id:Int):Void {
		if (keys[Keyboard.CONTROL] || keys[Keyboard.ALTERNATE]) {
			onRightUp();
			return;
		}
		framePanel.mouseChildren = true;
		framePanel.mouseEnabled = true;
		menuPanel.mouseChildren = true;
		menuPanel.mouseEnabled = true;
		mode.onMouseUp(0);
	}
	
	function onRightDown(?e:MouseEvent):Void {
		mode.onRightDown(0);
	}
	function onRightUp(?e:MouseEvent):Void {
		mode.onRightUp(0);
	}
	
	override function onEnterFrame(e:Event):Void {
		mode.onEnterFrame();
	}
	
	override function onKeyDown(key:Int):Void {
		var k = Keyboard;
		
		if (keys[k.CONTROL] || keys[224] || keys[15]) {
			
			if (key == k.Z || key == 1103) {
				if (!keys[k.SHIFT]) mode.undo();
				else mode.redo();
			}
			if (key == k.Y || key == 1085) mode.redo();
			if (key == k.S || key == 1099) save(basis);
			
			if (key == k.UP) addFrame();
			if (key == k.DOWN) delFrame();
			if (key == k.LEFT) prevFrame();
			if (key == k.RIGHT) nextFrame();
		}
		
		if (key == k.O || key == 1097) browse();
		if (key == k.N || key == 1090) resetAlert();
		if (key == k.T || key == 1077) {
			if (theme == themeLight) setTheme(2);
			else setTheme(1);
			mode.update();
			menuPanel.update();
			framePanel.update(true);
		}
		
		if (key == k.G || key == 1087) {
			isGrid = !isGrid;
			mode.update();
		}
		
		if (key == k.ENTER || key == k.SPACE) {
			if (keys[k.ALTERNATE]) togglePlay(3);
			else if (keys[k.SHIFT]) togglePlay(2);
			else togglePlay();
		}
		
		if (key == k.NUMBER_1) {
			scale = 1;
			mode.update();
		}
		if (key == k.NUMBER_2) {
			scale = 2;
			mode.update();
		}
		if (key == k.NUMBER_0) {
			scale = DEF_SCALE;
			mode.update();
		}
		if (key == k.MINUS || key == k.NUMPAD_SUBTRACT || key == 173) {
			if (keys[k.SHIFT]) scale--;
			scale--;
			if (scale < 1) scale = 1;
			mode.update();
		}
		if (key == k.EQUAL || key == k.NUMPAD_ADD) {
			if (keys[k.SHIFT]) scale++;
			scale++;
			if (scale > 100) scale = 100;
			mode.update();
		}
	}
	
	public function sendCommand(keys:Array<Int>):Void {
		if (keys.length < 1) return;
		for (k in keys) this.keys[k] = true;
		var id = keys.length-1;
		onKeyDown(keys[id]);
		for (k in keys) this.keys[k] = false;
	}
	
	public function setMode(value:Int):Void {
		switch(value) {
			case 1: mode = editMode;
			case 2: mode = animMode;
			case 3: mode = playMode;
		}
		mode.select();
	}
	
	public function setTheme(id:Int):Void {
		var newTheme:Theme;
		switch(id) {
			case 1: newTheme = themeLight;
			case 2: newTheme = themeDark;
			default: newTheme = themeLight;
		}
		if (theme == newTheme) return;
		sharedObject.data.theme = id;
		sharedObject.flush(); //save
		theme = newTheme;
		Lib.current.stage.color = theme.bg;
	}
	
	public function setInfo(plen:Int, elen:Int):Void {
		var txt = new Text("Points: "+plen+"\nEdges: "+elen);
		if (sInfo.numChildren > 0) sInfo.removeChildAt(0);
		sInfo.addChild(txt);
		sInfo.x = 5;
		sInfo.y = 5 + txt.height/2;
	}
	
	public function setPointHint(p:Point):Void {
		var x = Math.round(p.x * 100) / 100;
		var y = Math.round(p.y * 100) / 100;
		var txt = new Text(x+","+y+" | "+p.d);
		#if debug txt.text+=" "+p.edges; #end
		var g = pointHint.graphics;
		g.clear();
		g.beginFill(theme.hint, 0.5);
		g.drawRect(0, 0, txt.width, txt.height);
		if (pointHint.numChildren > 0) pointHint.removeChildAt(0);
		pointHint.addChild(txt);
		pointHint.x = p.x * scale + sbasis.x - txt.width/2;
		pointHint.y = p.y * scale + sbasis.y - txt.height;
	}
	
	public function togglePlay(value=1):Void {
		if (basis.frames.length < 2) return;
		playState = playState != 0 ? 0 : value;
		
		if (playState != 0) {
			
			setMode(3);
			for (id in 0...basis.frames.length) {
				playMode.reload(id);
			}
			if (frameId < 0) frameId = 0;
			visual.visible = false;
			pointHint.visible = false;
			prevView.graphics.clear();
			framePanel.update();
			if (playState == 3) playMode.createGif();
			
		} else {
			visual.visible = true;
			playMode.clear();
			resetBoard();
		}
	}
	
	public function updateFramePanel():Void {
		framePanel.update();
	}
	
	public function addFrame():Void {
		var frames = basis.frames;
		frameId++;
		frames.insert(frameId, copyFrame(frameId-1));
		framePanel.select();
	}
	
	public function addFrameLast():Void {
		var frames = basis.frames;
		if (frameId > -1) frames.push(copyFrame(frameId));
		else frames.push(copyFrame(frames.length-1));
		frameId = frames.length-1;
		framePanel.select();
	}
	
	public function delFrame():Void {
		if (frameId == -1) return;
		basis.frames.splice(frameId, 1);
		frameId--;
		framePanel.select();
	}
	
	public function prevFrame():Void {
		if (frameId < 0) return;
		frameId--;
		framePanel.select();
	}
	
	public function nextFrame():Void {
		if (frameId > basis.frames.length-2) return;
		frameId++;
		framePanel.select();
	}
	
	function copyFrame(id):Frame {
		if (id < 0) return DEF_FRAME;
		var orig = basis.frames[id];
		var f:Frame = {edges: []};
		
		for (i in 0...orig.edges.length) {
			if (orig.edges[i] == null) continue;
			f.edges[i] = Reflect.copy(orig.edges[i]);
		}
		return f;
	}
	
	function save(basis:Basis):Void {
		var json = haxe.Json.stringify(basis, null, "	");
		#if html5
		var blob = new js.html.Blob([json], {
			type: "application/json"
		});
		var url = js.html.URL.createObjectURL(blob);
		var a = js.Browser.document.createElement("a");
		untyped a.download = basis.name+".json";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		js.Browser.document.body.appendChild(a);
		a.click();
		js.Browser.document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#else
		var fr = new FileReference();
		fr.save(json, basis.name+'.json');
		#end
	}
	
	function browse():Void {
		#if html5
		var input = js.Browser.document.createElement("input");
		input.style.visibility = "hidden";
		input.setAttribute("type", "file");
		input.id = "browse";
		input.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		input.onchange = function() {
			untyped var file = input.files[0];
			var reader = new js.html.FileReader();
			reader.onload = function(e) {
				basis = haxe.Json.parse(e.target.result);
				clearHistory();
				resetBoard();
				js.Browser.document.body.removeChild(input);
			}
			reader.readAsText(file);
		}
		js.Browser.document.body.appendChild(input);
		input.click();
		#else
		var fr = new FileReference();
		//var filter = new FileFilter("Cool Files", "*.hx;*.txt;*.png;*.json");
		fr.browse(); //[filter]
		fr.addEventListener(Event.SELECT, function(e:Event) {
			fr.addEventListener(Event.COMPLETE, function(e:Event) {
				basis = haxe.Json.parse(fr.data.toString());
				clearHistory();
				resetBoard();
			});
			fr.load();
		});
		#end
	}
	
	#if html5
	function drop(e:js.html.DragEvent):Void {
		var reader = new js.html.FileReader();
		reader.onload = function(event) {
			basis = haxe.Json.parse(event.target.result);
			clearHistory();
			resetBoard();
		}
		e.preventDefault();
		reader.readAsText(e.dataTransfer.files[0]);
	}
	#end
	
	function resetAlert():Void {
		var stage = Lib.current.stage;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
		
		var alert = new Sprite();
		var g = alert.graphics;
		g.beginFill(theme.hint, 0.5);
		g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		visual.visible = false;
		
		var txt = new Text(Lang.get("reset_warning"));
		txt.format.size = 30;
		txt.update();
		txt.x = stage.stageWidth/2 - txt.width/2;
		txt.y = stage.stageHeight/2 - txt.height*2;
		alert.addChild(txt);
		
		var yes = new Text(Lang.get("yes"));
		yes.format.size = 30;
		yes.update();
		yes.x = stage.stageWidth/2 - yes.width*2;
		yes.y = stage.stageHeight/2;
		
		var no = new Text(Lang.get("no"));
		no.format.size = 30;
		no.update();
		no.x = stage.stageWidth/2 + no.width;
		no.y = stage.stageHeight/2;
		
		function onClick(e:MouseEvent):Void {
			if (e.target == yes) resetBasis();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
			yes.removeEventListener(MouseEvent.CLICK, onClick);
			no.removeEventListener(MouseEvent.CLICK, onClick);
			stage.removeChild(alert);
			visual.visible = true;
			stage.focus = stage;
		}
		yes.addEventListener(MouseEvent.CLICK, onClick);
		no.addEventListener(MouseEvent.CLICK, onClick);
		
		alert.addChild(yes);
		alert.addChild(no);
		stage.addChild(alert);
	}
	
	function resetBasis():Void {
		basis = {
			v: 1,
			name: "Example",
			delay: 10,
			points: [
				{x: 0, y: 0, d: 0, edges: []}
			],
			edges: [],
			frames: []
		}
		
		clearHistory();
		resetBoard();
	}
	
	function clearHistory():Void {
		editMode.clearHistory();
		animMode.clearHistory();
	}
	
	function resetBoard():Void {
		if (frameId > basis.frames.length-2) frameId = -1;
		mode.update();
		prevView.graphics.clear();
		framePanel.select(true);
		menuPanel.update();
	}
	
}
