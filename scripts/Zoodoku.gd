extends Control

const GRID_AREAS: Array = [
	[0, 0, 0, 1],
	[0, 0, 2, 1],
	[2, 2, 2, 1],
	[2, 2, 2, 2],
]
const GRID_SIZE: int = 4

const OBJECTS: Array = [
	{"row": 0, "col": 0, "type": "tree"},
	{"row": 1, "col": 3, "type": "rock"},
	{"row": 3, "col": 3, "type": "flower"},
]

const ANIMALS: Array = [
	{
		"id": "monkey",
		"name": "猴子",
		"clue": "我就在那棵大树旁边。",
		"solution_row": 0,
		"solution_col": 1,
		"image_path": "res://assets/sprites/animals/monkey.png",
	},
	{
		"id": "rabbit",
		"name": "兔子",
		"clue": "我在草地里，我在河马的北边。",
		"solution_row": 1,
		"solution_col": 2,
		"image_path": "res://assets/sprites/animals/rabbit.png",
	},
	{
		"id": "hippo",
		"name": "河马",
		"clue": "我在水塘里，我就在那块大石头旁边。",
		"solution_row": 2,
		"solution_col": 3,
		"image_path": "res://assets/sprites/animals/hippo.png",
	},
	{
		"id": "penguin",
		"name": "企鹅",
		"clue": "我在草地里，我在猴子的南边。",
		"solution_row": 3,
		"solution_col": 0,
		"image_path": "res://assets/sprites/animals/penguin.png",
	},
]

const AREA_INFO: Array = [
	{"name": "森林", "color": Color(0.12, 0.40, 0.18)},
	{"name": "水塘", "color": Color(0.18, 0.46, 0.76)},
	{"name": "草地", "color": Color(0.26, 0.62, 0.22)},
]

var grid_cells: Array = []
var animal_placements: Dictionary = {}
var card_nodes: Dictionary = {}
var _result_label: Label = null
var _texture_cache: Dictionary = {}

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

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.10, 0.12, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# ── Left panel ──
	var left: VBoxContainer = VBoxContainer.new()
	left.position = Vector2(14, 14)
	left.custom_minimum_size = Vector2(385, 700)
	left.add_theme_constant_override("separation", 10)
	add_child(left)

	var title: Label = Label.new()
	title.text = "Zoodoku"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	left.add_child(title)

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
	story_text.text = (
		"动物园管理员小美今天早上发现企鹅不见了！\n"
		+ "她找到其他三只动物问了情况。\n"
		+ "请根据它们的证词，找出企鹅藏在哪里。"
	)
	story_text.add_theme_font_size_override("font_size", 14)
	story_text.add_theme_color_override("font_color", Color(0.85, 0.88, 0.82))
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_vb.add_child(story_text)

	var cards_header: Label = Label.new()
	cards_header.text = "• 动物的证词（拖到右边格子放置）"
	cards_header.add_theme_font_size_override("font_size", 14)
	cards_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left.add_child(cards_header)

	for animal: Dictionary in ANIMALS:
		var card: Control = _make_animal_card(animal)
		left.add_child(card)
		card_nodes[animal["id"]] = card

	var hint: Label = Label.new()
	hint.text = "提示：右键点击格子可移除动物"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.5))
	left.add_child(hint)

	# ── Right panel / grid ──
	var cell_s: int = 130
	var gap: int = 4
	var grid_px: int = GRID_SIZE * cell_s + (GRID_SIZE - 1) * gap  # 532

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
	var cell_gd: GDScript = load("res://scripts/ZCell.gd")
	var cell: Control = cell_gd.new()
	cell.row = r
	cell.col = c
	var row_arr: Array = GRID_AREAS[r]
	cell.area_type = row_arr[c]
	cell.game_node = self
	for obj: Dictionary in OBJECTS:
		if obj["row"] == r and obj["col"] == c:
			cell.object_type = obj["type"]
			break
	return cell

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
	for a: Dictionary in ANIMALS:
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

func _check_solution() -> void:
	if animal_placements.size() < ANIMALS.size():
		_result_label.text = "还有动物没放置！请把所有动物都放到格子里。"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		return

	var correct: bool = true
	for animal: Dictionary in ANIMALS:
		if not animal_placements.has(animal["id"]):
			correct = false
			break
		var pos: Dictionary = animal_placements[animal["id"]]
		if pos["row"] != animal["solution_row"] or pos["col"] != animal["solution_col"]:
			correct = false
			break

	if correct:
		_result_label.text = "答对了！企鹅在草地的西南角晒太阳！小美终于找到它啦！"
		_result_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45))
	else:
		_result_label.text = "有些动物的位置不对，再想想看！"
		_result_label.add_theme_color_override("font_color", Color(0.95, 0.38, 0.32))
