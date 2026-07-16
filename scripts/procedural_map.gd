class_name ProceduralCityMap
extends Node3D

signal shelter_portal_entered

const GRID_SIZE := 22
const WORLD_SCALE := 2.0
const BASE_CELL_SIZE := 10.0
const CELL_SIZE := BASE_CELL_SIZE * WORLD_SCALE
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const SIDEWALK_WIDTH := 2.0 * WORLD_SCALE
const ISOMETRIC_VERTICAL_PROJECTION := 0.816496580927726
const BUILDING_CATALOG := preload("res://scripts/building_catalog.gd")
const LANDMARK_CATALOG := preload("res://scripts/urban_landmark_catalog.gd")
const PARK_HIGH_RISE_BUFFER_CELLS := 2
const PARK_MID_RISE_BUFFER_CELLS := 1
const TARGET_PARK_COUNT := 2
const TARGET_SUBWAY_COUNT := 2
const APARTMENT_HIGH_RISE_BUFFER_CELLS := 2
const FAR_DEPTH_OPEN_CELL := Vector2i(GRID_SIZE - 1, GRID_SIZE - 1)
const ROAD_SETBACK_MODULES := 2
const INTERIOR_SETBACK_MODULES := 1
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")
const RIVER_TEXTURE_PATH := "res://assets/tiles/river_water_generated.png"
const PARKING_TEXTURE_PATH := "res://assets/tiles/parking_lot_generated.png"
const SHELTER_TEXTURE_PATH := "res://assets/buildings/shelter_exterior_generated.png"
const BRIDGE_DECK_TEXTURE_PATH := "res://assets/tiles/bridge_deck_generated.png"
const GUARDRAIL_TEXTURE_PATH := "res://assets/tiles/guardrail_metal_generated.png"
const OPEN_LOT_TEXTURE_PATHS := [
	"res://assets/tiles/open_lot_demolition_generated.png",
	"res://assets/tiles/open_lot_courtyard_generated.png",
]
const VEHICLE_TEXTURES := {
	"sedan": preload("res://assets/vehicles/wrecked_sedan.png"),
	"truck": preload("res://assets/vehicles/wrecked_truck.png"),
	"bus": preload("res://assets/vehicles/wrecked_bus.png"),
}
const SHELTER_CELL := Vector2i(1, 1)

@export var map_seed: int = 0

var rng := RandomNumberGenerator.new()
var vertical_roads: Array[int] = []
var horizontal_roads: Array[int] = []
var river_columns := PackedInt32Array()
var river_center_x := 0
var building_cells := {}
var parking_cells := {}
var open_cells := {}
var waterfront_cells := {}
var park_cells: Array[Vector2i] = []
var playground_cells: Array[Vector2i] = []
var subway_cells: Array[Vector2i] = []
var apartment_origin := Vector2i(-1, -1)
var apartment_cells: Array[Vector2i] = []
var cell_zones := {}
var building_type_by_cell := {}
var portal_locked := false

var asphalt_material: StandardMaterial3D
var lot_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var sidewalk_edge_material: StandardMaterial3D
var marking_material: StandardMaterial3D
var curb_material: StandardMaterial3D
var water_material: StandardMaterial3D
var riverbank_material: StandardMaterial3D
var bridge_material: StandardMaterial3D
var vehicle_collision_material: StandardMaterial3D
var parking_material: StandardMaterial3D
var bridge_deck_material: StandardMaterial3D
var bridge_rail_material: StandardMaterial3D
var open_lot_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	if map_seed == 0:
		map_seed = GameState.map_seed
	rng.seed = map_seed
	_generate_layout()
	_build_materials()
	_build_floor_collision()
	_build_tiles()
	_build_zoned_lots()
	_build_shelter()


func _generate_layout() -> void:
	vertical_roads = [2, rng.randi_range(5, 6), rng.randi_range(9, 10), rng.randi_range(14, 15), 20]
	horizontal_roads = [2, rng.randi_range(5, 6), rng.randi_range(9, 10), rng.randi_range(14, 15), 20]
	vertical_roads.sort()
	horizontal_roads.sort()

	river_center_x = GRID_SIZE / 2 + rng.randi_range(-1, 0)
	for z in range(GRID_SIZE):
		river_columns.append(river_center_x)
	_select_apartment_complex_site()

	var eligible_cells: Array[Vector2i] = []
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var cell := Vector2i(x, z)
			if cell == SHELTER_CELL or _is_apartment_cell(cell) or _is_road_cell(cell) or _is_river_cell(cell):
				continue
			if _is_waterfront_cell(cell):
				waterfront_cells[cell] = true
				continue
			if cell == FAR_DEPTH_OPEN_CELL:
				open_cells[cell] = true
				continue
			eligible_cells.append(cell)

	_select_planned_landmarks(eligible_cells)
	_assign_zoning_districts(eligible_cells)
	for cell in eligible_cells:
		if _is_landmark_cell(cell):
			continue
		var zone := str(cell_zones.get(cell, "street_mixed"))
		var building_chance := float({
			"business_corner": 0.58,
			"street_mixed": 0.48,
			"residential_buffer": 0.32,
			"park_edge": 0.24,
			"service_interior": 0.34,
		}.get(zone, 0.42))
		if rng.randf() < building_chance:
			building_cells[cell] = true

	for cell in eligible_cells:
		if building_cells.has(cell):
			continue
		if _has_building_within(cell, 1):
			open_cells[cell] = true
		elif _touches_road(cell) and rng.randf() < 0.58:
			parking_cells[cell] = true
		else:
			open_cells[cell] = true


