extends Control

# ── Level definitions ─────────────────────────────────────────────────────────
const LEVELS: Array = [
	{
		"level_name": "第 1 关：失踪的企鹅",
		"story": (
			"动物园管理员小美今天早上发现企鹅不见了！\n"
			+ "她找到其他三只动物问了情况。\n"
			+ "请根据它们的证词，找出企鹅藏在哪里。"
		),
		"target_id": "penguin",
		"win_text": "企鹅在草地的西南角晒太阳！\n小美终于找到它啦！",
		"grid_areas": [
			[0, 0, 0, 1],
			[0, 0, 2, 1],
			[2, 2, 2, 1],
			[2, 2, 2, 2],
		],
		"objects": [
			{"row": 0, "col": 0, "type": "tree"},
			{"row": 1, "col": 3, "type": "rock"},
			{"row": 3, "col": 3, "type": "flower"},
		],
		"animals": [
			{
				"id": "monkey", "name": "猴子",
				"clue": "我就在那棵大树旁边。",
				"solution_row": 0, "solution_col": 1,
				"image_path": "res://assets/sprites/animals/monkey.png",
			},
			{
				"id": "rabbit", "name": "兔子",
				"clue": "我在草地里，我在河马的北边。",
				"solution_row": 1, "solution_col": 2,
				"image_path": "res://assets/sprites/animals/rabbit.png",
			},
			{
				"id": "hippo", "name": "河马",
				"clue": "我在水塘里，我就在那块大石头旁边。",
				"solution_row": 2, "solution_col": 3,
				"image_path": "res://assets/sprites/animals/hippo.png",
			},
			{
				"id": "penguin", "name": "企鹅",
				"clue": "我在草地里，我在猴子的南边。",
				"solution_row": 3, "solution_col": 0,
				"image_path": "res://assets/sprites/animals/penguin.png",
			},
		],
	},
	{
		"level_name": "第 2 关：闹事的猪",
		"story": (
			"找到企鹅后小美松了口气，但下午点名时\n"
			+ "又发现猪不见了！她只好再次四处打听……\n"
			+ "请根据动物们的证词，找出猪藏在哪里。"
		),
		"target_id": "pig",
		"win_text": "猪在森林旁的草地里打滚，全身沾满了泥！\n小美又把它带了回来。",
		"grid_areas": [
			[1, 1, 2, 2],
			[1, 0, 0, 2],
			[1, 0, 0, 2],
			[2, 2, 2, 2],
		],
		"objects": [
			{"row": 0, "col": 0, "type": "flower"},
			{"row": 1, "col": 1, "type": "tree"},
			{"row": 0, "col": 3, "type": "rock"},
		],
		"animals": [
			{
				"id": "panda", "name": "大熊猫",
				"clue": "我在草地里，石头就在我的东边。",
				"solution_row": 0, "solution_col": 2,
				"image_path": "res://assets/sprites/animals/panda.png",
			},
			{
				"id": "parrot", "name": "鹦鹉",
				"clue": "我在水塘里，荷花就在我的北边。",
				"solution_row": 1, "solution_col": 0,
				"image_path": "res://assets/sprites/animals/parrot.png",
			},
			{
				"id": "snake", "name": "蛇",
				"clue": "我在草地里，和大树同一列，在它的南边。",
				"solution_row": 3, "solution_col": 1,
				"image_path": "res://assets/sprites/animals/snake.png",
			},
			{
				"id": "pig", "name": "猪",
				"clue": "我在草地里，在蛇的北边，在熊猫的南边。",
				"solution_row": 2, "solution_col": 3,
				"image_path": "res://assets/sprites/animals/pig.png",
			},
		],
	},
]

const GRID_SIZE: int = 4

const AREA_INFO: Array = [
	{"name": "森林", "color": Color(0.30, 0.56, 0.34)},
	{"name": "水塘", "color": Color(0.36, 0.60, 0.82)},
	{"name": "草地", "color": Color(0.52, 0.76, 0.36)},
]

