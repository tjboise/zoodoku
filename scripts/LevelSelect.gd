extends Control

const MAP_OCEAN: Color = Color(0.46, 0.68, 0.84)
const MAP_LAND: Color = Color(0.64, 0.76, 0.52)
const MAP_LAND_OUTLINE: Color = Color(0.46, 0.60, 0.34)
const MAP_GRID: Color = Color(1.0, 1.0, 1.0, 0.10)
const TOPBAR_BG: Color = Color(0.94, 0.90, 0.80)

const ZOO_DATA: Array = [
	{
		"level": 0,
		"name_en": "San Diego Zoo",
		"name_zh": "圣地亚哥动物园",
		"location_en": "San Diego, California, USA",
		"location_zh": "美国·加利福尼亚",
		"animals_en": "Monkey · Rabbit · Hippo · Penguin",
		"animals_zh": "猴子 · 兔子 · 河马 · 企鹅",
		"pos": Vector2(224, 260),
		"color": Color(0.90, 0.48, 0.22),
	},
	{
		"level": 1,
		"name_en": "Singapore Zoo",
		"name_zh": "新加坡动物园",
		"location_en": "Singapore",
		"location_zh": "新加坡",
		"animals_en": "Giant Panda · Parrot · Snake · Pig",
		"animals_zh": "大熊猫 · 鹦鹉 · 蛇 · 猪",
		"pos": Vector2(1009, 358),
		"color": Color(0.24, 0.76, 0.48),
	},
]

var _continents: Array[PackedVector2Array] = []
var _hover_idx: int = -1
var _anim_t: float = 0.0
var _sound_btn: Button = null
var _lang_btn: Button = null
var _title_lbl: Label = null
var _sub_lbl: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

	Locale.language_changed.connect(_on_language_changed)

	_continents = [
		PackedVector2Array([
			Vector2(50, 142), Vector2(170, 95), Vector2(350, 125),
			Vector2(415, 170), Vector2(400, 250), Vector2(360, 285),
			Vector2(330, 300), Vector2(360, 335), Vector2(255, 285),
			Vector2(195, 230), Vector2(120, 175),
		]),
		PackedVector2Array([
			Vector2(280, 350), Vector2(360, 340), Vector2(410, 390),
			Vector2(410, 480), Vector2(385, 575), Vector2(330, 610),
			Vector2(265, 575), Vector2(245, 490), Vector2(250, 380),
		]),
		PackedVector2Array([
			Vector2(530, 90), Vector2(640, 88), Vector2(690, 130),
			Vector2(680, 185), Vector2(655, 220), Vector2(600, 235),
			Vector2(555, 215), Vector2(530, 175), Vector2(526, 130),
		]),
		PackedVector2Array([
			Vector2(545, 240), Vector2(660, 235), Vector2(710, 275),
			Vector2(720, 355), Vector2(700, 455), Vector2(650, 505),
			Vector2(600, 518), Vector2(555, 495), Vector2(540, 415),
			Vector2(535, 330), Vector2(540, 255),
		]),
		PackedVector2Array([
			Vector2(655, 90), Vector2(815, 85), Vector2(940, 98),
			Vector2(1075, 130), Vector2(1145, 175), Vector2(1120, 250),
			Vector2(1065, 298), Vector2(1035, 365), Vector2(960, 398),
			Vector2(885, 408), Vector2(815, 382), Vector2(758, 345),
			Vector2(715, 280), Vector2(680, 235), Vector2(658, 185),
			Vector2(652, 130),
		]),
		PackedVector2Array([
			Vector2(935, 440), Vector2(1060, 432), Vector2(1105, 468),
			Vector2(1100, 548), Vector2(1040, 572), Vector2(965, 565),
			Vector2(922, 525), Vector2(920, 478),
		]),
		PackedVector2Array([
			Vector2(385, 88), Vector2(475, 84), Vector2(510, 115),
			Vector2(493, 175), Vector2(447, 195), Vector2(395, 175),
			Vector2(372, 130),
		]),
	]

	MusicManager.play("res://assets/audio/music_menu.ogg")
	_build_ui()

