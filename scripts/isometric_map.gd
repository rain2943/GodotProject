extends Node3D

const GRID_SIZE := 9
const CELL_SIZE := 10.0
const ROAD_INDICES := [2, 6]
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const SIDEWALK_WIDTH := 1.4
const BUILDING_CATALOG := preload("res://scripts/building_catalog.gd")
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")
const MAP_MODULES := 90
const SIDEWALK_CLEARANCE_MODULES := 2
const BUILDING_LAYOUT := [
	{
		"building_id": "hanbit_8x8",
		"module_origin": Vector2i(50, 50),
	}
]

var asphalt_material: StandardMaterial3D
var lot_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var sidewalk_edge_material: StandardMaterial3D
var marking_material: StandardMaterial3D
var curb_material: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_floor_collision()
	_build_tile_grid()
	_build_buildings()


func _build_materials() -> void:
	asphalt_material = _texture_material(ASPHALT_TEXTURE)
	lot_material = _texture_material(CONCRETE_TEXTURE, Color("#77756f"))
	sidewalk_material = _texture_material(CONCRETE_TEXTURE, Color("#aaa79e"))
	sidewalk_edge_material = _color_material(Color("#64645f"))
	marking_material = _color_material(Color("#c8bd78"))
	curb_material = _color_material(Color("#8b8981"))


func _build_floor_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "MapFloor"
	body.position.y = -0.1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 0.2, MAP_SIZE)
	collision.shape = shape
	body.add_child(collision)


func _build_tile_grid() -> void:
	var half := (GRID_SIZE - 1) * 0.5
	for grid_x in GRID_SIZE:
		for grid_z in GRID_SIZE:
			var center := Vector3((grid_x - half) * CELL_SIZE, 0, (grid_z - half) * CELL_SIZE)
			var vertical_road := ROAD_INDICES.has(grid_x)
			var horizontal_road := ROAD_INDICES.has(grid_z)
			if vertical_road or horizontal_road:
				_build_road_cell(center, vertical_road, horizontal_road)
			else:
				_build_lot_cell(center, grid_x, grid_z)


func _build_lot_cell(center: Vector3, grid_x: int, grid_z: int) -> void:
	_add_plane("LotPaving", center, Vector2(CELL_SIZE, CELL_SIZE), lot_material, 0.0)
	if grid_x > 0 and ROAD_INDICES.has(grid_x - 1):
		_add_lot_sidewalk(center, Vector3.LEFT)
	if grid_x < GRID_SIZE - 1 and ROAD_INDICES.has(grid_x + 1):
		_add_lot_sidewalk(center, Vector3.RIGHT)
	if grid_z > 0 and ROAD_INDICES.has(grid_z - 1):
		_add_lot_sidewalk(center, Vector3.FORWARD)
	if grid_z < GRID_SIZE - 1 and ROAD_INDICES.has(grid_z + 1):
		_add_lot_sidewalk(center, Vector3.BACK)


func _build_road_cell(center: Vector3, vertical: bool, horizontal: bool) -> void:
	_add_plane("AsphaltRoad", center, Vector2(CELL_SIZE, CELL_SIZE), asphalt_material, 0.0)
	if vertical and horizontal:
		_add_crosswalks(center)
	elif vertical:
		_add_lane_dash(center, true)
	else:
		_add_lane_dash(center, false)


func _add_lane_dash(center: Vector3, vertical: bool) -> void:
	for offset in [-3.5, 0.0, 3.5]:
		var position := center
		if vertical:
			position.z += offset
			_add_plane("LaneDash", position, Vector2(0.12, 1.7), marking_material, 0.032)
		else:
			position.x += offset
			_add_plane("LaneDash", position, Vector2(1.7, 0.12), marking_material, 0.032)


func _add_crosswalks(center: Vector3) -> void:
	for stripe in range(-4, 5):
		var offset := stripe * 0.5
		_add_plane("Crosswalk", center + Vector3(offset, 0, -3.65), Vector2(0.28, 1.35), marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(offset, 0, 3.65), Vector2(0.28, 1.35), marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(-3.65, 0, offset), Vector2(1.35, 0.28), marking_material, 0.034)
		_add_plane("Crosswalk", center + Vector3(3.65, 0, offset), Vector2(1.35, 0.28), marking_material, 0.034)


func _add_lot_sidewalk(center: Vector3, direction: Vector3) -> void:
	var edge_offset := CELL_SIZE * 0.5 - SIDEWALK_WIDTH * 0.5
	var sidewalk_center := center + direction * edge_offset
	var inner_edge := center + direction * (CELL_SIZE * 0.5 - SIDEWALK_WIDTH)
	var curb_center := center + direction * (CELL_SIZE * 0.5 - 0.07)
	if abs(direction.x) > 0.5:
		_add_plane("Sidewalk", sidewalk_center, Vector2(SIDEWALK_WIDTH, CELL_SIZE), sidewalk_material, 0.022)
		_add_plane("SidewalkEdge", inner_edge, Vector2(0.08, CELL_SIZE), sidewalk_edge_material, 0.03)
		_add_plane("Curb", curb_center, Vector2(0.14, CELL_SIZE), curb_material, 0.034)
		for offset in [-3.75, -1.25, 1.25, 3.75]:
			_add_plane("PavingJoint", sidewalk_center + Vector3(0, 0, offset), Vector2(SIDEWALK_WIDTH, 0.035), sidewalk_edge_material, 0.031)
	else:
		_add_plane("Sidewalk", sidewalk_center, Vector2(CELL_SIZE, SIDEWALK_WIDTH), sidewalk_material, 0.022)
		_add_plane("SidewalkEdge", inner_edge, Vector2(CELL_SIZE, 0.08), sidewalk_edge_material, 0.03)
		_add_plane("Curb", curb_center, Vector2(CELL_SIZE, 0.14), curb_material, 0.034)
		for offset in [-3.75, -1.25, 1.25, 3.75]:
			_add_plane("PavingJoint", sidewalk_center + Vector3(offset, 0, 0), Vector2(0.035, SIDEWALK_WIDTH), sidewalk_edge_material, 0.031)


