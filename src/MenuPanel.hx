package;

import openfl.net.URLRequest;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.Lib;

class MenuPanel extends Sprite {
	
	var titles = ["Animo", "file", "edit", "view"];
	var menus:Array<Array<String>> = [
		["settings", "help", "github", "about"],
		["new", "open", "save", "file_sets", "write_gif"],
		["undo", "redo", "add_frame", "delete_frame", "next_frame", "prev_frame"],
		["play_pause", "grid", "toggle_theme", "reset_scale"]
	];
	var hotkeys:Array<Array<String>> = [
		["","","",""],
		["N","O","^S","","Alt-Enter"],
		["^Z","^Y","^Up","^Down","^Right","^Left"],
		["Enter","G","T","0"]
	];
	var btns:Array<Sprite> = [];
	var list:Array<Sprite> = [];
	var listX:Float;
	var titleId = -1;
	var menuId = -1;
	var offset = 20.0;
	var ctx:Editor;
	
	public function new(ctx:Editor) {
		this.ctx = ctx;
		super();
	}
	
	public function init():Void {
		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onOut);
		onOut();
	}
	
	function onOver(?e:MouseEvent):Void {
		alpha = 1;
	}
	
	function onOut(?e:MouseEvent):Void {
		alpha = 0.75;
		if (titleId != -1) {
			titleId = -1;
			menuId = -1;
			update();
		}
	}
	
	public function update():Void {
		var stage = Lib.current.stage;
		graphics.clear();
		
		for (i in 0...btns.length) {
			btns[i].removeEventListener(MouseEvent.ROLL_OVER, onOverTitle);
			btns[i].removeEventListener(MouseEvent.CLICK, onClickTitle);
			removeChild(btns[i]);
		}
		btns = [];
		var theme = ctx.theme;
		var offx = offset;
		
		for (i in 0...titles.length) {
			var txt = new Text(Lang.get(titles[i]), 0, 0);
			txt.format.color = theme.color;
			txt.update();
			var btnW = txt.width;
			var btnH = txt.height;
			
			btns[i] = new Sprite();
			var g = btns[i].graphics;
				
			if (i == titleId) {
				g.beginFill(theme.panel.on);
				listX = offx - offset/2;
			} else g.beginFill(theme.panel.off, 0);
			
			g.drawRect(-offset/2, 0, btnW+offset, btnH);
			
			btns[i].x = offx;
			btns[i].y = 0;
			btns[i].addEventListener(MouseEvent.ROLL_OVER, onOverTitle);
			btns[i].addEventListener(MouseEvent.CLICK, onClickTitle);
			btns[i].addChild(txt);
			addChild(btns[i]);
			
			offx += btnW + offset;
		}
		
		var btnH = new Text("M").height;
		graphics.beginFill(theme.panel.off);
		graphics.drawRect(0, 0, offx, btnH);
		graphics.moveTo(offx, btnH);
		graphics.lineTo(offx + btnH, 0);
		graphics.lineTo(offx, 0);
		
		showMenu();
		if (titleId == -1) stage.focus = stage;
	}
	
	function onClickTitle(e:MouseEvent):Void {
		var btn = cast(e.currentTarget, Sprite);
		var id = btns.indexOf(btn);
		if (titleId == id) titleId = -1;
		else titleId = id;
		menuId = -1;
		update();
	}
	
	function onOverTitle(e:MouseEvent):Void {
		if (titleId == -1) return;
		var btn = cast(e.currentTarget, Sprite);
		var id = btns.indexOf(btn);
		if (titleId != id) {
			titleId = id;
			menuId = -1;
			update();
		}
	}
	
	public function showMenu():Void {
		for (i in 0...list.length) {
			list[i].removeEventListener(MouseEvent.ROLL_OVER, onOverMenu);
			list[i].removeEventListener(MouseEvent.CLICK, onClickMenu);
			removeChild(list[i]);
		}
		list = [];
		if (titleId < 0) return;
		
		var theme = ctx.theme;
		var offx = listX;
		var offy = new Text("M").height;
		var menu = menus[titleId];
		var hotkeys = hotkeys[titleId];
		
		var maxW = 0.0;
		
		for (i in 0...menu.length) {
			var txt = new Text(Lang.get(menu[i]));
			txt.format.color = theme.color;
			txt.update();
			var ht = new Text(hotkeys[i]);
			//trace(ht.width, ht.height);
			
			var btnW = txt.width + offset + ht.width;
			var btnH = txt.height;
			if (maxW < btnW) maxW = btnW;
			
			list[i] = new Sprite();
			list[i].x = offx;
			list[i].y = offy;
			list[i].addEventListener(MouseEvent.ROLL_OVER, onOverMenu);
			list[i].addEventListener(MouseEvent.CLICK, onClickMenu);
			list[i].addChild(txt);
			list[i].addChild(ht);
			addChild(list[i]);
			
			offy += btnH;
		}
		
		for (i in 0...menu.length) {
			var ht = list[i].getChildAt(1);
			ht.x = maxW - ht.width;
			var h = list[i].getChildAt(0).height + 1;
			
			var g = list[i].graphics;
			if (menuId == i) g.beginFill(theme.panel.off);
			else g.beginFill(theme.panel.on);
			g.drawRect(0, -0.5, maxW, h);
		}
	}
	
	function onOverMenu(?e:MouseEvent):Void {
		var item = cast(e.currentTarget, Sprite);
		var id = list.indexOf(item);
		if (menuId != id) {
			menuId = id;
			showMenu();
		}
	}
	
	function onClickMenu(e:MouseEvent):Void {
		var item = cast(e.currentTarget, Sprite);
		var id = list.indexOf(item);
		action(id);
		titleId = -1;
		menuId = -1;
		update();
	}
	
	function action(id:Int):Void {
		var keys:Array<Int> = [];
		var k = Keyboard;
		switch(titleId) {
			case 0:
				switch(id) {
					case 1:
						var link = "https://github.com/RblSb/Animo/blob/master/README";
						if (Lang.iso == "ru") {
							link += "." + Lang.iso;
						}
						link += ".md";
						Lib.getURL(new URLRequest(link));
					case 2:
						Lib.getURL(new URLRequest("https://github.com/RblSb/Animo"));
				}
			case 1:
				switch(id) {
					case 0: keys = [k.N];
					case 1: keys = [k.O];
					case 2: keys = [k.CONTROL, k.S];
					case 4: keys = [k.ALTERNATE, k.ENTER];
				}
			case 2:
				switch(id) {
					case 0: keys = [k.CONTROL, k.Z];
					case 1: keys = [k.CONTROL, k.Y];
					case 2: keys = [k.CONTROL, k.UP];
					case 3: keys = [k.CONTROL, k.DOWN];
					case 4: keys = [k.CONTROL, k.RIGHT];
					case 5: keys = [k.CONTROL, k.LEFT];
				}
			case 3:
				switch(id) {
					case 0: keys = [k.ENTER];
					case 1: keys = [k.G];
					case 2: keys = [k.T];
					case 3: keys = [k.NUMBER_0];
				}
		}
		ctx.sendCommand(keys);
	}
	
}