func _assign_zoning_districts(eligible_cells: Array[Vector2i]) -> void:
	for cell in eligible_cells:
		var zone := "service_interior"
		if _distance_to_cells(cell, park_cells) <= 1:
			zone = "park_edge"
		elif _distance_to_cells(cell, apartment_cells) <= 2:
			zone = "residential_buffer"
		elif _is_near_road_intersection(cell, 1):
			zone = "business_corner"
		elif _touches_road(cell):
			zone = "street_mixed"
		cell_zones[cell] = zone


func _select_apartment_complex_site() -> void:
	# A 2x2 estate is placed immediately north-west of an intersection. This
	# guarantees a full road on its south edge and another on its east edge.
	var candidates: Array[Vector2i] = []
	for road_x in vertical_roads:
		if absi(road_x - river_center_x) <= 3:
			continue
		for road_z in horizontal_roads:
			var origin := Vector2i(road_x - 2, road_z - 2)
			var site_cells: Array[Vector2i] = [
				origin,
				origin + Vector2i.RIGHT,
				origin + Vector2i.DOWN,
				origin + Vector2i.ONE,
			]
			var valid := true
			for cell in site_cells:
				if not _cell_in_bounds(cell) or cell == SHELTER_CELL or _is_road_cell(cell) or _is_river_cell(cell) or _is_waterfront_cell(cell):
					valid = false
					break
			if valid and _block_distance(origin, SHELTER_CELL) >= 4:
				candidates.append(origin)
	if candidates.is_empty():
		return
	candidates.shuffle()
	apartment_origin = candidates[0]
	apartment_cells = [
		apartment_origin,
		apartment_origin + Vector2i.RIGHT,
		apartment_origin + Vector2i.DOWN,
		apartment_origin + Vector2i.ONE,
	]


func _select_planned_landmarks(eligible_cells: Array[Vector2i]) -> void:
	var shuffled := eligible_cells.duplicate()
	shuffled.shuffle()
	for require_intersection_access in [true, false]:
		for cell in shuffled:
			if park_cells.size() >= TARGET_PARK_COUNT:
				break
			if not _touches_road(cell) or _block_distance(cell, SHELTER_CELL) < 3:
				continue
			if _distance_to_cells(cell, park_cells) < 5:
				continue
			if require_intersection_access and not _is_near_road_intersection(cell, 2):
				continue
			park_cells.append(cell)
		if park_cells.size() >= TARGET_PARK_COUNT:
			break

	for park_cell in park_cells:
		var playground_candidates := shuffled.filter(func(candidate: Vector2i) -> bool:
			var distance := _block_distance(candidate, park_cell)
			return distance >= 1 and distance <= 2 and _touches_road(candidate) and not _is_landmark_cell(candidate)
		)
		if not playground_candidates.is_empty():
			playground_cells.append(playground_candidates[0])

	for cell in shuffled:
		if subway_cells.size() >= TARGET_SUBWAY_COUNT:
			break
		if _is_landmark_cell(cell) or not _touches_road(cell):
			continue
		if not _is_near_road_intersection(cell, 1):
			continue
		if _distance_to_cells(cell, park_cells) <= 1 or _distance_to_cells(cell, subway_cells) < 4:
			continue
		subway_cells.append(cell)


func _is_landmark_cell(cell: Vector2i) -> bool:
	return park_cells.has(cell) or playground_cells.has(cell) or subway_cells.has(cell) or _is_apartment_cell(cell)


func _is_apartment_cell(cell: Vector2i) -> bool:
	return apartment_cells.has(cell)


func _block_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _distance_to_cells(cell: Vector2i, cells: Array[Vector2i]) -> int:
	if cells.is_empty():
		return 999
	var nearest := 999
	for other_cell in cells:
		nearest = mini(nearest, _block_distance(cell, other_cell))
	return nearest


func _is_near_road_intersection(cell: Vector2i, radius: int) -> bool:
	for offset_x in range(-radius, radius + 1):
		for offset_z in range(-radius, radius + 1):
			var candidate := cell + Vector2i(offset_x, offset_z)
			if vertical_roads.has(candidate.x) and horizontal_roads.has(candidate.y):
				return true
	return false


func _has_building_within(cell: Vector2i, radius: int) -> bool:
	for offset_x in range(-radius, radius + 1):
		for offset_z in range(-radius, radius + 1):
			if building_cells.has(cell + Vector2i(offset_x, offset_z)):
				return true
	return false


func _touches_road(cell: Vector2i) -> bool:
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _is_road_cell(cell + direction):
			return true
	return false