# Warm palette constants
const C_BG: Color        = Color(0.95, 0.91, 0.81)
const C_LEFT_BG: Color   = Color(0.88, 0.83, 0.71)
const C_CARD_BG: Color   = Color(0.97, 0.93, 0.86)
const C_BORDER: Color    = Color(0.72, 0.62, 0.44)
const C_TEXT: Color      = Color(0.22, 0.16, 0.08)
const C_TEXT2: Color     = Color(0.50, 0.38, 0.22)
const C_ACCENT: Color    = Color(0.82, 0.50, 0.20)
const C_SIDEBAR: Color   = Color(0.84, 0.78, 0.64)

# ── State ────────────────────────────────────────────────────────────────────
var current_level: int = 0
var grid_cells: Array = []
var animal_placements: Dictionary = {}
var card_nodes: Dictionary = {}
var _result_label: Label = null
var _texture_cache: Dictionary = {}
var _sound_btn: Button = null

# ── Texture loader ────────────────────────────────────────────────────────────
func _load_texture(res_path: String) -> Texture2D:
	if _texture_cache.has(res_path):
		return _texture_cache[res_path]
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var img: Image = Image.load_from_file(abs_path)
	if img == null:
		return null
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[res_path] = tex
	return tex

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_level(Global.selected_level)

func _load_level(idx: int) -> void:
	current_level = idx
	animal_placements = {}
	card_nodes = {}
	_result_label = null
	_sound_btn = null

	var children: Array = get_children()
	for child: Node in children:
		remove_child(child)
		child.queue_free()

	grid_cells = []
	MusicManager.play("res://assets/audio/music_game.ogg")
	_build_ui()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _warm_stylebox(bg: Color = C_CARD_BG, border: Color = C_BORDER, radius: int = 6) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _style_button(btn: Button, bg: Color, fg: Color = Color.WHITE) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_left = 7
	sb.corner_radius_bottom_right = 7
	btn.add_theme_stylebox_override("normal", sb)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.bg_color = bg.lightened(0.18)
	btn.add_theme_stylebox_override("hover", sh)
	var sp: StyleBoxFlat = sb.duplicate()
	sp.bg_color = bg.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)

func _sidebar_btn_style(btn: Button) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.76, 0.70, 0.56)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", sb)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.bg_color = Color(0.84, 0.78, 0.64)
	btn.add_theme_stylebox_override("hover", sh)
	var sp: StyleBoxFlat = sb.duplicate()
	sp.bg_color = Color(0.64, 0.58, 0.44)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", C_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)

