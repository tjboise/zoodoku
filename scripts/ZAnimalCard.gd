extends Control

var animal_data: Dictionary = {}
var icon_texture: Texture2D = null
var game_node: Node = null

var _is_placed: bool = false
var _icon_rect: TextureRect = null
var _bg: ColorRect = null
var _border: ColorRect = null

const C_BG: Color      = Color(0.96, 0.92, 0.84)
const C_BG_DIM: Color  = Color(0.90, 0.86, 0.78)
const C_BORDER: Color  = Color(0.72, 0.62, 0.44)
const C_NAME: Color    = Color(0.22, 0.16, 0.08)
const C_CLUE: Color    = Color(0.50, 0.38, 0.22)

func _ready() -> void:
	custom_minimum_size = Vector2(370, 110)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_bg = ColorRect.new()
	_bg.color = C_BG
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_bg)

	_border = ColorRect.new()
	_border.color = C_BORDER
	_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_border.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_border.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_border)

	var inner_bg: ColorRect = ColorRect.new()
	inner_bg.color = C_BG
	inner_bg.position = Vector2(2, 2)
	inner_bg.size = Vector2(366, 106)
	inner_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(inner_bg)
	# keep _bg for opacity dimming
	_bg = inner_bg

	_icon_rect = TextureRect.new()
	_icon_rect.texture = icon_texture
	_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.size = Vector2(94, 94)
	_icon_rect.position = Vector2(8, 8)
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_icon_rect)

	var name_lbl: Label = Label.new()
	name_lbl.text = animal_data.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", C_NAME)
	name_lbl.position = Vector2(110, 8)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(name_lbl)

	var clue_lbl: Label = Label.new()
	clue_lbl.text = "「" + animal_data.get("clue", "") + "」"
	clue_lbl.add_theme_font_size_override("font_size", 13)
	clue_lbl.add_theme_color_override("font_color", C_CLUE)
	clue_lbl.position = Vector2(110, 38)
	clue_lbl.custom_minimum_size = Vector2(248, 66)
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
	modulate.a = 0.40 if placed else 1.0