func _build_buildings() -> void:
	var occupied_modules := {}
	for placement in BUILDING_LAYOUT:
		var building_id: String = placement.get("building_id", "")
		var module_origin: Vector2i = placement.get("module_origin", Vector2i.ZERO)
		var definition := BUILDING_CATALOG.get_definition(building_id)
		var validation_error := _validate_building_placement(definition, module_origin, occupied_modules)
		if not validation_error.is_empty():
			push_warning("Skipping %s: %s" % [building_id, validation_error])
			continue
		var footprint: Vector2i = definition["footprint_modules"]
		for module_x in range(module_origin.x, module_origin.x + footprint.x):
			for module_z in range(module_origin.y, module_origin.y + footprint.y):
				occupied_modules[Vector2i(module_x, module_z)] = building_id
		_spawn_building(building_id, definition, module_origin)


func _validate_building_placement(definition: Dictionary, module_origin: Vector2i, occupied_modules: Dictionary) -> String:
	if not BUILDING_CATALOG.is_valid_definition(definition):
		return "invalid catalog definition"
	var footprint: Vector2i = definition["footprint_modules"]
	if module_origin.x < 0 or module_origin.y < 0:
		return "origin is outside the map"
	if module_origin.x + footprint.x > MAP_MODULES or module_origin.y + footprint.y > MAP_MODULES:
		return "footprint extends outside the map"
	for module_x in range(module_origin.x, module_origin.x + footprint.x):
		for module_z in range(module_origin.y, module_origin.y + footprint.y):
			var module_position := Vector2i(module_x, module_z)
			if occupied_modules.has(module_position):
				return "footprint overlaps another building"
			var cell_x := floori(float(module_x) / BUILDING_CATALOG.MODULES_PER_CELL)
			var cell_z := floori(float(module_z) / BUILDING_CATALOG.MODULES_PER_CELL)
			if ROAD_INDICES.has(cell_x) or ROAD_INDICES.has(cell_z):
				return "footprint overlaps a road cell"
			var local_x := module_x % BUILDING_CATALOG.MODULES_PER_CELL
			var local_z := module_z % BUILDING_CATALOG.MODULES_PER_CELL
			if ROAD_INDICES.has(cell_x - 1) and local_x < SIDEWALK_CLEARANCE_MODULES:
				return "footprint overlaps the left sidewalk reserve"
			if ROAD_INDICES.has(cell_x + 1) and local_x >= BUILDING_CATALOG.MODULES_PER_CELL - SIDEWALK_CLEARANCE_MODULES:
				return "footprint overlaps the right sidewalk reserve"
			if ROAD_INDICES.has(cell_z - 1) and local_z < SIDEWALK_CLEARANCE_MODULES:
				return "footprint overlaps the upper sidewalk reserve"
			if ROAD_INDICES.has(cell_z + 1) and local_z >= BUILDING_CATALOG.MODULES_PER_CELL - SIDEWALK_CLEARANCE_MODULES:
				return "footprint overlaps the lower sidewalk reserve"
	return ""


func _spawn_building(building_id: String, definition: Dictionary, module_origin: Vector2i) -> void:
	var footprint_modules: Vector2i = definition["footprint_modules"]
	var footprint_world := Vector2(footprint_modules) * BUILDING_CATALOG.MODULE_SIZE
	var center_x := -MAP_SIZE * 0.5 + (module_origin.x + footprint_modules.x * 0.5) * BUILDING_CATALOG.MODULE_SIZE
	var center_z := -MAP_SIZE * 0.5 + (module_origin.y + footprint_modules.y * 0.5) * BUILDING_CATALOG.MODULE_SIZE
	var origin := Vector3(center_x, 0, center_z)
	var texture := load(definition["texture_path"]) as Texture2D
	if texture == null:
		push_warning("Skipping %s: texture failed to load" % building_id)
		return

	var body := StaticBody3D.new()
	body.name = "%s_%d_%d" % [definition["node_name"], module_origin.x, module_origin.y]
	body.position = origin
	body.add_to_group("camera_occluder")
	add_child(body)

	var sprite := Sprite3D.new()
	sprite.name = "BuildingSprite"
	sprite.texture = texture
	var projected_footprint_width := (footprint_world.x + footprint_world.y) / sqrt(2.0)
	sprite.pixel_size = projected_footprint_width / float(definition["base_pixel_width"])
	sprite.position.y = (float(definition["ground_pixel_y"]) - texture.get_height() * 0.5) * sprite.pixel_size
	sprite.billboard = 1
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.alpha_cut = 0
	sprite.render_priority = 0
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var wall_inset: Vector2 = definition["wall_inset_modules"] * BUILDING_CATALOG.MODULE_SIZE
	var wall_size := footprint_world - wall_inset * 2.0
	var height := float(definition["height_world"])
	shape.size = Vector3(wall_size.x, height, wall_size.y)
	collision.position.y = height * 0.5
	collision.shape = shape
	body.add_child(collision)

	body.set_meta("footprint_modules", footprint_modules)
	body.set_meta("occlusion_lateral_limit", (wall_size.x + wall_size.y) / (2.0 * sqrt(2.0)))
	body.set_meta("occlusion_depth_limit", float(definition["occlusion_depth"]))


func _add_plane(node_name: String, position: Vector3, size: Vector2, material: StandardMaterial3D, height: float) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position + Vector3(0, height, 0)
	var mesh := PlaneMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


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
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