# ── UI builder ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var lv: Dictionary = LEVELS[current_level]

	# Main background
	var bg: ColorRect = ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	const SIDEBAR_X: int = 1200
	const LEFT_W: int = 392
	const RIGHT_AREA_W: int = SIDEBAR_X - LEFT_W  # 808

	const CELL_S: int = 130
	const GAP: int = 4
	const GRID_PX: int = GRID_SIZE * CELL_S + (GRID_SIZE - 1) * GAP  # 532
	const GRID_X: int = LEFT_W + (RIGHT_AREA_W - GRID_PX) / 2  # 530

	# ── Left panel background ──────────────────────────────────────────────
	var left_bg: ColorRect = ColorRect.new()
	left_bg.color = C_LEFT_BG
	left_bg.position = Vector2(0, 0)
	left_bg.size = Vector2(LEFT_W, 720)
	left_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(left_bg)

	var left_border: ColorRect = ColorRect.new()
	left_border.color = C_BORDER
	left_border.position = Vector2(LEFT_W, 0)
	left_border.size = Vector2(2, 720)
	left_border.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(left_border)

	# ── Left panel content ─────────────────────────────────────────────────
	var left: VBoxContainer = VBoxContainer.new()
	left.position = Vector2(14, 14)
	left.custom_minimum_size = Vector2(LEFT_W - 22, 700)
	left.add_theme_constant_override("separation", 9)
	add_child(left)

	var level_lbl: Label = Label.new()
	level_lbl.text = lv["level_name"]
	level_lbl.add_theme_font_size_override("font_size", 24)
	level_lbl.add_theme_color_override("font_color", Color(0.62, 0.38, 0.10))
	left.add_child(level_lbl)

	var story_panel: PanelContainer = PanelContainer.new()
	story_panel.add_theme_stylebox_override("panel", _warm_stylebox())
	left.add_child(story_panel)

	var story_vb: VBoxContainer = VBoxContainer.new()
	story_vb.add_theme_constant_override("separation", 4)
	story_panel.add_child(story_vb)

	var story_head: Label = Label.new()
	story_head.text = "• 案情"
	story_head.add_theme_font_size_override("font_size", 13)
	story_head.add_theme_color_override("font_color", C_TEXT2)
	story_vb.add_child(story_head)

	var story_text: Label = Label.new()
	story_text.text = lv["story"]
	story_text.add_theme_font_size_override("font_size", 14)
	story_text.add_theme_color_override("font_color", C_TEXT)
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_text.custom_minimum_size = Vector2(350, 0)
	story_vb.add_child(story_text)

	var cards_header: Label = Label.new()
	cards_header.text = "• 动物的证词（拖到右边格子放置）"
	cards_header.add_theme_font_size_override("font_size", 13)
	cards_header.add_theme_color_override("font_color", C_TEXT2)
	left.add_child(cards_header)

	var animals: Array = lv["animals"]
	for animal: Dictionary in animals:
		var card: Control = _make_animal_card(animal)
		left.add_child(card)
		card_nodes[animal["id"]] = card

	var hint: Label = Label.new()
	hint.text = "提示：右键点击格子可移除动物"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.44, 0.28))
	left.add_child(hint)

	# ── Grid area ──────────────────────────────────────────────────────────
	_build_legend(GRID_X, 18)

	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.position = Vector2(GRID_X, 58)
	add_child(grid)

	grid_cells = []
	for r: int in GRID_SIZE:
		var row_arr: Array = []
		for c: int in GRID_SIZE:
			var cell: Control = _make_cell(r, c)
			grid.add_child(cell)
			row_arr.append(cell)
		grid_cells.append(row_arr)

	var submit_btn: Button = Button.new()
	submit_btn.text = "✓  提交答案"
	submit_btn.add_theme_font_size_override("font_size", 19)
	submit_btn.custom_minimum_size = Vector2(220, 48)
	submit_btn.position = Vector2(GRID_X + (GRID_PX - 220) / 2, 614)
	submit_btn.pressed.connect(_check_solution)
	_style_button(submit_btn, C_ACCENT)
	add_child(submit_btn)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.position = Vector2(GRID_X, 672)
	_result_label.custom_minimum_size = Vector2(GRID_PX, 40)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_label)

	# ── Sidebar ────────────────────────────────────────────────────────────
	_build_sidebar(SIDEBAR_X)

func _build_sidebar(sx: int) -> void:
	var sb_bg: ColorRect = ColorRect.new()
	sb_bg.color = C_SIDEBAR
	sb_bg.position = Vector2(sx, 0)
	sb_bg.size = Vector2(1280 - sx, 720)
	sb_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(sb_bg)

	var border: ColorRect = ColorRect.new()
	border.color = C_BORDER
	border.position = Vector2(sx, 0)
	border.size = Vector2(2, 720)
	border.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(border)

	var btn_w: int = 72
	var btn_x: int = sx + 4

	var back_btn: Button = Button.new()
	back_btn.text = "←\n返回"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.position = Vector2(btn_x, 12)
	back_btn.custom_minimum_size = Vector2(btn_w, 58)
	back_btn.pressed.connect(_go_back_to_map)
	_sidebar_btn_style(back_btn)
	add_child(back_btn)

	var help_btn: Button = Button.new()
	help_btn.text = "?\n规则"
	help_btn.add_theme_font_size_override("font_size", 13)
	help_btn.position = Vector2(btn_x, 88)
	help_btn.custom_minimum_size = Vector2(btn_w, 58)
	help_btn.pressed.connect(_show_how_to_play)
	_sidebar_btn_style(help_btn)
	add_child(help_btn)

	var about_btn: Button = Button.new()
	about_btn.text = "i\n关于"
	about_btn.add_theme_font_size_override("font_size", 13)
	about_btn.position = Vector2(btn_x, 164)
	about_btn.custom_minimum_size = Vector2(btn_w, 58)
	about_btn.pressed.connect(_show_about)
	_sidebar_btn_style(about_btn)
	add_child(about_btn)

	_sound_btn = Button.new()
	_sound_btn.text = "✕\n静音" if MusicManager.muted else "♪\n音乐"
	_sound_btn.add_theme_font_size_override("font_size", 13)
	_sound_btn.position = Vector2(btn_x, 240)
	_sound_btn.custom_minimum_size = Vector2(btn_w, 58)
	_sound_btn.pressed.connect(_toggle_sound)
	_sidebar_btn_style(_sound_btn)
	add_child(_sound_btn)

