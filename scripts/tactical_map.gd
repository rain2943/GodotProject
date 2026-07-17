extends Control

const UI_FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const EXTRACTION_TEXTURE := preload("res://assets/extraction/sewer_exit.png")

var world: Node3D
var player: Node3D
var extraction_position := Vector3.ZERO


func setup(world_node: Node3D, player_node: Node3D, extraction_world_position: Vector3) -> void:
	world = world_node
	player = player_node
	extraction_position = extraction_world_position


func _ready() -> void:
	name = "TacticalMap"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func toggle() -> void:
	visible = not visible
	if visible:
		queue_redraw()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var viewport_size := size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.005, 0.008, 0.009, 0.91))
	if not is_instance_valid(world):
		return
	var panel_size := Vector2(minf(840.0, viewport_size.x - 72.0), minf(610.0, viewport_size.y - 64.0))
	var panel_rect := Rect2((viewport_size - panel_size) * 0.5, panel_size)
	draw_style_box(_panel_style(), panel_rect)
	draw_string(UI_FONT, panel_rect.position + Vector2(26, 38), "종로 생존구역 전술 지도", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#e4e1d3"))
	draw_string(UI_FONT, panel_rect.position + Vector2(26, panel_rect.size.y - 18), "TAB 닫기   노란 표식: 하수구 탈출구", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#aaa995"))

	var data: Dictionary = world.call("get_map_snapshot_data")
	var grid_size := int(data.get("grid_size", 22))
	var map_side := minf(panel_rect.size.x - 70.0, panel_rect.size.y - 105.0)
	var map_rect := Rect2(panel_rect.position + Vector2((panel_rect.size.x - map_side) * 0.5, 55), Vector2.ONE * map_side)
	draw_rect(map_rect, Color("#181d1d"), true)
	var cell_size := map_rect.size.x / float(grid_size)
	var vertical_roads: Array = data.get("vertical_roads", [])
	var horizontal_roads: Array = data.get("horizontal_roads", [])
	var river_columns: Array = data.get("river_columns", [])
	for z in grid_size:
		for x in grid_size:
			var cell_rect := Rect2(map_rect.position + Vector2(x, z) * cell_size, Vector2.ONE * cell_size)
			if z < river_columns.size() and int(river_columns[z]) == x:
				draw_rect(cell_rect, Color("#254451"), true)
			elif vertical_roads.has(x) or horizontal_roads.has(z):
				draw_rect(cell_rect, Color("#444a49"), true)
			else:
				draw_rect(cell_rect, Color("#242b29"), true)

	for cell_value in data.get("building_cells", []):
		var cell: Vector2i = cell_value
		var rect := Rect2(map_rect.position + Vector2(cell.x, cell.y) * cell_size, Vector2.ONE * cell_size)
		draw_rect(rect.grow(-cell_size * 0.12), Color("#111515"), true)
		draw_rect(rect.grow(-cell_size * 0.12), Color("#59605b"), false, 1.0)

	var extraction_cell: Vector2i = world.call("world_to_map_cell", extraction_position)
	var extraction_center := map_rect.position + (Vector2(extraction_cell.x, extraction_cell.y) + Vector2.ONE * 0.5) * cell_size
	var marker_size := maxf(28.0, cell_size * 1.35)
	draw_circle(extraction_center, marker_size * 0.57, Color(0.95, 0.72, 0.18, 0.24))
	draw_texture_rect(EXTRACTION_TEXTURE, Rect2(extraction_center - Vector2.ONE * marker_size * 0.5, Vector2.ONE * marker_size), false)

	if is_instance_valid(player):
		var player_cell: Vector2i = world.call("world_to_map_cell", player.global_position)
		var player_center := map_rect.position + (Vector2(player_cell.x, player_cell.y) + Vector2.ONE * 0.5) * cell_size
		draw_circle(player_center, maxf(5.0, cell_size * 0.28), Color("#8fffd0"))
		draw_circle(player_center, maxf(8.0, cell_size * 0.43), Color(0.56, 1.0, 0.82, 0.38), false, 2.0)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.034, 0.034, 0.98)
	style.border_color = Color(0.35, 0.38, 0.36, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
