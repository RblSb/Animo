package;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.Lib;
import Interfaces.Mode;
import Types;

class EditMode implements Mode {
	
	var undo_h:Array<EHistory> = [];
	var redo_h:Array<EHistory> = [];
	var HISTORY_MAX = 30;
	var closest:Array<Int> = [-1, -1];
	var CLOSE_MAX = 7.0;
	var ctx:Editor;
	
	public function new(ctx:Editor) {
		this.ctx = ctx;
		if (ctx.isTouch) CLOSE_MAX *= 2;
	}
	
	public function select():Void {
		ctx.prevView.visible = false;
		ctx.playState = 0;
		update();
	}
	
	function addHistory(h:EHistory):Void {
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
		case "add":
			h2.push({
				cmd: cmd,
				p: points[h.pid],
				p2: points[h.pid2],
				e: edges[h.eid]
			});
			if (h.pid != -1) delPoint(h.pid);
			if (h.pid2 != -1) delPoint(h.pid2);
			if (h.eid != -1) delEdge(h.eid);
			
		case "del":
			h2.push({cmd: cmd, pid: h.pid});
			setPoint(h.pid, h.p);
			for (i in 0...h.edges.length)
				setEdge(h.p.edges[i], h.edges[i]);
			
		case "set":
			h2.push({cmd: cmd, pid: h.pid, p: points[h.pid]});
			setPoint(h.pid, h.p);
			
		case "merge":
			h2.push({
				cmd: cmd, pid: h.pid, p: h.p, edges: h.edges,
				pid2: h.pid2, p2: h.p2, edges2: h.edges2
			});
			setPoint(h.pid2, h.p2);
			for (i in 0...h.edges2.length)
				setEdge(h.p2.edges[i], h.edges2[i]);
			
			setPoint(h.pid, h.p);
			for (i in 0...h.edges.length)
				setEdge(h.p.edges[i], h.edges[i]);
			
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
		case "add":
			var pid = -1, pid2 = -1, eid = -1;
			if (h.p != null) pid = addPoint(h.p);
			if (h.p2 != null) pid2 = addPoint(h.p2);
			if (h.e != null) eid = addEdge(h.e);
			h2.push({
				cmd: cmd,
				pid: pid,
				pid2: pid2,
				eid: eid
			});
			
		case "del":
			var p = Reflect.copy(points[h.pid]);
			p.edges = p.edges.copy();
			var edges:Array<Edge> = [];
			for (i in p.edges) edges.push(basis.edges[i]);
			h2.push({cmd: cmd, pid: h.pid, p: p, edges: edges});
			delPoint(h.pid);
			
		case "set":
			h2.push({cmd: cmd, pid: h.pid, p: points[h.pid]});
			setPoint(h.pid, h.p);
			
		case "merge":
			var p = Reflect.copy(basis.points[h.pid]);
			p.edges = p.edges.copy();
			var p2 = Reflect.copy(basis.points[h.pid2]);
			p2.edges = p2.edges.copy();
			
			h2.push({
				cmd: cmd, pid: h.pid, p: p, edges: h.edges,
				pid2: h.pid2, p2: p2, edges2: h.edges2
			});
			
			mergePoints(h.pid, h.pid2);
		}
		redo_h.pop();
		update();
		if (!ctx.isTouch) onMouseMove(0);
	}
	
	function addPoint(p:Point):Int {
		var points = ctx.basis.points;
		var id = 0;
		while(points[id] != null) id++;
		if (p.edges == null) p.edges = [];
		points[id] = p;
		
		return id;
	}
	
	function setPoint(id:Int, p:Point):Void {
		var points = ctx.basis.points;
		if (p.edges == null) p.edges = points[id].edges;
		if (p.d == null) p.d = points[id].d;
		points[id] = p;
	}
	
	function delPoint(id:Int):Void {
		var points = ctx.basis.points;
		for (i in 0...points[id].edges.length) {
			delEdge(points[id].edges[0]);
		}
		points[id] = null;
	}

	function addEdge(e:Edge):Int {
		var points = ctx.basis.points;
		var edges = ctx.basis.edges;
		var id = 0;
		while(edges[id] != null) id++;
		if (e.ang == null) e.ang = Math.atan2(
			points[e.p2].y - points[e.p1].y,
			points[e.p2].x - points[e.p1].x
		);
		edges[id] = e;
		points[e.p1].edges.push(id);
		points[e.p2].edges.push(id);
		
		return id;
	}
	
	function setEdge(id:Int, e:Edge):Void {
		var points = ctx.basis.points;
		var edge = ctx.basis.edges[id];
		if (edge == null) edge = {};
		if (e.p1 != null) edge.p1 = e.p1;
		if (e.p2 != null) edge.p2 = e.p2;
		
		edge.ang = Math.atan2(
			points[edge.p2].y - points[edge.p1].y,
			points[edge.p2].x - points[edge.p1].x
		);
		ctx.basis.edges[id] = edge;
		
		if (points[e.p1].edges.indexOf(id) == -1) points[e.p1].edges.push(id);
		if (points[e.p2].edges.indexOf(id) == -1) points[e.p2].edges.push(id);
	}
	
	function delEdge(id:Int):Void {
		var e = ctx.basis.edges[id];
		if (e == null) return;
		var points = ctx.basis.points;
		points[e.p1].edges.remove(id);
		points[e.p2].edges.remove(id);
		ctx.basis.edges[id] = null;
	}
	
	function mergePoints(id:Int, id2:Int):Void {
		var basis = ctx.basis;
		var p = basis.points[id];
		var p2 = basis.points[id2];
		var old_edges = p2.edges.copy();
		var new_edges = p.edges.copy();
		
		for (eid in old_edges) {
			var e = basis.edges[eid];
			var pp = e.p1 == id2 ? e.p2 : e.p1;
			if (e.p1 == id2) e.p1 = id;
			else e.p2 = id;
			var isNew = true;
			
			for (i in new_edges) {
				var e = basis.edges[i];
				if (e == null) continue;
				//trace(pp, id, e.p1, e.p2);
				if ((pp == e.p1 && id == e.p2) ||
					(pp == e.p2 && id == e.p1)) {
					isNew = false;
					break;
				}
			}
			if (isNew) {
				p.edges.push(eid);
				p2.edges.remove(eid);
			} else delEdge(eid);
		}
		
		delPoint(id2);
	}
	
	static inline function dist(x:Float, y:Float, x2:Float, y2:Float):Float {
		return Math.sqrt(Math.pow(x - x2, 2) + Math.pow(y - y2, 2));
	}
	
	function closestPoint(x:Float, y:Float):Int {
		var points = ctx.basis.points;
		var sbasis = ctx.sbasis;
		var scale = ctx.scale;
		var min = CLOSE_MAX;
		if (ctx.isGrid) min *= scale / ctx.DEF_SCALE;
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
		var pointer = ctx.pointers[id];
		var sbasis = ctx.sbasis;
		var basis = ctx.basis;
		var scale = ctx.scale;
		
		if (ctx.isTouch) {
			ctx.pointers[id].isDown = false;
			onMouseMove(id);
			ctx.pointers[id].isDown = true;
		}
		if (closest[0] != -1) { //if start point exist
			pointer.startX = basis.points[closest[0]].x * scale + sbasis.x;
			pointer.startY = basis.points[closest[0]].y * scale + sbasis.y;
		}
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
		
		if (!pointer.isDown) { //start point search
			if (cp != closest[0]) {
				
				closest[0] = cp;
				g.clear();
				
				if (cp != -1) {
					var x = basis.points[cp].x * scale + sbasis.x;
					var y = basis.points[cp].y * scale + sbasis.y;
					g.lineStyle(3, theme.hover);
					g.drawCircle(x, y, 4);
					ctx.setPointHint(basis.points[cp]);
					ctx.pointHint.visible = true;
					
				} else ctx.pointHint.visible = false;
			}
			
		} else { //end point search
			
			closest[1] = cp;
			g.clear();
			
			if (cp != -1) {
				pointer.x = basis.points[cp].x * scale + sbasis.x;
				pointer.y = basis.points[cp].y * scale + sbasis.y;
				g.lineStyle(3, theme.hover);
				g.drawCircle(pointer.x, pointer.y, 4);
				ctx.setPointHint(basis.points[cp]);
				ctx.pointHint.visible = true;
				
			} else ctx.pointHint.visible = false;
			
			//draw line between points
			g.lineStyle(3, theme.hoverLine);
			var sx = pointer.startX;
			var sy = pointer.startY;
			var x = pointer.x;
			var y = pointer.y;
			
			if (isGrid) { //grid binging
				if (closest[0] == -1) {
					sx = Math.round((sx - sbasis.x) / scale) * scale + sbasis.x;
					sy = Math.round((sy - sbasis.y) / scale) * scale + sbasis.y;
				}
				if (closest[1] == -1) {
					x = Math.round((x - sbasis.x) / scale) * scale + sbasis.x;
					y = Math.round((y - sbasis.y) / scale) * scale + sbasis.y;
				}
			}
			g.moveTo(sx, sy);
			g.lineTo(x, y);
		}
	}
	
	public function onMouseUp(id:Int):Void {
		ctx.visual.graphics.clear();
		
		var pointer = ctx.pointers[id];
		var isGrid = ctx.isGrid;
		var sbasis = ctx.sbasis;
		var basis = ctx.basis;
		var points = basis.points;
		var scale = ctx.scale;
		var pid = -1, pid2 = -1, eid = -1; //for history
		
		if (closest[0] == -1) { //new start point
			var sx = (pointer.startX - sbasis.x) / scale;
			var sy = (pointer.startY - sbasis.y) / scale;
			if (isGrid) {
				sx = Math.round(sx);
				sy = Math.round(sy);
			}
			closest[0] = addPoint({x: sx, y: sy, d: 0});
			pid = closest[0];
		}
		
		if (dist(pointer.x, pointer.y, pointer.startX, pointer.startY) > CLOSE_MAX) {
			
			if (closest[1] == -1) { //new end point
				var x = (pointer.x - sbasis.x) / scale;
				var y = (pointer.y - sbasis.y) / scale;
				if (isGrid) {
					x = Math.round(x);
					y = Math.round(y);
				}
				var d = closest[0] == -1 ? 1 : points[closest[0]].d + 1;
				
				closest[1] = addPoint({x: x, y: y, d: d});
				pid2 = closest[1];
			}
			//new line
			eid = addEdge({p1: closest[0], p2: closest[1]});
			//clear this line old frame data
			for (frame in ctx.basis.frames) {
				frame.edges[eid] = null;
			}
		}
		
		if (pid == -1 && pid2 == -1 && eid == -1) return;
		
		addHistory({cmd: "add", pid: pid, pid2: pid2, eid: eid});
		pointer.startX = 0;
		pointer.startY = 0;
		closest[0] = -1;
		closest[1] = -1;
		
		update();
		if (!ctx.isTouch) onMouseMove(id);
	}
	
	public function onRightDown(id:Int):Void {
		var pointer = ctx.pointers[id];
		var sbasis = ctx.sbasis;
		var basis = ctx.basis;
		var scale = ctx.scale;
		
		if (closest[0] != -1) { //if start point exist
			pointer.isDown = true;
			pointer.startX = basis.points[closest[0]].x * scale + sbasis.x;
			pointer.startY = basis.points[closest[0]].y * scale + sbasis.y;
		}
	}
	
	public function onRightUp(id:Int):Void {
		ctx.visual.graphics.clear();
		if (closest[0] == -1) return;
		
		var pointer = ctx.pointers[id];
		var sbasis = ctx.sbasis;
		var basis = ctx.basis;
		var scale = ctx.scale;
		pointer.isDown = false;
		
		if (dist(pointer.x, pointer.y, pointer.startX, pointer.startY) > CLOSE_MAX) {
			var cp = closestPoint(pointer.x, pointer.y);
			if (cp == -1) { //edit point
				
				var x = (pointer.x - sbasis.x) / scale;
				var y = (pointer.y - sbasis.y) / scale;
				if (ctx.isGrid) {
					x = Math.round(x);
					y = Math.round(y);
				}
				var pid = closest[0];
				var p = basis.points[pid];
				addHistory({cmd: "set", pid: pid, p: p});
				setPoint(pid, {x: x, y: y});
				
			} else { //merge points
				
				var p = Reflect.copy(basis.points[cp]);
				p.edges = p.edges.copy();
				var edges:Array<Edge> = [];
				for (i in p.edges) edges.push(Reflect.copy(basis.edges[i]));
				
				var pid = closest[0];
				var p2 = Reflect.copy(basis.points[pid]);
				p2.edges = p2.edges.copy();
				var edges2:Array<Edge> = [];
				for (i in p2.edges) edges2.push(Reflect.copy(basis.edges[i]));
				
				addHistory({
					cmd: "merge", pid: cp, p: p, edges: edges,
					pid2: pid, p2: p2, edges2: edges2
				});
				
				mergePoints(cp, pid);
			}
			
		} else { //delete point
			
			var pid = closest[0];
			var p = Reflect.copy(basis.points[pid]);
			p.edges = p.edges.copy();
			var edges:Array<Edge> = [];
			for (i in p.edges) edges.push(basis.edges[i]);
			addHistory({cmd: "del", pid: pid, p: p, edges: edges});
			delPoint(pid);
		}
		
		update();
		if (!ctx.isTouch) onMouseMove(id);
	}
	
	public function onEnterFrame():Void {}
	
	public function update():Void {
		var stage = Lib.current.stage;
		var theme = ctx.theme;
		var isGrid = ctx.isGrid;
		var grid = ctx.grid;
		
		var sbasis = ctx.sbasis;
		var g = sbasis.graphics;
		var points = ctx.basis.points;
		var edges = ctx.basis.edges;
		var scale = ctx.scale;
		g.clear();
		
		var plen = 0, elen = 0; //counters
		
		var cslen = theme.lines.length;
		var csi = 0;
		for (e in edges) {
			if (e == null) continue;
			g.lineStyle(3, theme.lines[csi % cslen]);
			g.moveTo(points[e.p1].x * scale, points[e.p1].y * scale);
			g.lineTo(points[e.p2].x * scale, points[e.p2].y * scale);
			csi++;
			elen++;
		}
		
		g.lineStyle(3, theme.color);
		for (p in points) {
			if (p == null) continue;
			g.drawCircle(p.x * scale, p.y * scale, 1);
			plen++;
		}
		
		sbasis.x = 0;
		sbasis.y = 0;
		var r = sbasis.getRect(ctx);
		sbasis.x = stage.stageWidth/2 - r.width/2 - r.x;
		sbasis.y = stage.stageHeight/2 - r.height/2 - r.y;
		
		var gr = grid.graphics;
		gr.clear();
		gr.lineStyle(1, theme.grid);
		
		if (isGrid) {
			var w = Math.ceil((r.width+r.x)/scale);
			var h = Math.ceil((r.height+r.y)/scale);
			
			for (ix in Math.floor(r.x/scale)...w)
				for (iy in Math.floor(r.y/scale)...h)
					gr.drawRect(ix*scale, iy*scale, scale, scale);
			
		} else gr.drawRect(r.x, r.y, r.width, r.height);
		
		grid.x = sbasis.x;
		grid.y = sbasis.y;
		
		ctx.setInfo(plen, elen);
	}
	
}