func _build_materials() -> void:
	asphalt_material = _texture_material(ASPHALT_TEXTURE)
	lot_material = _texture_material(CONCRETE_TEXTURE, Color("#77756f"))
	sidewalk_material = _texture_material(CONCRETE_TEXTURE, Color("#aaa79e"))
	sidewalk_edge_material = _color_material(Color("#64645f"))
	marking_material = _color_material(Color("#d1c87d"))
	curb_material = _color_material(Color("#8b8981"))
	if ResourceLoader.exists(RIVER_TEXTURE_PATH):
		water_material = _texture_material(load(RIVER_TEXTURE_PATH) as Texture2D, Color("#b9dce2"))
	else:
		water_material = _color_material(Color("#264d59"))
	water_material.metallic = 0.12
	water_material.roughness = 0.38
	if ResourceLoader.exists(PARKING_TEXTURE_PATH):
		parking_material = _texture_material(load(PARKING_TEXTURE_PATH) as Texture2D)
	else:
		parking_material = asphalt_material
	riverbank_material = _color_material(Color("#4f5146"))
	bridge_material = _color_material(Color("#575b5d"))
	if ResourceLoader.exists(BRIDGE_DECK_TEXTURE_PATH):
		bridge_deck_material = _texture_material(load(BRIDGE_DECK_TEXTURE_PATH) as Texture2D)
	else:
		bridge_deck_material = asphalt_material
	if ResourceLoader.exists(GUARDRAIL_TEXTURE_PATH):
		bridge_rail_material = _texture_material(load(GUARDRAIL_TEXTURE_PATH) as Texture2D)
	else:
		bridge_rail_material = _color_material(Color("#796d58"))
	bridge_rail_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for texture_path in OPEN_LOT_TEXTURE_PATHS:
		if ResourceLoader.exists(texture_path):
			open_lot_materials.append(_texture_material(load(texture_path) as Texture2D))
	if open_lot_materials.is_empty():
		open_lot_materials.append(lot_material)
	vehicle_collision_material = _color_material(Color(1.0, 0.02, 0.02, 0.46))
	vehicle_collision_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vehicle_collision_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vehicle_collision_material.no_depth_test = true
	vehicle_collision_material.render_priority = 120


func _build_floor_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "MapFloor"
	body.position.y = -0.1
	body.collision_layer = 1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 0.2, MAP_SIZE)
	collision.shape = shape
	body.add_child(collision)


func _build_tiles() -> void:
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var cell := Vector2i(x, z)
			var center := _cell_center(cell)
			var is_river := _is_river_cell(cell)
			var is_road := _is_road_cell(cell)
			if is_river and horizontal_roads.has(z):
				_build_river_cell(center, false)
				_build_bridge_cell(center, vertical_roads.has(x), horizontal_roads.has(z))
			elif is_river:
				_build_river_cell(center, true)
			elif is_road:
				_build_road_cell(center, vertical_roads.has(x), horizontal_roads.has(z))
			else:
				_build_lot_cell(center, cell)


func _build_lot_cell(center: Vector3, cell: Vector2i) -> void:
	_add_plane("LotPaving", center, Vector2(CELL_SIZE, CELL_SIZE), lot_material, 0.0)
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + direction
		if _is_road_cell(neighbor):
			_add_lot_sidewalk(center, Vector3(direction.x, 0, direction.y))


func _build_road_cell(center: Vector3, vertical: bool, horizontal: bool) -> void:
	_add_plane("AsphaltRoad", center, Vector2(CELL_SIZE, CELL_SIZE), asphalt_material, 0.01)
	if vertical and horizontal:
		_add_crosswalks(center)
	elif vertical:
		_add_lane_dash(center, true)
	else:
		_add_lane_dash(center, false)
	if vertical != horizontal and rng.randf() < 0.2:
		_spawn_road_cover_vehicle(center, vertical)


func _build_river_cell(center: Vector3, block_movement: bool) -> void:
	_add_plane("RiverWater", center, Vector2(CELL_SIZE, CELL_SIZE), water_material, -0.04)
	_add_plane("RiverBankLeft", center + Vector3(-4.65 * WORLD_SCALE, 0, 0), Vector2(0.7 * WORLD_SCALE, CELL_SIZE), riverbank_material, 0.015)
	_add_plane("RiverBankRight", center + Vector3(4.65 * WORLD_SCALE, 0, 0), Vector2(0.7 * WORLD_SCALE, CELL_SIZE), riverbank_material, 0.015)
	if block_movement:
		var blocker := StaticBody3D.new()
		blocker.name = "RiverBarrier"
		blocker.position = center + Vector3(0, 0.45, 0)
		blocker.collision_layer = 1
		add_child(blocker)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(CELL_SIZE - 0.8 * WORLD_SCALE, 0.9, CELL_SIZE)
		collision.shape = shape
		blocker.add_child(collision)


func _build_bridge_cell(center: Vector3, _vertical: bool, _horizontal: bool) -> void:
	_add_plane("BridgeDeck", center, Vector2(CELL_SIZE, CELL_SIZE), bridge_material, 0.13)
	_add_oriented_plane("BridgeRoadArt", center, Vector2(CELL_SIZE, 8.8 * WORLD_SCALE), bridge_deck_material, 0.15, false)
	_build_guardrails(center, false, 0.15, CELL_SIZE, 4.35 * WORLD_SCALE, true)


