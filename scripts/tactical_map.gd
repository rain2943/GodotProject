extends Control

const UI_FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
var world: Node3D
var player: Node3D
var extraction_positions: Array[Vector3] = []
var discovered_extraction_indices: Dictionary = {}


func setup(world_node: Node3D, player_node: Node3D, extraction_world_positions: Array[Vector3]) -> void:
	world = world_node
	player = player_node
	extraction_positions.assign(extraction_world_positions)
	discovered_extraction_indices.clear()


func discover_extraction(index: int) -> void:
	if index < 0 or index >= extraction_positions.size():
		return
	discovered_extraction_indices[index] = true
	queue_redraw()


func is_extraction_discovered(index: int) -> bool:
	return bool(discovered_extraction_indices.get(index, false))


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
	var panel_size := Vector2(minf(1040.0, viewport_size.x - 64.0), minf(720.0, viewport_size.y - 54.0))
	var panel_rect := Rect2((viewport_size - panel_size) * 0.5, panel_size)
	draw_style_box(_panel_style(), panel_rect)
	draw_string(UI_FONT, panel_rect.position + Vector2(28, 40), "종로 생존구역 전술 지도", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#e4e1d3"))
	draw_string(UI_FONT, panel_rect.position + Vector2(28, 65), "게임 화면과 같은 방향 · 청록: 현재 위치 · 노랑: 하수구", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#aebbb4"))

	var data: Dictionary = world.call("get_map_snapshot_data")
	var grid_size := int(data.get("grid_size", 22))
	var map_size := float(data.get("map_size", grid_size * 20.0))
	var map_rect := Rect2(panel_rect.position + Vector2(52, 78), panel_rect.size - Vector2(104, 142))
	var map_center := map_rect.get_center()
	var map_boundary := PackedVector2Array([
		map_center + Vector2(0, -map_rect.size.y * 0.49),
		map_center + Vector2(map_rect.size.x * 0.49, 0),
		map_center + Vector2(0, map_rect.size.y * 0.49),
		map_center + Vector2(-map_rect.size.x * 0.49, 0),
	])
	draw_colored_polygon(map_boundary, Color("#171d1c"))
	var vertical_roads: Array = data.get("vertical_roads", [])
	var horizontal_roads: Array = data.get("horizontal_roads", [])
	var river_columns: Array = data.get("river_columns", [])
	for z in grid_size:
		for x in grid_size:
			var cell_polygon := _cell_polygon(x, z, grid_size, map_rect)
			var fill_color := Color("#252c2a")
			if z < river_columns.size() and int(river_columns[z]) == x:
				fill_color = Color("#234653")
			elif vertical_roads.has(x) or horizontal_roads.has(z):
				fill_color = Color("#474d4b")
			draw_colored_polygon(cell_polygon, fill_color)
			draw_polyline(_closed_polygon(cell_polygon), Color(0.44, 0.5, 0.47, 0.12), 1.0)

	for cell_value in data.get("building_cells", []):
		var cell: Vector2i = cell_value
		var building_polygon := _shrink_polygon(_cell_polygon(cell.x, cell.y, grid_size, map_rect), 0.76)
		draw_colored_polygon(building_polygon, Color("#101514"))
		draw_polyline(_closed_polygon(building_polygon), Color("#69726d"), 1.2)

	var marker_size := clampf(map_rect.size.x / float(grid_size) * 0.86, 15.0, 28.0)
	var player_center := Vector2.ZERO
	if is_instance_valid(player):
		player_center = _world_position_to_map_point(player.global_position, map_rect, map_size)
	var nearest_extraction := Vector2.ZERO
	var nearest_distance := INF
	for extraction_index in extraction_positions.size():
		if not is_extraction_discovered(extraction_index):
			continue
		var extraction_position := extraction_positions[extraction_index]
		var extraction_center := _world_position_to_map_point(extraction_position, map_rect, map_size)
		if is_instance_valid(player):
			var distance := player.global_position.distance_to(extraction_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_extraction = extraction_center
		draw_circle(extraction_center, marker_size * 0.72, Color(0.95, 0.72, 0.18, 0.18))
		draw_circle(extraction_center, marker_size * 0.48, Color("#dcb64b"), false, 3.0)
		draw_line(
			extraction_center + Vector2(0, -marker_size * 0.35),
			extraction_center + Vector2(0, marker_size * 0.28),
			Color("#f0d77d"),
			2.0
		)
		draw_circle(extraction_center, 2.5, Color("#fff0a8"))

	if is_instance_valid(player):
		if nearest_distance < INF:
			draw_line(player_center, nearest_extraction, Color(0.87, 0.73, 0.3, 0.34), 2.0)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
		var outer_radius := marker_size + 5.0 + pulse * 6.0
		var inner_radius := maxf(8.0, marker_size * 0.42)
		draw_circle(player_center, outer_radius, Color(0.25, 1.0, 0.78, 0.16))
		draw_circle(player_center, outer_radius, Color.WHITE, false, 4.0)
		draw_circle(player_center, outer_radius - 3.0, Color("#5dffd0"), false, 2.0)
		draw_circle(player_center, inner_radius, Color("#07110f"))
		draw_circle(player_center, inner_radius * 0.72, Color("#65ffd2"))
		_draw_player_heading(player_center, marker_size * 1.35, map_rect)
		var sector := str(world.call("get_sector_label", player.global_position))
		var label_position := player_center + Vector2(outer_radius + 7.0, -outer_radius * 0.45)
		draw_string(UI_FONT, label_position, "내 위치  %s" % sector, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
		var footer := "현재 %s   ·   발견한 탈출구 %d / %d   ·   TAB 닫기" % [
			sector,
			discovered_extraction_indices.size(),
			extraction_positions.size(),
		]
		if nearest_distance < INF:
			footer = "현재 %s   ·   가장 가까운 발견 탈출구 %.0fm   ·   TAB 닫기" % [sector, nearest_distance]
		draw_string(UI_FONT, panel_rect.position + Vector2(28, panel_rect.size.y - 22), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d7d4b9"))
	if discovered_extraction_indices.is_empty():
		draw_string(UI_FONT, map_rect.get_center() + Vector2(-170, 6), "탈출구 미발견 · 직접 시야로 찾아야 합니다", HORIZONTAL_ALIGNMENT_CENTER, 340, 17, Color("#d9c579"))

	draw_polyline(_closed_polygon(map_boundary), Color("#7c8982"), 2.0)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.034, 0.034, 0.98)
	style.border_color = Color(0.35, 0.38, 0.36, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style


func _world_position_to_map_point(world_position: Vector3, map_rect: Rect2, map_size: float) -> Vector2:
	var half_map := map_size * 0.5
	var normalized := Vector2(
		clampf((world_position.x + half_map) / map_size, 0.0, 1.0),
		clampf((world_position.z + half_map) / map_size, 0.0, 1.0)
	)
	return _normalized_to_isometric(normalized, map_rect)


func _draw_player_heading(center: Vector2, length: float, map_rect: Rect2) -> void:
	if not is_instance_valid(player):
		return
	var forward_3d: Vector3 = player.get_meta("tactical_heading", -player.global_transform.basis.z)
	var direction := Vector2(
		forward_3d.x - forward_3d.z,
		(forward_3d.x + forward_3d.z) * (map_rect.size.y / map_rect.size.x)
	)
	if direction.length_squared() < 0.001:
		direction = Vector2.UP
	direction = direction.normalized()
	var tip := center + direction * length
	var side := Vector2(-direction.y, direction.x)
	var back := center + direction * (length * 0.25)
	var points := PackedVector2Array([
		tip,
		back + side * length * 0.32,
		back - side * length * 0.32,
	])
	draw_colored_polygon(points, Color("#8fffd0"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color("#06100e"), 2.0)


func _normalized_to_isometric(normalized: Vector2, map_rect: Rect2) -> Vector2:
	var center := map_rect.get_center()
	return center + Vector2(
		(normalized.x - normalized.y) * map_rect.size.x * 0.49,
		(normalized.x + normalized.y - 1.0) * map_rect.size.y * 0.49
	)


func _cell_polygon(x: int, z: int, grid_size: int, map_rect: Rect2) -> PackedVector2Array:
	var inverse_grid := 1.0 / float(grid_size)
	return PackedVector2Array([
		_normalized_to_isometric(Vector2(x, z) * inverse_grid, map_rect),
		_normalized_to_isometric(Vector2(x + 1, z) * inverse_grid, map_rect),
		_normalized_to_isometric(Vector2(x + 1, z + 1) * inverse_grid, map_rect),
		_normalized_to_isometric(Vector2(x, z + 1) * inverse_grid, map_rect),
	])


func _shrink_polygon(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var result := PackedVector2Array()
	for point in points:
		result.append(center.lerp(point, factor))
	return result


func _closed_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
