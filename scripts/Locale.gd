extends Node

signal language_changed

# Default language is English; switch with set_language("zh")
var lang: String = "en"

func t(en: String, zh: String) -> String:
	return zh if lang == "zh" else en

func set_language(new_lang: String) -> void:
	if new_lang == lang:
		return
	lang = new_lang
	language_changed.emit()
