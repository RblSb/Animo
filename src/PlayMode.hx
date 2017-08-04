package;

import openfl.display.BitmapData;
//import openfl.display.Tilemap;
//import openfl.display.Tile;
import openfl.display.Sprite;
import openfl.Lib;
import gif.Gif;
import Interfaces.Mode;
import Types;

class PlayMode implements Mode {
	
	var gif:Gif;
	var minW = 0.0; //for gif
	var minH = 0.0;
	var maxW = 0.0;
	var maxH = 0.0;
	var points:Array<Point> = []; //cache
	var edges:Array<Edge> = [];
	var oldFrameId = -1;
	var frameCount = 1;
	var ctx:Editor;
	var sbasis(get, never):Sprite;
	var basis(get, never):Basis;
	var theme(get, never):Theme;
	var scale(get, never):Float;
	var isGrid(get, never):Bool;
	
	public function new(ctx:Editor) {
		this.ctx = ctx;
	}
	
	public function select():Void {
		oldFrameId = ctx.frameId;
	}
	
	public function createGif():Void {
		var w = Math.abs(minW) + Math.abs(maxW);
		var h = Math.abs(minH) + Math.abs(maxH);
		gif = new Gif(
			Math.ceil(w * scale + 6),
			Math.ceil(h * scale + 6),
			1/30, -1, 10, 2
		);
	}
	
	public function clear():Void {
		if (gif != null) {
			minW = 0;
			minH = 0;
			maxW = 0;
			maxH = 0;
			gif.save(basis.name+'.gif');
			gif = null;
		}
		ctx.frameId = oldFrameId;
	}
	
	public function reload(frameId:Int):Void {
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
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	public function onMouseDown(id:Int):Void {}
	public function onMouseMove(id:Int):Void {}
	public function onMouseUp(id:Int):Void {}
	public function onRightDown(id:Int):Void {}
	public function onRightUp(id:Int):Void {}
	
	static inline function dist(x:Float, y:Float, x2:Float, y2:Float):Float {
		return Math.sqrt(Math.pow(x - x2, 2) + Math.pow(y - y2, 2));
	}
	
	function transform(frameId:Int, p:Int, angDiff=0.0, addX=0.0, addY=0.0):Void {
		var p1 = points[p]; //current point
		if (p1 == null) return;
		var parents = getParents(p1);
		if (parents.length != 1) return;
		var pp = parents[0]; //parent id
		var p2 = points[pp]; //parent point
		
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

		if (p1.x < minW) minW = p1.x; //for gif
		if (p1.y < minH) minH = p1.y;
		if (p1.x > maxW) maxW = p1.x;
		if (p1.y > maxH) maxH = p1.y;
		
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
			var e = basis.edges[eid];
			if (points[e.p1].d == p.d + depth ||
				points[e.p2].d == p.d + depth) edges.push(eid);
		}
		return edges;
	}
	
	function getParents(p:Point):Array<Int> {
		var parents:Array<Int> = [];
		for (eid in p.edges) {
			var e = basis.edges[eid];
			if (points[e.p1].d == p.d-1) parents.push(e.p1);
			if (points[e.p2].d == p.d-1) parents.push(e.p2);
		}
		return parents;
	}
	
	function getChilds(p:Point):Array<Int> {
		var childs:Array<Int> = [];
		for (eid in p.edges) {
			var e = basis.edges[eid];
			if (points[e.p1].d == p.d+1) childs.push(e.p1);
			if (points[e.p2].d == p.d+1) childs.push(e.p2);
		}
		return childs;
	}
	
	public function onEnterFrame():Void {
		if (ctx.playState == 3) {
			var bmd = new BitmapData(
				Math.ceil(sbasis.width * 2),
				Math.ceil(sbasis.height * 2),
				false,
				theme.bg
			);
			
			sbasis.x = 0;
			sbasis.y = 0;
			var r = sbasis.getRect(ctx);
			var w = Math.abs(r.x) + Math.abs(r.width);
			var h = Math.abs(r.y) + Math.abs(r.height);
			
			var offx = w/2 + gif.width - w + 3;
			//var offy = h - gif.height;
			var offy = gif.height/2 + 6;
			var mat = new openfl.geom.Matrix(1,0,0,1,offx,offy);
			bmd.draw(sbasis, mat);
			gif.addFrame(bmd);
			
			var stage = Lib.current.stage;
			sbasis.x = stage.stageWidth/2 - r.width/2 - r.x;
			sbasis.y = stage.stageHeight/2 - r.height/2 - r.y;
		}
		
		var frame = basis.frames[ctx.frameId];
		var fnext = ctx.frameId + 1;
		if (fnext == basis.frames.length) fnext = 0;
		var frame2 = basis.frames[fnext];
		var delay = basis.delay;
		
		for (eid in 0...basis.edges.length) {
			if (basis.edges[eid] == null) continue;
			var f = frame.edges[eid];
			var f2 = frame2.edges[eid];
			if (f == null || f2 == null) return;
			var dist = distAng(f2.ang, f.ang) / delay * frameCount;
			if (dist == 0) continue;
			edges[eid].ang = basis.edges[eid].ang + f.ang - dist;
		}
		
		for (p in points) { //get main points
			if (p == null) continue;
			if (p.d == 0) {
				var childs = getChilds(p);
				for (id in childs) {
					transformView(id);
				}
			}
		}
		
		update();
		frameCount++;
		if (frameCount > delay) {
			frameCount = 1;
			ctx.frameId = fnext;
			if (ctx.playState > 1 && fnext == 0) {
				ctx.togglePlay();
			}
			ctx.updateFramePanel();
		}
	}
	
	function distAng(ang:Float, toAng:Float):Float {
		var a = toAng - ang;
		if (a < -Math.PI) a += Math.PI * 2;
		if (a > Math.PI) a -= Math.PI * 2;
		return a;
	}
	
	function transformView(p:Int, addX=0.0, addY=0.0):Void {
		var p1 = points[p]; //current point
		if (p1 == null) return;
		var parents = getParents(p1);
		if (parents.length != 1) return;
		var pp = parents[0]; //parent id
		var p2 = points[pp]; //parent point
		
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
		var stage = Lib.current.stage;
		var grid = ctx.grid;
		var g = sbasis.graphics;
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
	
	function get_sbasis() {
		return ctx.sbasis;
	}
	function get_basis() {
		return ctx.basis;
	}
	function get_theme() {
		return ctx.theme;
	}
	function get_scale() {
		return ctx.scale;
	}
	function get_isGrid() {
		return ctx.isGrid;
	}
	
}
