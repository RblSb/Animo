package;

import openfl.system.Capabilities;

class Lang {
	
	static var RU:Map<String, String> = [
		"yes" => "Да",
		"no" => "Нет",
		"loading" => "Загрузка...",
		"reset_warning" => "Данные будут потеряны. Вы уверены?",
		"file" => "Файл",
		"edit" => "Правка",
		"view" => "Вид",
		"settings" => "Настройки",
		"help" => "Помощь для Death",
		"about" => "О программе",
		"new" => "Новый",
		"open" => "Открыть",
		"save" => "Сохранить",
		"file_sets" => "Настройки проекта",
		"write_gif" => "Записать в GIF",
		"undo" => "Отменить",
		"redo" => "Повторить",
		"add_frame" => "Добавить кадр",
		"delete_frame" => "Удалить кадр",
		"next_frame" => "Следующий кадр",
		"prev_frame" => "Предыдущий кадр",
		"play_pause" => "Пуск/Пауза",
		"grid" => "Сетка",
		"toggle_theme" => "Сменить тему",
		"reset_scale" => "Сбросить масштаб"
	];
	static var EN:Map<String, String> = [
		"yes" => "Yes",
		"no" => "No",
		"loading" => "Loading...",
		"reset_warning" => "The data will be lost. Are you sure?",
		"file" => "File",
		"edit" => "Edit",
		"view" => "View",
		"settings" => "Settings",
		"help" => "Help",
		"github" => "Github",
		"about" => "About",
		"new" => "New",
		"open" => "Open",
		"save" => "Save",
		"file_sets" => "File Sets",
		"write_gif" => "Write GIF",
		"undo" => "Undo",
		"redo" => "Redo",
		"add_frame" => "Add Frame",
		"delete_frame" => "Delete Frame",
		"next_frame" => "Next Frame",
		"prev_frame" => "Prev Frame",
		"play_pause" => "Play/Pause",
		"grid" => "Grid",
		"toggle_theme" => "Toggle Theme",
		"reset_scale" => "Reset Scale"
	];
	static var current:Map<String, String>;
	public static var iso:String;
	
	public static function init() {
		iso = Capabilities.language;
		set(iso);
	}
	
	public static function get(id:String) {
		var s = current[id];
		if (s == null) {
			s = EN[id];
			if (s == null) return id;
		}
		return s;
	}
	
	public static function set(id:String) {
		switch(id) {
			case "ru": current = RU;
			default: current = EN;
		}
	}
	
	public static inline function fastGet(id:String) {
		return current[id];
	}
	
}
