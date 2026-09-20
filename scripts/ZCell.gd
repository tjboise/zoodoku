extends Control

var row: int = 0
var col: int = 0
var area_type: int = 0   # 0=forest 1=pond 2=grassland
var object_type: String = ""
var game_node: Node = null

var placed_animal_id: String = ""
var _animal_icon: TextureRect = null
var _is_blocked: bool = false
var _hovered: bool = false

const AREA_COLOR: Array = [
	Color(0.12, 0.40, 0.18),
	Color(0.18, 0.46, 0.76),
	Color(0.26, 0.62, 0.22),
]
const AREA_COLOR_DARK: Array = [
	Color(0.07, 0.24, 0.10),
	Color(0.10, 0.28, 0.48),
	Color(0.15, 0.38, 0.12),
]
const OBJ_COLOR: Dictionary = {
	"tree":   Color(0.08, 0.30, 0.10),
	"rock":   Color(0.52, 0.48, 0.42),
	"flower": Color(0.88, 0.38, 0.62),
}

const CELL_SIZE: float = 130.0

func _ready() -> void:
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: _hovered = true;  queue_redraw())
	mouse_exited.connect( func() -> void: _hovered = false; queue_redraw())

	_animal_icon = TextureRect.new()
	_animal_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_animal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_animal_icon.size = Vector2(CELL_SIZE - 8.0, CELL_SIZE - 8.0)
	_animal_icon.position = Vector2(4, 4)
	_animal_icon.visible = false
	_animal_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_animal_icon)

func _draw() -> void:
	var s: Vector2 = size
	var base: Color = AREA_COLOR_DARK[area_type] if (_is_blocked and placed_animal_id == "") \
		else AREA_COLOR[area_type]
	draw_rect(Rect2(Vector2.ZERO, s), base)
	draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.08), false, 1.5)

	if object_type != "" and placed_animal_id == "":
		var oc: Color = OBJ_COLOR.get(object_type, Color.WHITE)
		var cx: float = s.x * 0.5
		var cy: float = s.y * 0.5
		match object_type:
			"tree":
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(cx, 14),
					Vector2(cx - 28, cy + 14),
					Vector2(cx + 28, cy + 14),
				])
				draw_colored_polygon(pts, oc)
				draw_rect(Rect2(Vector2(cx - 7, cy + 14), Vector2(14, 22)), Color(0.42, 0.28, 0.10))
			"rock":
				draw_circle(Vector2(cx, cy + 8), 30, oc)
				draw_circle(Vector2(cx - 16, cy + 16), 20, oc)
				draw_circle(Vector2(cx + 16, cy + 16), 22, oc)
			"flower":
				var petal: Color = Color(oc.r, oc.g, oc.b, 0.9)
				for i in 5:
					var ang: float = TAU * i / 5.0 - PI * 0.5
					draw_circle(Vector2(cx + cos(ang) * 22, cy + sin(ang) * 22), 14, petal)
				draw_circle(Vector2(cx, cy), 14, Color(0.98, 0.92, 0.30))

	if _is_blocked and placed_animal_id == "":
		draw_line(Vector2(20, 20), Vector2(s.x - 20, s.y - 20), Color(0, 0, 0, 0.22), 4)
		draw_line(Vector2(s.x - 20, 20), Vector2(20, s.y - 20), Color(0, 0, 0, 0.22), 4)

	if _hovered:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 0.6, 0.18))
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 0.4, 0.6), false, 2.5)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		if placed_animal_id != "" and game_node:
			game_node.remove_animal_from_cell(row, col)

func _get_drag_data(_at: Vector2):
	if placed_animal_id == "" or game_node == null:
		return null

	var animal_data: Dictionary = {}
	for a: Dictionary in game_node.ANIMALS:
		if a["id"] == placed_animal_id:
			animal_data = a
			break
	if animal_data.is_empty():
		return null

	var preview: Control = Control.new()
	preview.custom_minimum_size = Vector2(100, 100)
	var icon: TextureRect = TextureRect.new()
	icon.texture = game_node._load_texture(animal_data.get("image_path", ""))
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(100, 100)
	preview.add_child(icon)
	set_drag_preview(preview)

	return animal_data.duplicate()

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("id")

func _drop_data(_at: Vector2, data: Variant) -> void:
	if game_node:
		game_node.try_place_animal((data as Dictionary)["id"], row, col)

func place_animal(animal_id: String, texture: Texture2D) -> void:
	placed_animal_id = animal_id
	_animal_icon.texture = texture
	_animal_icon.visible = true
	queue_redraw()

func remove_animal() -> void:
	placed_animal_id = ""
	_animal_icon.visible = false
	_animal_icon.texture = null
	queue_redraw()

func set_blocked(blocked: bool) -> void:
	_is_blocked = blocked
	queue_redraw()
