package;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.Lib;
import Interfaces.Mode;
import Types;

class AnimMode implements Mode {
	
	var undo_h:Array<AHistory> = [];
	var redo_h:Array<AHistory> = [];
	var HISTORY_MAX = 30;
	var points:Array<Point> = []; //cache
	var edges:Array<Edge> = [];
	var closePoint = -1;
	var angleDiff = 0;
	var CLOSE_MAX = 7.0;
	var ctx:Editor;
	
	public function new(ctx:Editor) {
		this.ctx = ctx;
		if (ctx.isTouch) CLOSE_MAX *= 2;
	}
	
	public function select():Void {
		ctx.prevView.visible = true;
		reload(ctx.frameId);
		update();
	}
	
	public function reload(frameId:Int):Void {
		var basis = ctx.basis;
		var frame = basis.frames[frameId];
		var parents:Array<Int> = [];
		points = [];
		
		for (i in 0...basis.points.length) {
			if (basis.points[i] == null) continue;
			
			points[i] = {}; //cache
			points[i].x = basis.points[i].x;
			points[i].y = basis.points[i].y;
			points[i].edges = basis.points[i].edges; //link
			points[i].d = basis.points[i].d;
			if (points[i].d == 0) parents.push(i);
		}
		
		for (i in 0...basis.edges.length) {
			if (basis.edges[i] == null) continue;
			
			if (frame.edges[i] == null) {
				//angle diff with basis edges
				frame.edges[i] = {ang: 0};
				
				var p = basis.edges[i].p1;
				if (p > basis.edges[i].p2) p = basis.edges[i].p2;
				var p_edges = getEdges(points[p], -1);
				if (p_edges.length == 1) {
					var eid = p_edges[0];
					frame.edges[i].ang = frame.edges[eid].ang;
				}
			}
			
			edges[i] = {}; //cache
			edges[i].ang = basis.edges[i].ang + frame.edges[i].ang;
		}
		
		for (pid in parents) {
			var childs = getChilds(points[pid]);
			for (id in childs) {
				transform(frameId, id);
			}
		}
	}
	
	function addHistory(h:AHistory):Void {
		undo_h.push(h);
		if (undo_h.length > HISTORY_MAX) undo_h.shift();
		redo_h = [];
	}
	
	public function clearHistory():Void {
		undo_h = [];
		redo_h = [];
	}
	
	public function undo():Void {
		var hid = undo_h.length - 1;
		if (hid == -1) return;
		var basis = ctx.basis;
		var points = basis.points;
		var edges = basis.edges;
		var h = undo_h[hid];
		var h2 = redo_h;
		var cmd = h.cmd;
		
		switch(cmd) {
		case "set":
			h2.push({
				cmd: cmd,
				fid: h.fid,
				pid: h.pid,
				ang: -h.ang,
			});
			transform(h.fid, h.pid, h.ang);
			ctx.frameId = h.fid;
			ctx.updateFramePanel();
		}
		undo_h.pop();
		update();
		if (!ctx.isTouch) onMouseMove(0);
	}
	
	public function redo():Void {
		var hid = redo_h.length - 1;
		if (hid == -1) return;
		var basis = ctx.basis;
		var points = basis.points;
		var h = redo_h[hid];
		var h2 = undo_h;
		var cmd = h.cmd;
		
		switch(cmd) {
		case "set":
			h2.push({
				cmd: cmd,
				fid: h.fid,
				pid: h.pid,
				ang: -h.ang
			});
			transform(h.fid, h.pid, h.ang);
			ctx.frameId = h.fid;
			ctx.updateFramePanel();
		}
		redo_h.pop();
		update();
		if (!ctx.isTouch) onMouseMove(0);
	}
	
	static inline function dist(x:Float, y:Float, x2:Float, y2:Float):Float {
		return Math.sqrt(Math.pow(x - x2, 2) + Math.pow(y - y2, 2));
	}
	
	function closestPoint(x:Float, y:Float):Int {
		var sbasis = ctx.sbasis;
		var scale = ctx.scale;
		var min = CLOSE_MAX;
		var id = -1;
		
		for (i in 0...points.length) {
			if (points[i] == null) continue;
			var px = points[i].x * scale + sbasis.x;
			var py = points[i].y * scale + sbasis.y;
			var d = dist(x, y, px, py);
			if (d < min) {
				min = d;
				id = i;
			}
		}
		return id;
	}
	
	public function onMouseDown(id:Int):Void {
		if (ctx.isTouch) {
			ctx.pointers[id].isDown = false;
			onMouseMove(id);
			ctx.pointers[id].isDown = true;
		}
		if (closePoint != -1) ctx.pointHint.visible = false;
	}
	