func _build_guardrails(
	center: Vector3,
	vertical: bool,
	deck_height: float,
	segment_length: float,
	half_width: float,
	with_collision: bool
) -> void:
	for side in [-1.0, 1.0]:
		var side_offset := Vector3(side * half_width, 0, 0) if vertical else Vector3(0, 0, side * half_width)
		var rail_size := Vector3(0.16, 0.14, segment_length) if vertical else Vector3(segment_length, 0.14, 0.16)
		for rail_height in [0.42, 0.72]:
			_add_box("GuardrailBeam", center + side_offset + Vector3(0, deck_height + rail_height, 0), rail_size, bridge_rail_material)
		for post_index in range(5):
			var post_offset := lerpf(-segment_length * 0.4, segment_length * 0.4, post_index / 4.0)
			var post_position := center + side_offset
			if vertical:
				post_position.z += post_offset
			else:
				post_position.x += post_offset
			_add_box("GuardrailPost", post_position + Vector3(0, deck_height + 0.39, 0), Vector3(0.2, 0.78, 0.2), bridge_rail_material)
		if with_collision:
			var collision_size := Vector3(0.32, 1.0, segment_length) if vertical else Vector3(segment_length, 1.0, 0.32)
			_add_static_collision_box("BridgeGuardCollision", center + side_offset + Vector3(0, deck_height + 0.48, 0), collision_size)
func _build_zoned_lots() -> void:
	_build_apartment_complex()
	for cell in park_cells:
		_spawn_landmark(cell, "pocket_park")
	for cell in playground_cells:
		_spawn_landmark(cell, "playground")
	for cell in subway_cells:
		_spawn_landmark(cell, "subway_entrance")
	for cell in waterfront_cells:
		_build_waterfront_lot(cell)
	for cell in parking_cells:
		_build_parking_lot(cell)
	for cell in building_cells:
		_try_build_building(cell)
	for cell in open_cells:
		_build_open_lot(cell)


func _build_apartment_complex() -> void:
	if apartment_cells.size() != 4:
		return
	var center := _cell_center(apartment_origin) + Vector3(CELL_SIZE * 0.5, 0, CELL_SIZE * 0.5)
	var apartment := _spawn_landmark_at(center, "apartment_complex", "site_%d_%d" % [apartment_origin.x, apartment_origin.y])
	if apartment == null:
		return
	apartment.add_to_group("urban_apartment_complex")
	apartment.add_to_group("camera_occluder")
	apartment.set_meta("site_origin", apartment_origin)
	apartment.set_meta("site_size_cells", Vector2i(2, 2))
	apartment.set_meta("resident_capacity", 120)
	apartment.set_meta("occlusion_lateral_limit", 25.5)
	apartment.set_meta("occlusion_depth_limit", 58.0)
	var apartment_sprite := apartment.get_node_or_null("LandmarkSprite") as Sprite3D
	if apartment_sprite:
		apartment_sprite.name = "BuildingSprite"
	var module_world_size := CELL_SIZE / float(LANDMARK_CATALOG.MODULES_PER_CELL)
	_add_apartment_gate(apartment, "MainEntrance", "main_entrance", Vector3(-4.2, 0.7, 9.0) * module_world_size, Vector3(4.4, 1.4, 1.3) * module_world_size)
	_add_apartment_gate(apartment, "ServiceExit", "service_exit", Vector3(9.0, 0.7, 4.5) * module_world_size, Vector3(1.3, 1.4, 4.0) * module_world_size)
	# Short paved aprons make both openings visibly meet their adjoining roads.
	_add_plane("ApartmentMainGateApron", center + Vector3(-4.2 * module_world_size, 0, 19.0), Vector2(8.8, 4.0), asphalt_material, 0.055)
	_add_plane("ApartmentServiceGateApron", center + Vector3(19.0, 0, 4.5 * module_world_size), Vector2(4.0, 8.0), asphalt_material, 0.055)


func _add_apartment_gate(parent: Node3D, node_name: String, gate_kind: String, local_position: Vector3, size: Vector3) -> void:
	var gate := Area3D.new()
	gate.name = node_name
	gate.position = local_position
	gate.collision_layer = 0
	gate.collision_mask = 0
	gate.add_to_group("apartment_gate")
	gate.set_meta("gate_kind", gate_kind)
	gate.set_meta("road_connected", true)
	parent.add_child(gate)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	gate.add_child(collision)