func _build_legend(gx: int, gy: int) -> void:
	var hb: HBoxContainer = HBoxContainer.new()
	hb.position = Vector2(gx, gy)
	hb.add_theme_constant_override("separation", 6)
	add_child(hb)
	for info: Dictionary in AREA_INFO:
		var swatch: ColorRect = ColorRect.new()
		swatch.color = info["color"]
		swatch.custom_minimum_size = Vector2(16, 16)
		hb.add_child(swatch)
		var lbl: Label = Label.new()
		lbl.text = info["name"] + "   "
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", C_TEXT2)
		hb.add_child(lbl)

func _make_animal_card(animal: Dictionary) -> Control:
	var card_gd: GDScript = load("res://scripts/ZAnimalCard.gd")
	var card: Control = card_gd.new()
	card.animal_data = animal.duplicate()
	card.icon_texture = _load_texture(animal["image_path"])
	card.game_node = self
	return card

func _make_cell(r: int, c: int) -> Control:
	var lv: Dictionary = LEVELS[current_level]
	var grid_areas: Array = lv["grid_areas"]
	var row_data: Array = grid_areas[r]
	var area: int = row_data[c]

	var cell_gd: GDScript = load("res://scripts/ZCell.gd")
	var cell: Control = cell_gd.new()
	cell.row = r
	cell.col = c
	cell.area_type = area
	cell.game_node = self

	var objects: Array = lv["objects"]
	for obj: Dictionary in objects:
		if obj["row"] == r and obj["col"] == c:
			cell.object_type = obj["type"]
			break
	return cell

# ── Placement logic ───────────────────────────────────────────────────────────
func try_place_animal(animal_id: String, r: int, c: int) -> void:
	if animal_placements.has(animal_id):
		var old: Dictionary = animal_placements[animal_id]
		if old["row"] == r and old["col"] == c:
			return
		var old_row: Array = grid_cells[old["row"]]
		var old_cell: Control = old_row[old["col"]]
		old_cell.call("remove_animal")
		animal_placements.erase(animal_id)

	var target_row: Array = grid_cells[r]
	var target_cell: Control = target_row[c]
	var occupant: String = target_cell.get("placed_animal_id")
	if occupant != "" and occupant != animal_id:
		target_cell.call("remove_animal")
		animal_placements.erase(occupant)
		if card_nodes.has(occupant):
			card_nodes[occupant].call("set_placed", false)

	var animal_data: Dictionary = {}
	var lv: Dictionary = LEVELS[current_level]
	var animals: Array = lv["animals"]
	for a: Dictionary in animals:
		if a["id"] == animal_id:
			animal_data = a
			break

	animal_placements[animal_id] = {"row": r, "col": c}
	var tex: Texture2D = _load_texture(animal_data.get("image_path", ""))
	target_cell.call("place_animal", animal_id, tex)

	if card_nodes.has(animal_id):
		card_nodes[animal_id].call("set_placed", true)

	_update_row_col_markers()
	_result_label.text = ""