	public function onMouseMove(id:Int):Void {
		var pointer = ctx.pointers[id];
		var isGrid = ctx.isGrid;
		var sbasis = ctx.sbasis;
		var basis = ctx.basis;
		var scale = ctx.scale;
		var theme = ctx.theme;
		
		var cp = closestPoint(pointer.x, pointer.y);
		var g = ctx.visual.graphics;
		
		if (!pointer.isDown) { //select point
			
			if (closePoint == cp) return;
			closePoint = cp;
			g.clear();
			
			if (cp != -1) {
				var x = points[cp].x * scale + sbasis.x;
				var y = points[cp].y * scale + sbasis.y;
				
				g.lineStyle(3, theme.hover);
				g.drawCircle(x, y, 4);
				ctx.setPointHint(points[cp]);
				ctx.pointHint.visible = true;
				
			} else ctx.pointHint.visible = false;
			
		} else if (closePoint != -1) { //move point
			
			var edges = getEdges(points[closePoint], -1);
			if (edges.length != 1) return;
			var edge = edges[0];
			var parents = getParents(points[closePoint]);
			if (parents.length != 1) return;
			var id = parents[0];
			
			var x = points[closePoint].x * scale + sbasis.x;
			var y = points[closePoint].y * scale + sbasis.y;
			var x2 = points[id].x * scale + sbasis.x;
			var y2 = points[id].y * scale + sbasis.y;
			var dist = dist(x, y, x2, y2);
			
			g.clear();
			g.lineStyle(1, theme.hoverLine);
			g.drawCircle(x2, y2, dist);
			g.lineStyle(3, theme.hoverParent);
			g.drawCircle(x2, y2, 4);
			g.lineStyle(3, theme.hoverLine);
			g.drawCircle(x, y, 4);
			
			var ang = Math.atan2(pointer.y - y2, pointer.x - x2);
			var angX = Math.cos(ang) * dist;
			var angY = Math.sin(ang) * dist;
			
			g.moveTo(x2, y2);
			g.lineTo(x2 + angX, y2 + angY);
			g.lineStyle(3, theme.color);
			g.drawCircle(x2 + angX, y2 + angY, 1);
			
			//fix (сейв в переменную один раз для истории и визуализации)
			var frame = basis.frames[ctx.frameId];
			var oldAng = basis.edges[edge].ang + frame.edges[edge].ang;
			angleDiff = Math.round((ang - oldAng) * 180 / Math.PI);
			//transform(ctx.frameId, edge.p1 or p2);
			//update();
		}
	}
	
	public function onMouseUp(id:Int):Void {
		ctx.visual.graphics.clear();
		if (closePoint == -1) return;
		
		transform(ctx.frameId, closePoint, angleDiff);
		addHistory({
			cmd: "set",
			fid: ctx.frameId,
			pid: closePoint,
			ang: -angleDiff
		});
		closePoint = -1;
		angleDiff = 0;
		update();
		if (!ctx.isTouch) onMouseMove(id);
	}
	
	public function onRightDown(id:Int):Void {}
	public function onRightUp(id:Int):Void {}
	
	function transform(frameId:Int, p:Int, angDiff=0.0, addX=0.0, addY=0.0):Void {
		var p1 = points[p]; //current point
		if (p1 == null) return;
		var parents = getParents(p1);
		if (parents.length != 1) return;
		var pp = parents[0]; //parent id
		var p2 = points[pp]; //parent point
		
		var basis = ctx.basis;
		var frame = basis.frames[frameId];
		
		var p_edges = getEdges(p1, -1); //parent-child edge
		if (p_edges.length != 1) return;
		var eid = p_edges[0];
		
		frame.edges[eid].ang += angDiff / 180 * Math.PI;
		var ang = basis.edges[eid].ang + frame.edges[eid].ang;
		edges[eid].ang = ang;
		
		var oldX = p1.x; //for rotate offsets
		var oldY = p1.y;
		p1.x += addX;
		p1.y += addY;
		var rp = rotate(p1, p2, ang);
		p1.x = rp.x;
		p1.y = rp.y;
		
		var childs = getChilds(p1);
		for (id in childs) {
			transform(frameId, id, angDiff, p1.x - oldX, p1.y - oldY);
		}
	}
	
	function rotate(p1:Point, p2:Point, ang:Float):Point {
		var dist = dist(p1.x, p1.y, p2.x, p2.y);
		var x = p2.x + Math.cos(ang) * dist;
		var y = p2.y + Math.sin(ang) * dist;
		return {x: x, y: y};
	}
	
	function getEdges(p:Point, depth:Int):Array<Int> {
		var edges:Array<Int> = [];
		for (eid in p.edges) {
			var e = ctx.basis.edges[eid];
			if (points[e.p1].d == p.d + depth ||
				points[e.p2].d == p.d + depth) edges.push(eid);
		}
		return edges;
	}
	