func _build_waterfront_lot(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	var promenade_size := CELL_SIZE - 0.6 * WORLD_SCALE
	_add_plane("RiverfrontPromenade", center, Vector2(promenade_size, promenade_size), sidewalk_material, 0.04)
	var river_side := signf(float(river_center_x - cell.x))
	var edge_position := center + Vector3(river_side * (CELL_SIZE * 0.5 - 0.55), 0, 0)
	_add_plane("RiverfrontEdge", edge_position, Vector2(0.65, promenade_size), riverbank_material, 0.055)


func _spawn_road_cover_vehicle(center: Vector3, vertical: bool) -> void:
	var vehicle_roll := rng.randf()
	var vehicle_type := "sedan"
	if vehicle_roll > 0.9:
		vehicle_type = "bus"
	elif vehicle_roll > 0.66:
		vehicle_type = "truck"
	var lane_offset := (3.0 if rng.randf() < 0.5 else -3.0) * WORLD_SCALE
	var travel_offset := rng.randf_range(-2.2, 2.2) * WORLD_SCALE
	var position := center + (Vector3(lane_offset, 0.1, travel_offset) if vertical else Vector3(travel_offset, 0.1, lane_offset))
	_spawn_vehicle("RoadCover_%d_%d" % [roundi(center.x), roundi(center.z)], vehicle_type, position)


func _build_parking_lot(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	var lot_art_size := CELL_SIZE - 0.6 * WORLD_SCALE
	_add_plane("ParkingLotArt", center, Vector2(lot_art_size, lot_art_size), parking_material, 0.045)
	var slots := [
		Vector3(-2.45 * WORLD_SCALE, 0.1, -2.15 * WORLD_SCALE),
		Vector3(-2.45 * WORLD_SCALE, 0.1, 2.15 * WORLD_SCALE),
		Vector3(2.45 * WORLD_SCALE, 0.1, -2.15 * WORLD_SCALE),
		Vector3(2.45 * WORLD_SCALE, 0.1, 2.15 * WORLD_SCALE),
	]
	var slot: Vector3 = slots[rng.randi_range(0, slots.size() - 1)]
	_spawn_vehicle("Parked_%d_%d" % [cell.x, cell.y], "sedan", center + slot)


func _build_open_lot(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	var material := open_lot_materials[rng.randi_range(0, open_lot_materials.size() - 1)]
	var lot_art_size := CELL_SIZE - 0.6 * WORLD_SCALE
	_add_plane("UrbanOpenLotArt", center, Vector2(lot_art_size, lot_art_size), material, 0.035)


func _try_build_building(cell: Vector2i) -> void:
	var modules_per_cell := BUILDING_CATALOG.MODULES_PER_CELL
	var zone := str(cell_zones.get(cell, "street_mixed"))
	var definitions: Array[Dictionary] = []
	for building_id in BUILDING_CATALOG.DEFINITIONS:
		var definition: Dictionary = BUILDING_CATALOG.get_definition(building_id)
		var footprint: Vector2i = definition.get("footprint_modules", Vector2i.ZERO)
		if footprint.x > modules_per_cell - 2 or footprint.y > modules_per_cell - 2:
			continue
		var height_class := str(definition.get("height_class", "mid"))
		var park_distance := _distance_to_cells(cell, park_cells)
		if height_class == "high":
			if zone != "business_corner" or park_distance <= PARK_HIGH_RISE_BUFFER_CELLS or _distance_to_cells(cell, apartment_cells) <= APARTMENT_HIGH_RISE_BUFFER_CELLS:
				continue
		elif height_class == "mid" and (park_distance <= PARK_MID_RISE_BUFFER_CELLS or zone == "residential_buffer"):
			continue
		definitions.append({
			"id": building_id,
			"definition": definition,
			"weight": float(definition.get("density_weight", 1.0)),
		})
	if definitions.is_empty():
		return
	var neighboring_types := {}
	for offset_x in range(-1, 2):
		for offset_z in range(-1, 2):
			var neighboring_id: String = str(building_type_by_cell.get(cell + Vector2i(offset_x, offset_z), ""))
			if not neighboring_id.is_empty():
				neighboring_types[neighboring_id] = true
	if definitions.size() > 1:
		var varied_definitions: Array[Dictionary] = definitions.filter(func(candidate: Dictionary) -> bool:
			return not neighboring_types.has(str(candidate["id"]))
		)
		if not varied_definitions.is_empty():
			definitions = varied_definitions
	var total_weight := 0.0
	for candidate in definitions:
		total_weight += float(candidate["weight"])
	var selection_roll := rng.randf() * total_weight
	var selected: Dictionary = definitions.back()
	for candidate in definitions:
		selection_roll -= float(candidate["weight"])
		if selection_roll <= 0.0:
			selected = candidate
			break
	var definition: Dictionary = selected["definition"]
	var footprint: Vector2i = definition["footprint_modules"]
	var cell_origin := cell * modules_per_cell
	var offset_x := _choose_parcel_axis_offset(
		modules_per_cell - footprint.x,
		_is_road_cell(cell + Vector2i.LEFT),
		_is_road_cell(cell + Vector2i.RIGHT)
	)
	var offset_y := _choose_parcel_axis_offset(
		modules_per_cell - footprint.y,
		_is_road_cell(cell + Vector2i.UP),
		_is_road_cell(cell + Vector2i.DOWN)
	)
	var module_origin := cell_origin + Vector2i(offset_x, offset_y)
	_spawn_building(selected["id"], definition, module_origin)
	building_type_by_cell[cell] = str(selected["id"])


func _choose_parcel_axis_offset(slack_modules: int, road_at_negative_edge: bool, road_at_positive_edge: bool) -> int:
	if slack_modules <= 0:
		return 0
	if road_at_negative_edge and not road_at_positive_edge:
		return mini(ROAD_SETBACK_MODULES, slack_modules)
	if road_at_positive_edge and not road_at_negative_edge:
		return maxi(0, slack_modules - ROAD_SETBACK_MODULES)
	var minimum := mini(INTERIOR_SETBACK_MODULES, slack_modules)
	var maximum := maxi(minimum, slack_modules - INTERIOR_SETBACK_MODULES)
	return rng.randi_range(minimum, maximum)


func _spawn_landmark(cell: Vector2i, landmark_id: String) -> void:
	_spawn_landmark_at(_cell_center(cell), landmark_id, "%d_%d" % [cell.x, cell.y])


func _spawn_landmark_at(center: Vector3, landmark_id: String, instance_suffix: String) -> Node3D:
	var definition := LANDMARK_CATALOG.get_definition(landmark_id)
	if definition.is_empty():
		return null
	var texture := load(str(definition["texture_path"])) as Texture2D
	if texture == null:
		return null
	var footprint_modules: Vector2i = definition["footprint_modules"]
	var module_world_size := CELL_SIZE / float(LANDMARK_CATALOG.MODULES_PER_CELL)
	var footprint_world := Vector2(footprint_modules) * module_world_size
	var landmark := Node3D.new()
	landmark.name = "%s_%s" % [str(definition["node_name"]), instance_suffix]
	landmark.position = center
	landmark.add_to_group("urban_landmark")
	landmark.add_to_group("urban_%s" % landmark_id)
	landmark.set_meta("landmark_kind", landmark_id)
	add_child(landmark)

	var sprite := Sprite3D.new()
	sprite.name = "LandmarkSprite"
	sprite.texture = texture
	var corners: Array = definition["footprint_corners_px"]
	var base_pixel_width := absf((corners[2] as Vector2).x - (corners[0] as Vector2).x)
	var projected_width := (footprint_world.x + footprint_world.y) / sqrt(2.0)
	sprite.pixel_size = projected_width / base_pixel_width
	sprite.offset.x = texture.get_width() * 0.5 - (corners[3] as Vector2).x
	sprite.position = Vector3(
		footprint_world.x * 0.5,
		((corners[3] as Vector2).y - texture.get_height() * 0.5) * sprite.pixel_size / ISOMETRIC_VERTICAL_PROJECTION,
		footprint_world.y * 0.5
	)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	landmark.add_child(sprite)

	for box_definition in definition.get("collision_boxes", []):
		var offset: Vector2 = box_definition["offset"]
		var size: Vector2 = box_definition["size"]
		var collision_height := float(box_definition.get("height", 1.2))
		_add_static_collision_box(
			"%sCollision" % str(definition["node_name"]),
			center + Vector3(offset.x * module_world_size, collision_height * 0.5, offset.y * module_world_size),
			Vector3(size.x * module_world_size, collision_height, size.y * module_world_size)
		)
	return landmark


func _spawn_building(building_id: String, definition: Dictionary, module_origin: Vector2i) -> void:
	var footprint_modules: Vector2i = definition["footprint_modules"]
	var module_world_size := CELL_SIZE / float(BUILDING_CATALOG.MODULES_PER_CELL)
	var footprint_world := Vector2(footprint_modules) * module_world_size
	var center_x := -MAP_SIZE * 0.5 + (module_origin.x + footprint_modules.x * 0.5) * module_world_size
	var center_z := -MAP_SIZE * 0.5 + (module_origin.y + footprint_modules.y * 0.5) * module_world_size
	var texture := load(definition["texture_path"]) as Texture2D
	if texture == null:
		return
	var body := StaticBody3D.new()
	body.name = "%s_%d_%d" % [building_id, module_origin.x, module_origin.y]
	body.position = Vector3(center_x, 0, center_z)
	body.add_to_group("camera_occluder")
	body.collision_layer = 1
	body.set_meta("building_id", building_id)
	body.set_meta("height_class", str(definition.get("height_class", "mid")))
	body.set_meta("planning_cell", Vector2i(
		module_origin.x / BUILDING_CATALOG.MODULES_PER_CELL,
		module_origin.y / BUILDING_CATALOG.MODULES_PER_CELL
	))
	var planning_cell: Vector2i = body.get_meta("planning_cell")
	body.set_meta("zoning_district", str(cell_zones.get(planning_cell, "street_mixed")))
	body.set_meta("road_frontage", _get_road_frontage(planning_cell))
	add_child(body)
	var sprite := Sprite3D.new()
	sprite.name = "BuildingSprite"
	sprite.texture = texture
	var corners: Array = definition["footprint_corners_px"]
	var base_pixel_width := absf((corners[2] as Vector2).x - (corners[0] as Vector2).x)
	var projected_width := (footprint_world.x + footprint_world.y) / sqrt(2.0)
	sprite.pixel_size = projected_width / base_pixel_width
	sprite.offset.x = texture.get_width() * 0.5 - (corners[3] as Vector2).x
	sprite.position = Vector3(footprint_world.x * 0.5, ((corners[3] as Vector2).y - texture.get_height() * 0.5) * sprite.pixel_size / ISOMETRIC_VERTICAL_PROJECTION, footprint_world.y * 0.5)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)
	var collision := CollisionShape3D.new()
	collision.name = "BuildingCollision"
	var shape := BoxShape3D.new()
	var height := float(definition["height_world"]) * WORLD_SCALE
	shape.size = Vector3(footprint_world.x, height, footprint_world.y)
	collision.position.y = height * 0.5
	collision.shape = shape
	body.add_child(collision)
	body.set_meta("occlusion_lateral_limit", (footprint_world.x + footprint_world.y) / (2.0 * sqrt(2.0)))
	body.set_meta("occlusion_depth_limit", float(definition["occlusion_depth"]) * WORLD_SCALE)


func _get_road_frontage(cell: Vector2i) -> PackedStringArray:
	var frontage := PackedStringArray()
	if _is_road_cell(cell + Vector2i.LEFT):
		frontage.append("west")
	if _is_road_cell(cell + Vector2i.RIGHT):
		frontage.append("east")
	if _is_road_cell(cell + Vector2i.UP):
		frontage.append("north")
	if _is_road_cell(cell + Vector2i.DOWN):
		frontage.append("south")
	return frontage


func _spawn_vehicle(node_name: String, vehicle_type: String, position: Vector3) -> void:
	var texture := VEHICLE_TEXTURES.get(vehicle_type) as Texture2D
	if texture == null:
		return
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	body.add_to_group("vehicle_obstacle")
	add_child(body)
	var sprite := Sprite3D.new()
	sprite.name = "VehicleSprite"
	sprite.texture = texture
	var width := 4.6 if vehicle_type == "sedan" else (6.2 if vehicle_type == "truck" else 7.8)
	sprite.pixel_size = width / float(texture.get_width())
	sprite.position.y = texture.get_height() * sprite.pixel_size * 0.5 / ISOMETRIC_VERTICAL_PROJECTION
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.render_priority = 5
	body.add_child(sprite)
	var footprint := Vector3(3.9, 1.25, 1.8)
	if vehicle_type == "truck":
		footprint = Vector3(5.4, 1.8, 2.2)
	elif vehicle_type == "bus":
		footprint = Vector3(7.1, 2.2, 2.35)
	var collision := CollisionShape3D.new()
	collision.name = "VehicleCollision"
	var shape := BoxShape3D.new()
	shape.size = footprint
	collision.position.y = footprint.y * 0.5 - position.y
	collision.rotation.y = deg_to_rad(45.0)
	collision.shape = shape
	body.add_child(collision)
	var debug_mesh := MeshInstance3D.new()
	debug_mesh.name = "VehicleCollisionDebug"
	debug_mesh.position = collision.position
	debug_mesh.rotation = collision.rotation
	var box := BoxMesh.new()
	box.size = footprint + Vector3(0.03, 0.03, 0.03)
	box.material = vehicle_collision_material
	debug_mesh.mesh = box
	body.add_child(debug_mesh)


func _build_shelter() -> void:
	var center := _cell_center(SHELTER_CELL)
	var shelter := StaticBody3D.new()
	shelter.name = "ShelterSafehouse"
	shelter.position = center
	shelter.collision_layer = 1
	shelter.add_to_group("safe_zone")
	shelter.add_to_group("camera_occluder")
	add_child(shelter)
	if ResourceLoader.exists(SHELTER_TEXTURE_PATH):
		var sprite := Sprite3D.new()
		sprite.name = "BuildingSprite"
		sprite.texture = load(SHELTER_TEXTURE_PATH) as Texture2D
		sprite.pixel_size = 0.0088 * WORLD_SCALE
		sprite.position.y = 4.3 * WORLD_SCALE
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.transparent = true
		sprite.shaded = false
		sprite.no_depth_test = true
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shelter.add_child(sprite)
	var shelter_collision := CollisionShape3D.new()
	shelter_collision.name = "ShelterCollision"
	var shelter_shape := BoxShape3D.new()
	shelter_shape.size = Vector3(6.0, 4.2, 6.0) * WORLD_SCALE
	shelter_collision.position.y = 2.1 * WORLD_SCALE
	shelter_collision.shape = shelter_shape
	shelter.add_child(shelter_collision)
	shelter.set_meta("occlusion_lateral_limit", 5.0 * WORLD_SCALE)
	shelter.set_meta("occlusion_depth_limit", 9.0 * WORLD_SCALE)
	var light := OmniLight3D.new()
	light.position = Vector3(3.4, 1.2, 0) * WORLD_SCALE
	light.light_color = Color("#5dffb2")
	light.light_energy = 2.0
	light.omni_range = 6.0 * WORLD_SCALE
	shelter.add_child(light)
	var portal := Area3D.new()
	portal.name = "ShelterPortal"
	portal.position = Vector3(3.6, 0.9, 0) * WORLD_SCALE
	portal.collision_layer = 0
	portal.collision_mask = 1
	shelter.add_child(portal)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.8, 2.2) * WORLD_SCALE
	collision.shape = shape
	portal.add_child(collision)
	portal.body_entered.connect(_on_shelter_portal_body_entered)


func _on_shelter_portal_body_entered(body: Node3D) -> void:
	if portal_locked or body.name != "Player":
		return
	portal_locked = true
	shelter_portal_entered.emit()


func get_shelter_exit_position() -> Vector3:
	return _cell_center(SHELTER_CELL) + Vector3(6.2 * WORLD_SCALE, 0.78, 0)


func get_map_limit() -> float:
	return MAP_SIZE * 0.5 - 1.5


func is_position_in_safe_zone(world_position: Vector3) -> bool:
	var shelter_center := _cell_center(SHELTER_CELL)
	return Vector2(world_position.x, world_position.z).distance_to(Vector2(shelter_center.x, shelter_center.z)) <= 6.0 * WORLD_SCALE


func find_nearest_open_position(world_position: Vector3) -> Vector3:
	var start := _world_to_cell(world_position)
	if _cell_in_bounds(start) and not _is_river_cell(start) and not building_cells.has(start):
		return world_position
	for radius in range(GRID_SIZE):
		for x in range(start.x - radius, start.x + radius + 1):
			for z in range(start.y - radius, start.y + radius + 1):
				var cell := Vector2i(x, z)
				if _cell_in_bounds(cell) and not _is_river_cell(cell) and not building_cells.has(cell):
					var result := _cell_center(cell)
					result.y = world_position.y
					return result
	return Vector3(0, world_position.y, 0)


func _is_road_cell(cell: Vector2i) -> bool:
	return _cell_in_bounds(cell) and (vertical_roads.has(cell.x) or horizontal_roads.has(cell.y))


func _is_river_cell(cell: Vector2i) -> bool:
	return _cell_in_bounds(cell) and river_columns[cell.y] == cell.x


func _is_waterfront_cell(cell: Vector2i) -> bool:
	return _cell_in_bounds(cell) and abs(cell.x - river_center_x) == 1


func _cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE and cell.y < GRID_SIZE


func _cell_center(cell: Vector2i) -> Vector3:
	return Vector3(-MAP_SIZE * 0.5 + (cell.x + 0.5) * CELL_SIZE, 0, -MAP_SIZE * 0.5 + (cell.y + 0.5) * CELL_SIZE)


func _world_to_cell(position: Vector3) -> Vector2i:
	return Vector2i(floori((position.x + MAP_SIZE * 0.5) / CELL_SIZE), floori((position.z + MAP_SIZE * 0.5) / CELL_SIZE))


func _add_lane_dash(center: Vector3, vertical: bool) -> void:
	for base_offset in [-3.5, 0.0, 3.5]:
		var offset: float = float(base_offset) * WORLD_SCALE
		var position := center
		if vertical:
			position.z += offset
			_add_plane("LaneDash", position, Vector2(0.12, 1.7) * WORLD_SCALE, marking_material, 0.032)
		else:
			position.x += offset
			_add_plane("LaneDash", position, Vector2(1.7, 0.12) * WORLD_SCALE, marking_material, 0.032)


func _add_crosswalks(center: Vector3) -> void:
	for stripe in range(-4, 5):
		var offset := stripe * 0.5 * WORLD_SCALE
		var edge_offset := 3.65 * WORLD_SCALE
		_add_plane("Crosswalk", center + Vector3(offset, 0, -edge_offset), Vector2(0.28, 1.35) * WORLD_SCALE, marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(offset, 0, edge_offset), Vector2(0.28, 1.35) * WORLD_SCALE, marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(-edge_offset, 0, offset), Vector2(1.35, 0.28) * WORLD_SCALE, marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(edge_offset, 0, offset), Vector2(1.35, 0.28) * WORLD_SCALE, marking_material, 0.034)


func _add_lot_sidewalk(center: Vector3, direction: Vector3) -> void:
	var edge_offset := CELL_SIZE * 0.5 - SIDEWALK_WIDTH * 0.5
	var sidewalk_center := center + direction * edge_offset
	var curb_center := center + direction * (CELL_SIZE * 0.5 - 0.07 * WORLD_SCALE)
	if abs(direction.x) > 0.5:
		_add_plane("Sidewalk", sidewalk_center, Vector2(SIDEWALK_WIDTH, CELL_SIZE), sidewalk_material, 0.022)
		_add_plane("Curb", curb_center, Vector2(0.14 * WORLD_SCALE, CELL_SIZE), curb_material, 0.034)
	else:
		_add_plane("Sidewalk", sidewalk_center, Vector2(CELL_SIZE, SIDEWALK_WIDTH), sidewalk_material, 0.022)
		_add_plane("Curb", curb_center, Vector2(CELL_SIZE, 0.14 * WORLD_SCALE), curb_material, 0.034)


func _add_plane(node_name: String, position: Vector3, size: Vector2, material: Material, height: float) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position + Vector3(0, height, 0)
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_oriented_plane(
	node_name: String,
	position: Vector3,
	size: Vector2,
	material: Material,
	height: float,
	vertical: bool
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position + Vector3(0, height, 0)
	if vertical:
		instance.rotation.y = PI * 0.5
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_static_collision_box(node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_static_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	_add_box_to(self, node_name, position, size, material)


func _add_box_to(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	parent.add_child(instance)


func _texture_material(texture: Texture2D, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness = 0.96
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _color_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material