func _build_ui() -> void:
	# Clear children except continents data (no children at scene start)
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	_title_lbl = Label.new()
	_title_lbl.text = "ZOODOKU"
	_title_lbl.add_theme_font_size_override("font_size", 46)
	_title_lbl.add_theme_color_override("font_color", Color(0.22, 0.16, 0.08))
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.position = Vector2(440, 12)
	_title_lbl.custom_minimum_size = Vector2(400, 0)
	add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.text = Locale.t(
		"Travel the World, Save the Zoo!  ·  Click a map marker to enter a level",
		"环游世界，拯救动物园！　点击地图上的标记进入关卡"
	)
	_sub_lbl.add_theme_font_size_override("font_size", 14)
	_sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.35, 0.20))
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.position = Vector2(320, 66)
	_sub_lbl.custom_minimum_size = Vector2(640, 0)
	add_child(_sub_lbl)

	_sound_btn = Button.new()
	_sound_btn.text = (Locale.t("x Muted", "x 静音") if MusicManager.muted
		else Locale.t("~ Music", "~ 音乐"))
	_sound_btn.add_theme_font_size_override("font_size", 13)
	_sound_btn.position = Vector2(1182, 18)
	_sound_btn.custom_minimum_size = Vector2(80, 32)
	_sound_btn.pressed.connect(_on_sound_pressed)
	add_child(_sound_btn)

	_lang_btn = Button.new()
	_lang_btn.text = "中文" if Locale.lang == "en" else "EN"
	_lang_btn.add_theme_font_size_override("font_size", 13)
	_lang_btn.position = Vector2(1090, 18)
	_lang_btn.custom_minimum_size = Vector2(80, 32)
	_lang_btn.pressed.connect(_toggle_language)
	add_child(_lang_btn)

func _on_language_changed() -> void:
	_build_ui()
	queue_redraw()

func _on_sound_pressed() -> void:
	MusicManager.toggle_mute()
	if _sound_btn:
		_sound_btn.text = (Locale.t("x Muted", "x 静音") if MusicManager.muted
			else Locale.t("~ Music", "~ 音乐"))

func _toggle_language() -> void:
	Locale.set_language("zh" if Locale.lang == "en" else "en")

func _process(delta: float) -> void:
	_anim_t += delta
	queue_redraw()
	var mouse: Vector2 = get_global_mouse_position()
	var new_hover: int = -1
	for i: int in ZOO_DATA.size():
		var zoo: Dictionary = ZOO_DATA[i]
		var pos: Vector2 = zoo["pos"]
		if mouse.distance_to(pos) < 32.0:
			new_hover = i
			break
	if new_hover != _hover_idx:
		_hover_idx = new_hover

func _zoo_text(zoo: Dictionary, key: String) -> String:
	var lk: String = key + "_" + Locale.lang
	if zoo.has(lk):
		return zoo[lk]
	return zoo.get(key + "_en", "")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), MAP_OCEAN)

	for lon_i: int in 12:
		var x: float = float(lon_i) / 12.0 * 1280.0
		draw_line(Vector2(x, 0), Vector2(x, 720), MAP_GRID, 1.0)
	for lat_i: int in 6:
		var y: float = float(lat_i) / 6.0 * 720.0
		draw_line(Vector2(0, y), Vector2(1280, y), MAP_GRID, 1.0)

	var shadow: Color = Color(0.0, 0.0, 0.0, 0.12)
	for cont: PackedVector2Array in _continents:
		var shifted: PackedVector2Array = PackedVector2Array()
		for pt: Vector2 in cont:
			shifted.append(pt + Vector2(4, 4))
		draw_colored_polygon(shifted, shadow)

	for cont: PackedVector2Array in _continents:
		draw_colored_polygon(cont, MAP_LAND)
		var outline: PackedVector2Array = PackedVector2Array(cont)
		outline.append(cont[0])
		draw_polyline(outline, MAP_LAND_OUTLINE, 1.5, true)

	for i: int in ZOO_DATA.size():
		var zoo: Dictionary = ZOO_DATA[i]
		var pos: Vector2 = zoo["pos"]
		var col: Color = zoo["color"]
		var is_hover: bool = (i == _hover_idx)

		var pulse: float = (sin(_anim_t * 2.2) + 1.0) * 0.5
		var ring_r: float = 22.0 + pulse * 10.0
		draw_circle(pos, ring_r, Color(col.r, col.g, col.b, 0.20 * (1.0 - pulse * 0.4)))

		var dot_r: float = 13.0 if is_hover else 10.0
		draw_circle(pos, dot_r + 2.5, Color(0.1, 0.06, 0.02, 0.38))
		draw_circle(pos, dot_r, col)
		draw_circle(pos, dot_r * 0.42, Color(1.0, 1.0, 1.0, 0.85))

		var font: Font = ThemeDB.fallback_font
		var name_str: String = _zoo_text(zoo, "name")
		var lx: float = pos.x + 18.0
		var ly: float = pos.y - 6.0
		if pos.x > 900:
			lx = pos.x - 145.0
		draw_string(font, Vector2(lx + 1, ly + 1), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.4))
		draw_string(font, Vector2(lx, ly), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.14, 0.10, 0.04))

		if is_hover:
			_draw_zoo_card(pos, zoo)

	draw_rect(Rect2(0, 0, 1280, 90), Color(TOPBAR_BG.r, TOPBAR_BG.g, TOPBAR_BG.b, 0.88))
	draw_line(Vector2(0, 90), Vector2(1280, 90), Color(0.72, 0.62, 0.44, 0.6), 1.5)

	_draw_compass(Vector2(1215, 648), 28.0)

	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(12, 714), "Zoodoku · 2026", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.35))

