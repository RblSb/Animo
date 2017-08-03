package;

import openfl.display.Sprite;

class Main extends Sprite {
	
	static var loader:Loader;
	
	public function new() {
		super();
		init();
	}
	
	function init():Void {
		if (loader != null) return;
		Lang.init();
		loader = new Loader();
		loader.preload();
		loader.show();
	}
	
}
