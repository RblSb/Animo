package;

typedef Basis = {
	v:Int, //version
	?width:Int,
	?height:Int,
	?name:String,
	?delay:Int,
	points:Array<Point>,
	edges:Array<Edge>,
	?frames:Array<Frame>
}

typedef Point = {
	?x:Float,
	?y:Float,
	?edges: Array<Int>,
	?d: Int //depth
}

typedef Edge = {
	?ang:Float,
	?min:Float,
	?max:Float,
	?p1:Int, //points
	?p2:Int
}

typedef Frame = {
	?edges:Array<Edge>
}

typedef EHistory = {
	cmd:String,
	?p:Point,
	?p2:Point,
	?pid:Int,
	?pid2:Int,
	?edges:Array<Edge>,
	?edges2:Array<Edge>,
	?eid:Int,
	?e:Edge
}

typedef AHistory = {
	cmd:String,
	fid:Int,
	?pid:Int,
	?ang:Float
}

typedef Theme = {
	bg: Int,
	color: Int,
	hover: Int,
	hoverLine: Int,
	hoverParent: Int,
	lines: Array<Int>,
	panel: {on: Int, off: Int},
	grid: Int,
	hint: Int
}