	function getParents(p:Point):Array<Int> {
		var parents:Array<Int> = [];
		for (eid in p.edges) {
			var e = ctx.basis.edges[eid];
			if (points[e.p1].d == p.d-1) parents.push(e.p1);
			if (points[e.p2].d == p.d-1) parents.push(e.p2);
		}
		return parents;
	}
	
	function getChilds(p:Point):Array<Int> {
		var childs:Array<Int> = [];
		for (eid in p.edges) {
			var e = ctx.basis.edges[eid];
			if (points[e.p1].d == p.d+1) childs.push(e.p1);
			if (points[e.p2].d == p.d+1) childs.push(e.p2);
		}
		return childs;
	}
	
	public function onEnterFrame():Void {}
	
	function transformView(p:Int, addX=0.0, addY=0.0):Void {
		var p1 = points[p]; //current point
		if (p1 == null) return;
		var parents = getParents(p1);
		if (parents.length != 1) return;
		var pp = parents[0]; //parent id
		var p2 = points[pp]; //parent point
		
		var basis = ctx.basis;
		var frame = basis.frames[ctx.frameId];
		
		var p_edges = getEdges(p1, -1); //parent-child edge
		if (p_edges.length != 1) return;
		var eid = p_edges[0];
		
		var oldX = p1.x; //rotate offsets
		var oldY = p1.y;
		p1.x += addX;
		p1.y += addY;
		var rp = rotate(p1, p2, edges[eid].ang);
		p1.x = rp.x;
		p1.y = rp.y;
		
		var childs = getChilds(p1);
		for (id in childs) {
			transformView(id, p1.x - oldX, p1.y - oldY);
		}
	}
	
	public function update():Void {
		drawPrevFrame();
		var stage = Lib.current.stage;
		var theme = ctx.theme;
		var isGrid = ctx.isGrid;
		var grid = ctx.grid;
		var basis = ctx.basis;
		var sbasis = ctx.sbasis;
		var g = sbasis.graphics;
		var scale = ctx.scale;
		g.clear();
		
		var cslen = theme.lines.length;
		var csi = 0;
		for (e in basis.edges) {
			if (e == null) continue;
			g.lineStyle(3, theme.lines[csi%cslen]);
			g.moveTo(points[e.p1].x * scale, points[e.p1].y * scale);
			g.lineTo(points[e.p2].x * scale, points[e.p2].y * scale);
			csi++;
		}
		
		g.lineStyle(3, theme.color);
		for (p in points) {
			if (p == null) continue;
			g.drawCircle(p.x * scale, p.y * scale, 1);
		}
		
		sbasis.x = 0;
		sbasis.y = 0;
		var r = sbasis.getRect(ctx);
		sbasis.x = stage.stageWidth/2 - r.width/2 - r.x;
		sbasis.y = stage.stageHeight/2 - r.height/2 - r.y;
		
		var gr = grid.graphics;
		gr.clear();
		gr.lineStyle(1, theme.grid);
		
		if (isGrid && ctx.playState == 0) {
			var w = Math.ceil((r.width+r.x)/scale);
			var h = Math.ceil((r.height+r.y)/scale);
			
			for (ix in Math.floor(r.x/scale)...w)
				for (iy in Math.floor(r.y/scale)...h)
					gr.drawRect(ix*scale, iy*scale, scale, scale);
			
		} else gr.drawRect(r.x, r.y, r.width, r.height);
		
		grid.x = sbasis.x;
		grid.y = sbasis.y;
	}
	
	function drawPrevFrame():Void { //fix
		var flen = ctx.basis.frames.length;
		var frameId = ctx.frameId;
		if (ctx.playState != 0 || flen < 2 || frameId < 0) return;
		if (frameId == 0) frameId = flen;
		reload(frameId - 1);
		var stage = Lib.current.stage;
		var theme = ctx.theme;
		var basis = ctx.basis;
		var sbasis = ctx.prevView;
		var g = sbasis.graphics;
		var scale = ctx.scale;
		g.clear();
		
		var cslen = theme.lines.length;
		var csi = 0;
		for (e in basis.edges) {
			if (e == null) continue;
			g.lineStyle(3, theme.lines[csi%cslen]);
			g.moveTo(points[e.p1].x * scale, points[e.p1].y * scale);
			g.lineTo(points[e.p2].x * scale, points[e.p2].y * scale);
			csi++;
		}
		
		g.lineStyle(3, theme.color);
		for (p in points) {
			if (p == null) continue;
			g.drawCircle(p.x * scale, p.y * scale, 1);
		}
		
		sbasis.x = 0;
		sbasis.y = 0;
		var r = sbasis.getRect(ctx);
		sbasis.x = stage.stageWidth/2 - r.width/2 - r.x;
		sbasis.y = stage.stageHeight/2 - r.height/2 - r.y;
		reload(ctx.frameId);
	}
	
}