func remove_animal_from_cell(r: int, c: int) -> void:
	var row_arr: Array = grid_cells[r]
	var cell: Control = row_arr[c]
	var animal_id: String = cell.get("placed_animal_id")
	if animal_id == "":
		return
	cell.call("remove_animal")
	animal_placements.erase(animal_id)
	if card_nodes.has(animal_id):
		card_nodes[animal_id].call("set_placed", false)
	_update_row_col_markers()
	_result_label.text = ""

func _update_row_col_markers() -> void:
	var row_used: Dictionary = {}
	var col_used: Dictionary = {}
	for id: String in animal_placements:
		var pos: Dictionary = animal_placements[id]
		row_used[pos["row"]] = true
		col_used[pos["col"]] = true

	for r: int in GRID_SIZE:
		for c: int in GRID_SIZE:
			var row_arr: Array = grid_cells[r]
			var cell: Control = row_arr[c]
			var has_animal: bool = (cell.get("placed_animal_id") != "")
			var blocked: bool = (row_used.has(r) or col_used.has(c)) and not has_animal
			cell.call("set_blocked", blocked)

# ── Solution check ────────────────────────────────────────────────────────────
func _check_solution() -> void:
	var lv: Dictionary = LEVELS[current_level]
	var animals: Array = lv["animals"]

	if animal_placements.size() < animals.size():
		_result_label.text = "还有动物没放置！请把所有动物都放到格子里。"
		_result_label.add_theme_color_override("font_color", Color(0.78, 0.50, 0.10))
		return

	var correct: bool = true
	for animal: Dictionary in animals:
		if not animal_placements.has(animal["id"]):
			correct = false
			break
		var pos: Dictionary = animal_placements[animal["id"]]
		if pos["row"] != animal["solution_row"] or pos["col"] != animal["solution_col"]:
			correct = false
			break

	if correct:
		_show_win_screen()
	else:
		_result_label.text = "有些动物的位置不对，再想想看！"
		_result_label.add_theme_color_override("font_color", Color(0.82, 0.28, 0.22))

# ── Sidebar actions ───────────────────────────────────────────────────────────
func _go_back_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _toggle_sound() -> void:
	MusicManager.toggle_mute()
	if _sound_btn:
		_sound_btn.text = "✕\n静音" if MusicManager.muted else "♪\n音乐"

func _show_how_to_play() -> void:
	_show_modal_popup("游戏规则", (
		"目标\n把所有动物放到正确的格子里！\n\n"
		+ "基本规则\n"
		+ "• 每行、每列只能有一只动物\n"
		+ "• 根据动物说的话找出它们的位置\n\n"
		+ "区域颜色\n"
		+ "• 深绿色 = 森林\n"
		+ "• 蓝色 = 水塘\n"
		+ "• 浅绿色 = 草地\n\n"
		+ "操作方法\n"
		+ "• 把左边的动物卡片拖到右边的格子里\n"
		+ "• 右键点击格子可移除动物\n"
		+ "• 放好所有动物后点击"提交答案"\n\n"
		+ "线索词汇\n"
		+ "• "在X旁边" = 与X直接相邻（同区域内）\n"
		+ "• "在X的北/南边" = 比X更靠上/下的行\n"
		+ "• "在X的东/西边" = 比X更靠右/左的列"
	), "知道了！")

func _show_about() -> void:
	_show_modal_popup("关于 Zoodoku", (
		"Zoodoku · 动物数独\n\n"
		+ "一款以动物为主题的逻辑推理游戏。\n"
		+ "根据动物们的证词，推断出每只\n"
		+ "动物在格子里的正确位置。\n\n"
		+ "玩法灵感来自 Murdoku。\n"
		+ "动物素材来自 Kenney Animal Pack。\n\n"
		+ "把 .ogg 音乐文件放到\n"
		+ "assets/audio/ 文件夹即可启用音乐：\n"
		+ "• music_menu.ogg — 选关界面音乐\n"
		+ "• music_game.ogg — 游戏内音乐"
	), "关闭")

