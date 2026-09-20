extends Control

var animal_data: Dictionary = {}
var icon_texture: Texture2D = null
var game_node: Node = null

var _is_placed: bool = false
var _icon_rect: TextureRect = null
var _bg: ColorRect = null

func _ready() -> void:
	custom_minimum_size = Vector2(370, 110)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_bg = ColorRect.new()
	_bg.color = Color(0.18, 0.21, 0.17)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_bg)

	_icon_rect = TextureRect.new()
	_icon_rect.texture = icon_texture
	_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.size = Vector2(96, 96)
	_icon_rect.position = Vector2(7, 7)
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_icon_rect)

	var name_lbl: Label = Label.new()
	name_lbl.text = animal_data.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5))
	name_lbl.position = Vector2(110, 8)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(name_lbl)

	var clue_lbl: Label = Label.new()
	clue_lbl.text = "「" + animal_data.get("clue", "") + "」"
	clue_lbl.add_theme_font_size_override("font_size", 14)
	clue_lbl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.78))
	clue_lbl.position = Vector2(110, 38)
	clue_lbl.custom_minimum_size = Vector2(245, 65)
	clue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(clue_lbl)

func _get_drag_data(_at: Vector2) -> Variant:
	if _is_placed or animal_data.is_empty():
		return null

	var preview: Control = Control.new()
	preview.custom_minimum_size = Vector2(100, 100)
	var icon: TextureRect = TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(100, 100)
	preview.add_child(icon)
	set_drag_preview(preview)

	return animal_data.duplicate()

func set_placed(placed: bool) -> void:
	_is_placed = placed
	modulate.a = 0.38 if placed else 1.0
	if _bg:
		_bg.color = Color(0.12, 0.14, 0.11) if placed else Color(0.18, 0.21, 0.17)
