package;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.Lib;
import Types.Frame;

class FramePanel extends Sprite {
	
	var btns:Array<Sprite> = [];
	var btnW = 12;
	var btnH = 20;
	var current = -2;
	var numBtns = 3;
	var ctx:Editor;
	
	public function new(ctx:Editor) {
		this.ctx = ctx;
		super();
	}
	
	public function init():Void {
		if (ctx.isTouch) {
			btnW += 2;
			btnW *= 2;
			btnH *= 2;
		}
		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onOut);
		onOut();
	}
	
	function onOver(?e:MouseEvent):Void {
		alpha = 1;
	}
	
	function onOut(?e:MouseEvent):Void {
		alpha = 0.75;
	}
	
	public function select(force=false):Void {
		update(force);
		if (ctx.frameId == -1) ctx.setMode(1);
		else ctx.setMode(2);
	}
	
	public function update(force=false):Void {
		var stage = Lib.current.stage;
		var len = ctx.basis.frames.length;
		x = stage.stageWidth/2 - (len+numBtns) * btnW / 2;
		y = stage.stageHeight - btnH - stage.stageHeight/50;
		
		if (current == ctx.frameId && !force) return;
		current = ctx.frameId;
		
		for (i in 0...btns.length) {
			btns[i].removeEventListener(MouseEvent.CLICK, onClick);
			removeChild(btns[i]);
		}
		btns = [];
		
		var theme = ctx.theme;
		
		for (i in 0...len+numBtns) {
			btns[i] = new Sprite();
			var g = btns[i].graphics;
			
			if (i == current+1) g.beginFill(theme.panel.on);
			else g.beginFill(theme.panel.off);
			
			g.lineStyle(1, theme.color);
			g.drawRect(0, 0, btnW, btnH);
			btns[i].x = i * btnW;
			
			btns[i].addEventListener(MouseEvent.CLICK, onClick);
			addChild(btns[i]);
		}
		
		var g = btns[0].graphics; //basic frame
		g.beginFill(theme.panel.on);
		g.lineStyle(1, theme.color);
		g.drawRect(2, (btnH-btnW)/2, btnW-2*2, btnW);
		
		g = btns[len+1].graphics; //add button
		g.beginFill(theme.color);
		g.moveTo(btnW/2, (btnH-btnW)/2);
		g.lineTo(btnW/2, btnH-(btnH-btnW)/2);
		g.moveTo(2, btnH/2);
		g.lineTo(btnW-2, btnH/2);
		
		g = btns[len+2].graphics; //play button
		g.beginFill(theme.panel.on);
		if (ctx.playState == 0) {
			g.moveTo(2, (btnH-btnW)/2);
			g.lineTo(btnW-2, btnH/2);
			g.lineTo(2, btnH-(btnH-btnW)/2);
			g.lineTo(2, (btnH-btnW)/2);
		} else {
			g.moveTo(btnW/4, (btnH-btnW)/2);
			g.lineTo(btnW/4, btnH-(btnH-btnW)/2);
			g.moveTo(btnW-btnW/4, (btnH-btnW)/2);
			g.lineTo(btnW-btnW/4, btnH-(btnH-btnW)/2);
		}
	}
	
	function onClick(e:MouseEvent):Void {
		var btn = cast(e.target, Sprite);
		var id = btns.indexOf(btn);
		
		if (id == btns.length-2) ctx.addFrameLast();
		else if (id == btns.length-1) ctx.togglePlay();
		else {
			ctx.frameId = id - 1;
			select();
		}
	}
	
}