func _show_modal_popup(title_str: String, body_str: String, close_text: String) -> void:
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _warm_stylebox(C_CARD_BG, C_BORDER, 10))
	panel.custom_minimum_size = Vector2(460, 0)
	panel.position = Vector2(410, 80)
	overlay.add_child(panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var sp1: Control = Control.new()
	sp1.custom_minimum_size = Vector2(0, 4)
	vb.add_child(sp1)

	var title: Label = Label.new()
	title.text = title_str
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.62, 0.38, 0.10))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sep: HSeparator = HSeparator.new()
	vb.add_child(sep)

	var body: Label = Label.new()
	body.text = body_str
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", C_TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(420, 0)
	vb.add_child(body)

	var close_btn: Button = Button.new()
	close_btn.text = close_text
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.custom_minimum_size = Vector2(120, 38)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(overlay.queue_free)
	_style_button(close_btn, C_ACCENT)
	vb.add_child(close_btn)

	var sp2: Control = Control.new()
	sp2.custom_minimum_size = Vector2(0, 4)
	vb.add_child(sp2)

# ── Win screen ────────────────────────────────────────────────────────────────
func _show_win_screen() -> void:
	var lv: Dictionary = LEVELS[current_level]
	var is_last: bool = (current_level + 1 >= LEVELS.size())

	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _warm_stylebox(C_CARD_BG, C_BORDER, 12))
	panel.custom_minimum_size = Vector2(520, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	overlay.add_child(panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var sp1: Control = Control.new()
	sp1.custom_minimum_size = Vector2(0, 6)
	vb.add_child(sp1)

	var big: Label = Label.new()
	big.text = "通关！"
	big.add_theme_font_size_override("font_size", 52)
	big.add_theme_color_override("font_color", Color(0.82, 0.50, 0.12))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(big)

	var lv_lbl: Label = Label.new()
	lv_lbl.text = lv["level_name"] + " 完成"
	lv_lbl.add_theme_font_size_override("font_size", 15)
	lv_lbl.add_theme_color_override("font_color", C_TEXT2)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lv_lbl)

	var msg: Label = Label.new()
	msg.text = lv["win_text"]
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_color_override("font_color", C_TEXT)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(480, 0)
	vb.add_child(msg)

	var sep: HSeparator = HSeparator.new()
	vb.add_child(sep)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vb.add_child(btn_row)

	var retry_btn: Button = Button.new()
	retry_btn.text = "重玩本关"
	retry_btn.add_theme_font_size_override("font_size", 16)
	retry_btn.custom_minimum_size = Vector2(140, 44)
	retry_btn.pressed.connect(_load_level.bind(current_level))
	_style_button(retry_btn, Color(0.60, 0.52, 0.38), C_TEXT)
	btn_row.add_child(retry_btn)

	if not is_last:
		var next_btn: Button = Button.new()
		next_btn.text = "下一关 →"
		next_btn.add_theme_font_size_override("font_size", 16)
		next_btn.custom_minimum_size = Vector2(140, 44)
		next_btn.pressed.connect(_load_level.bind(current_level + 1))
		_style_button(next_btn, C_ACCENT)
		btn_row.add_child(next_btn)
	else:
		var all_done: Label = Label.new()
		all_done.text = "全部通关，你真厉害！"
		all_done.add_theme_font_size_override("font_size", 17)
		all_done.add_theme_color_override("font_color", Color(0.25, 0.60, 0.30))
		all_done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(all_done)

	var map_btn: Button = Button.new()
	map_btn.text = "← 返回地图"
	map_btn.add_theme_font_size_override("font_size", 14)
	map_btn.custom_minimum_size = Vector2(130, 40)
	map_btn.pressed.connect(_go_back_to_map)
	_style_button(map_btn, Color(0.44, 0.60, 0.76))
	btn_row.add_child(map_btn)

	var sp2: Control = Control.new()
	sp2.custom_minimum_size = Vector2(0, 6)
	vb.add_child(sp2)

	panel.pivot_offset = Vector2(260, 0)
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
