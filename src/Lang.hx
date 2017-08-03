package;

import openfl.system.Capabilities;

class Lang {
	
	static var RU:Map<String, String> = [
		"yes"  => "Да",
		"no"  => "Нет",
		"loading"  => "Загрузка...",
		"reset_warning" => "Данные будут потеряны. Вы уверены?",
	];
	static var EN:Map<String, String> = [
		"yes"  => "Yes",
		"no"  => "No",
		"loading"  => "Loading...",
		"reset_warning" => "The data will be lost. Are you sure?",
	];
	static var current:Map<String, String>;
	
	public static function init() {
		set(Capabilities.language);
	}
	
	public static function get(id:String) {
		return current[id];
	}
	
	public static function set(id:String) {
		switch(id) {
			case "ru": current = RU;
			default: current = EN;
		}
	}
	
}