func _draw_zoo_card(pos: Vector2, zoo: Dictionary) -> void:
	var card_w: float = 260.0
	var card_h: float = 120.0
	var cx: float = clamp(pos.x - card_w / 2.0, 8.0, 1272.0 - card_w)
	var cy: float = pos.y - card_h - 24.0
	if cy < 95.0:
		cy = pos.y + 24.0

	draw_rect(Rect2(cx + 5, cy + 5, card_w, card_h), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(cx, cy, card_w, card_h), Color(0.97, 0.93, 0.86, 0.97))
	draw_rect(Rect2(cx, cy, card_w, card_h), Color(0.72, 0.62, 0.44), false, 2.0)
	draw_rect(Rect2(cx, cy, card_w, 7), zoo["color"])

	var font: Font = ThemeDB.fallback_font
	var lvl_num: int = int(zoo["level"]) + 1
	var enter_str: String = Locale.t("Level " + str(lvl_num) + "  ·  Click to Enter →",
		"第 " + str(lvl_num) + " 关  ·  点击进入 →")

	draw_string(font, Vector2(cx + 14, cy + 34), _zoo_text(zoo, "name"), HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 20), 18, Color(0.20, 0.14, 0.06))
	draw_string(font, Vector2(cx + 14, cy + 58), _zoo_text(zoo, "location"), HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 20), 13, Color(0.50, 0.38, 0.22))
	draw_string(font, Vector2(cx + 14, cy + 80), _zoo_text(zoo, "animals"), HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 20), 12, Color(0.50, 0.38, 0.22))
	draw_string(font, Vector2(cx + 14, cy + 104), enter_str, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 20), 12, Color(0.72, 0.46, 0.16))

func _draw_compass(center: Vector2, r: float) -> void:
	draw_circle(center, r + 4, Color(0.60, 0.50, 0.34, 0.55))
	draw_circle(center, r + 3, Color(0.94, 0.90, 0.80, 0.90))

	var font: Font = ThemeDB.fallback_font
	var dirs: Array = [
		[Vector2(0, -1), "N", Color(0.78, 0.28, 0.18)],
		[Vector2(0, 1),  "S", Color(0.30, 0.22, 0.12)],
		[Vector2(1, 0),  "E", Color(0.30, 0.22, 0.12)],
		[Vector2(-1, 0), "W", Color(0.30, 0.22, 0.12)],
	]
	for d: Array in dirs:
		var dir: Vector2 = d[0]
		var col: Color = d[2]
		var tip: Vector2 = center + dir * r * 0.88
		var arm1: Vector2 = center + dir.rotated(PI * 0.5) * r * 0.22
		var arm2: Vector2 = center + dir.rotated(-PI * 0.5) * r * 0.22
		draw_colored_polygon(PackedVector2Array([tip, arm1, center, arm2]), col)
		var lpos: Vector2 = center + dir * (r + 12) - Vector2(4, 4)
		draw_string(font, lpos, d[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.22, 0.16, 0.08))

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		return
	var mouse: Vector2 = get_global_mouse_position()
	for zoo: Dictionary in ZOO_DATA:
		var pos: Vector2 = zoo["pos"]
		if mouse.distance_to(pos) < 32.0:
			_enter_level(int(zoo["level"]))
			return

func _enter_level(level_idx: int) -> void:
	Global.selected_level = level_idx
	get_tree().change_scene_to_file("res://scenes/Zoodoku.tscn")
