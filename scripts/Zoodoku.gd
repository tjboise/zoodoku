extends Control

# ── Level definitions ─────────────────────────────────────────────────────────
# area codes: 0=Forest  1=Pond  2=Grassland
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
	{"name": "森林", "color": Color(0.12, 0.40, 0.18)},
	{"name": "水塘", "color": Color(0.18, 0.46, 0.76)},
	{"name": "草地", "color": Color(0.26, 0.62, 0.22)},
]

# ── State ────────────────────────────────────────────────────────────────────
var current_level: int = 0
var grid_cells: Array = []
var animal_placements: Dictionary = {}
var card_nodes: Dictionary = {}
var _result_label: Label = null
var _texture_cache: Dictionary = {}

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
	_load_level(0)

func _load_level(idx: int) -> void:
	current_level = idx
	animal_placements = {}
	card_nodes = {}
	_result_label = null

	# Remove all existing children
	var children: Array = get_children()
	for child: Node in children:
		remove_child(child)
		child.queue_free()

	grid_cells = []
	_build_ui()

# ── UI builder ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var lv: Dictionary = LEVELS[current_level]

	# Background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.10, 0.12, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# ── Left panel ──────────────────────────────────────────────────────────
	var left: VBoxContainer = VBoxContainer.new()
	left.position = Vector2(14, 14)
	left.custom_minimum_size = Vector2(385, 700)
	left.add_theme_constant_override("separation", 10)
	add_child(left)

	# Level name
	var level_lbl: Label = Label.new()
	level_lbl.text = lv["level_name"]
	level_lbl.add_theme_font_size_override("font_size", 26)
	level_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	left.add_child(level_lbl)

	# Story panel
	var story_panel: PanelContainer = PanelContainer.new()
	story_panel.custom_minimum_size = Vector2(385, 0)
	left.add_child(story_panel)

	var story_vb: VBoxContainer = VBoxContainer.new()
	story_vb.add_theme_constant_override("separation", 4)
	story_panel.add_child(story_vb)

	var story_head: Label = Label.new()
	story_head.text = "• 案情"
	story_head.add_theme_font_size_override("font_size", 14)
	story_head.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	story_vb.add_child(story_head)

	var story_text: Label = Label.new()
	story_text.text = lv["story"]
	story_text.add_theme_font_size_override("font_size", 14)
	story_text.add_theme_color_override("font_color", Color(0.85, 0.88, 0.82))
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_vb.add_child(story_text)

	var cards_header: Label = Label.new()
	cards_header.text = "• 动物的证词（拖到右边格子放置）"
	cards_header.add_theme_font_size_override("font_size", 14)
	cards_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left.add_child(cards_header)

	var animals: Array = lv["animals"]
	for animal: Dictionary in animals:
		var card: Control = _make_animal_card(animal)
		left.add_child(card)
		card_nodes[animal["id"]] = card

	var hint: Label = Label.new()
	hint.text = "提示：右键点击格子可移除动物"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.5))
	left.add_child(hint)

	# ── Right panel / grid ──────────────────────────────────────────────────
	var cell_s: int = 130
	var gap: int = 4
	var grid_px: int = GRID_SIZE * cell_s + (GRID_SIZE - 1) * gap

	var right_x: int = 410
	var right_w: int = 1280 - right_x
	var grid_x: int = right_x + (right_w - grid_px) / 2

	_build_legend(grid_x, 20)

	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	grid.position = Vector2(grid_x, 60)
	add_child(grid)

	grid_cells = []
	for r: int in GRID_SIZE:
		var row_arr: Array = []
		for c: int in GRID_SIZE:
			var cell: Control = _make_cell(r, c)
			grid.add_child(cell)
			row_arr.append(cell)
		grid_cells.append(row_arr)

	var btn_x: int = grid_x + (grid_px - 200) / 2
	var submit_btn: Button = Button.new()
	submit_btn.text = "提交答案"
	submit_btn.add_theme_font_size_override("font_size", 20)
	submit_btn.custom_minimum_size = Vector2(200, 48)
	submit_btn.position = Vector2(btn_x, 620)
	submit_btn.pressed.connect(_check_solution)
	add_child(submit_btn)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 17)
	_result_label.position = Vector2(grid_x, 678)
	_result_label.custom_minimum_size = Vector2(grid_px, 40)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_label)

func _build_legend(gx: int, gy: int) -> void:
	var hb: HBoxContainer = HBoxContainer.new()
	hb.position = Vector2(gx, gy)
	hb.add_theme_constant_override("separation", 6)
	add_child(hb)
	for info: Dictionary in AREA_INFO:
		var swatch: ColorRect = ColorRect.new()
		swatch.color = info["color"]
		swatch.custom_minimum_size = Vector2(18, 18)
		hb.add_child(swatch)
		var lbl: Label = Label.new()
		lbl.text = info["name"] + "   "
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.85))
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
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
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
		_result_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.32))

# ── Win screen ────────────────────────────────────────────────────────────────
func _show_win_screen() -> void:
	var lv: Dictionary = LEVELS[current_level]
	var is_last: bool = (current_level + 1 >= LEVELS.size())

	# Full-screen dim overlay
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(dim)

	# Center panel
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	overlay.add_child(panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	# Spacer top
	var sp1: Control = Control.new()
	sp1.custom_minimum_size = Vector2(0, 8)
	vb.add_child(sp1)

	# "通关！"
	var big: Label = Label.new()
	big.text = "通关！"
	big.add_theme_font_size_override("font_size", 52)
	big.add_theme_color_override("font_color", Color(0.98, 0.88, 0.20))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(big)

	# Level name
	var lv_lbl: Label = Label.new()
	lv_lbl.text = lv["level_name"] + " 完成"
	lv_lbl.add_theme_font_size_override("font_size", 16)
	lv_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.65))
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lv_lbl)

	# Win message
	var msg: Label = Label.new()
	msg.text = lv["win_text"]
	msg.add_theme_font_size_override("font_size", 19)
	msg.add_theme_color_override("font_color", Color(0.88, 0.93, 0.88))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(480, 0)
	vb.add_child(msg)

	# Separator
	var sep: HSeparator = HSeparator.new()
	vb.add_child(sep)

	# Button row
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)

	var retry_btn: Button = Button.new()
	retry_btn.text = "重玩本关"
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.custom_minimum_size = Vector2(160, 48)
	retry_btn.pressed.connect(_load_level.bind(current_level))
	btn_row.add_child(retry_btn)

	if is_last:
		var all_done: Label = Label.new()
		all_done.text = "全部通关，你真厉害！"
		all_done.add_theme_font_size_override("font_size", 18)
		all_done.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
		all_done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(all_done)
	else:
		var next_btn: Button = Button.new()
		next_btn.text = "下一关 →"
		next_btn.add_theme_font_size_override("font_size", 18)
		next_btn.custom_minimum_size = Vector2(160, 48)
		next_btn.pressed.connect(_load_level.bind(current_level + 1))
		btn_row.add_child(next_btn)

	# Spacer bottom
	var sp2: Control = Control.new()
	sp2.custom_minimum_size = Vector2(0, 8)
	vb.add_child(sp2)

	# Pop-in animation
	panel.pivot_offset = Vector2(260, 0)
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
