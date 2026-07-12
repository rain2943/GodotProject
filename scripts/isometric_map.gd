extends Node3D

const GRID_SIZE := 9
const CELL_SIZE := 10.0
const ROAD_INDICES := [2, 6]
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const SIDEWALK_WIDTH := 2.0
const ISOMETRIC_VERTICAL_PROJECTION := 0.816496580927726
const SHOW_VEHICLE_COLLISION_DEBUG := true
const BUILDING_CATALOG := preload("res://scripts/building_catalog.gd")
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")
const VEHICLE_TEXTURES := {
	"sedan": preload("res://assets/vehicles/wrecked_sedan.png"),
	"truck": preload("res://assets/vehicles/wrecked_truck.png"),
	"bus": preload("res://assets/vehicles/wrecked_bus.png"),
}
const MAP_MODULES := 90
const SIDEWALK_CLEARANCE_MODULES := 2
const ALLEY_SEGMENTS := [
	Rect2i(48, 30, 2, 30),
	Rect2i(30, 38, 18, 2),
]
const BUILDING_LAYOUT := [
	{
		"building_id": "academy_tower_6x4",
		"module_origin": Vector2i(42, 54),
	},
	{
		"building_id": "hanbit_apartment_8x4",
		"module_origin": Vector2i(50, 54),
	}
]
const VEHICLE_PLACEMENTS := [
	{
		"type": "sedan",
		"position": Vector3(-21.8, 0.1, -8.6),
		"visual_width": 4.8,
		"collision": Vector2(3.9, 1.85),
		"height": 1.2,
	},
	{
		"type": "sedan",
		"position": Vector3(-16.4, 0.1, 20.7),
		"visual_width": 4.5,
		"collision": Vector2(3.7, 1.8),
		"height": 1.2,
	},
	{
		"type": "truck",
		"position": Vector3(23.2, 0.1, -16.2),
		"visual_width": 6.5,
		"collision": Vector2(5.7, 2.2),
		"height": 1.8,
	},
	{
		"type": "truck",
		"position": Vector3(15.6, 0.1, 23.1),
		"visual_width": 6.1,
		"collision": Vector2(5.3, 2.15),
		"height": 1.75,
	},
	{
		"type": "bus",
		"position": Vector3(-22.8, 0.1, 17.2),
		"visual_width": 8.6,
		"collision": Vector2(7.7, 2.35),
		"height": 2.2,
	},
	{
		"type": "bus",
		"position": Vector3(20.8, 0.1, -22.2),
		"visual_width": 8.3,
		"collision": Vector2(7.45, 2.35),
		"height": 2.2,
	},
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
	_build_alleys()
	_build_buildings()
	_build_vehicles()


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


func _build_alleys() -> void:
	for segment in ALLEY_SEGMENTS:
		var center_modules := Vector2(segment.position) + Vector2(segment.size) * 0.5
		var center := Vector3(
			-MAP_SIZE * 0.5 + center_modules.x * BUILDING_CATALOG.MODULE_SIZE,
			0,
			-MAP_SIZE * 0.5 + center_modules.y * BUILDING_CATALOG.MODULE_SIZE
		)
		var size := Vector2(segment.size) * BUILDING_CATALOG.MODULE_SIZE
		_add_plane("AlleyAsphalt", center, size, asphalt_material, 0.041)
		if segment.size.x < segment.size.y:
			_add_plane("AlleyGutter", center + Vector3(-size.x * 0.5 + 0.08, 0, 0), Vector2(0.16, size.y), curb_material, 0.045)
			_add_plane("AlleyGutter", center + Vector3(size.x * 0.5 - 0.08, 0, 0), Vector2(0.16, size.y), curb_material, 0.045)
		else:
			_add_plane("AlleyGutter", center + Vector3(0, 0, -size.y * 0.5 + 0.08), Vector2(size.x, 0.16), curb_material, 0.045)
			_add_plane("AlleyGutter", center + Vector3(0, 0, size.y * 0.5 - 0.08), Vector2(size.x, 0.16), curb_material, 0.045)


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
			if _is_alley_module(module_position):
				return "footprint overlaps an alley"
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


func _is_alley_module(module_position: Vector2i) -> bool:
	for segment in ALLEY_SEGMENTS:
		if segment.has_point(module_position):
			return true
	return false


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
	var footprint_corners: Array = definition["footprint_corners_px"]
	var left_corner: Vector2 = footprint_corners[0]
	var right_corner: Vector2 = footprint_corners[2]
	var front_corner: Vector2 = footprint_corners[3]
	var base_pixel_width := absf(right_corner.x - left_corner.x)
	var projected_footprint_width := (footprint_world.x + footprint_world.y) / sqrt(2.0)
	sprite.pixel_size = projected_footprint_width / base_pixel_width
	sprite.position.x = footprint_world.x * 0.5
	sprite.position.y = (front_corner.y - texture.get_height() * 0.5) * sprite.pixel_size / ISOMETRIC_VERTICAL_PROJECTION
	sprite.position.z = footprint_world.y * 0.5
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
	var height := float(definition["height_world"])
	shape.size = Vector3(footprint_world.x, height, footprint_world.y)
	collision.position.y = height * 0.5
	collision.shape = shape
	body.add_child(collision)

	body.set_meta("footprint_modules", footprint_modules)
	body.set_meta("collision_footprint_world", footprint_world)
	body.set_meta("footprint_corners_px", footprint_corners)
	body.set_meta("occlusion_lateral_limit", (footprint_world.x + footprint_world.y) / (2.0 * sqrt(2.0)))
	body.set_meta("occlusion_depth_limit", float(definition["occlusion_depth"]))


func _build_vehicles() -> void:
	for index in VEHICLE_PLACEMENTS.size():
		var placement: Dictionary = VEHICLE_PLACEMENTS[index]
		var vehicle_type: String = placement.get("type", "")
		var texture := VEHICLE_TEXTURES.get(vehicle_type) as Texture2D
		if texture == null:
			push_warning("Skipping vehicle %s: texture missing" % vehicle_type)
			continue
		_spawn_vehicle(index, placement, texture)


func _spawn_vehicle(index: int, placement: Dictionary, texture: Texture2D) -> void:
	var body := StaticBody3D.new()
	body.name = "Vehicle_%s_%02d" % [placement.get("type", "prop"), index]
	body.position = placement.get("position", Vector3.ZERO)
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("vehicle_obstacle")
	add_child(body)

	var sprite := Sprite3D.new()
	sprite.name = "VehicleSprite"
	sprite.texture = texture
	var visual_width := float(placement.get("visual_width", 4.0))
	sprite.pixel_size = visual_width / float(texture.get_width())
	sprite.position.y = (float(texture.get_height()) * sprite.pixel_size * 0.5) / ISOMETRIC_VERTICAL_PROJECTION
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.render_priority = 5
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)

	var footprint: Vector2 = placement.get("collision", Vector2(3.5, 1.8))
	var height := float(placement.get("height", 1.2))
	_add_vehicle_silhouette_collision(body, texture, sprite.pixel_size, height, footprint)
	body.set_meta("collision_footprint_world", footprint)
	body.set_meta("collision_rotation_degrees", 45.0)

	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0, 0, 0, 0.3)
	var shadow_mesh := PlaneMesh.new()
	shadow_mesh.size = Vector2(footprint.x * 1.04, footprint.y * 1.18)
	shadow_mesh.material = shadow_material
	var shadow := MeshInstance3D.new()
	shadow.name = "VehicleShadow"
	shadow.position.y = 0.025
	shadow.rotation.y = deg_to_rad(45.0)
	shadow.mesh = shadow_mesh
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(shadow)


func _add_vehicle_silhouette_collision(
	body: StaticBody3D,
	texture: Texture2D,
	pixel_size: float,
	height: float,
	fallback_footprint: Vector2
) -> void:
	var image := texture.get_image()
	if image == null or image.is_empty():
		_add_vehicle_collision_strip(body, Vector3.ZERO, fallback_footprint, height, 0, null)
		return

	var image_width := image.get_width()
	var image_height := image.get_height()
	var band_count := 12
	var band_height := ceili(float(image_height) / float(band_count))
	var length_axis := Vector3(1.0, 0.0, -1.0).normalized()
	var depth_axis := Vector3(-1.0, 0.0, -1.0).normalized()
	var debug_material: StandardMaterial3D
	if SHOW_VEHICLE_COLLISION_DEBUG:
		debug_material = StandardMaterial3D.new()
		debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_material.albedo_color = Color(1.0, 0.03, 0.03, 0.38)
		debug_material.no_depth_test = true
	var strip_index := 0
	for band_index in band_count:
		var y_start := band_index * band_height
		var y_end := mini(y_start + band_height, image_height)
		if y_start >= y_end:
			continue
		var min_x := image_width
		var max_x := -1
		var required_pixels := maxi(1, ceili(float(y_end - y_start) * 0.18))
		for x in image_width:
			var opaque_pixels := 0
			for y in range(y_start, y_end):
				if image.get_pixel(x, y).a >= 0.28:
					opaque_pixels += 1
			if opaque_pixels >= required_pixels:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
		if max_x < min_x:
			continue
		min_x = maxi(0, min_x - 2)
		max_x = mini(image_width - 1, max_x + 2)
		var strip_width := float(max_x - min_x + 1) * pixel_size
		var strip_depth := float(y_end - y_start) * pixel_size * sqrt(3.0) + 0.04
		var horizontal_center := (float(min_x + max_x + 1) * 0.5 - float(image_width) * 0.5) * pixel_size
		var vertical_center := float(y_start + y_end) * 0.5
		var depth_from_bottom := (float(image_height) - vertical_center) * pixel_size * sqrt(3.0)
		var center := length_axis * horizontal_center + depth_axis * depth_from_bottom
		_add_vehicle_collision_strip(
			body,
			center,
			Vector2(strip_width, strip_depth),
			height,
			strip_index,
			debug_material
		)
		strip_index += 1


func _add_vehicle_collision_strip(
	body: StaticBody3D,
	center: Vector3,
	size: Vector2,
	height: float,
	strip_index: int,
	debug_material: StandardMaterial3D
) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "VehicleCollision%d" % strip_index
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, height, size.y)
	collision.position = center
	collision.position.y = height * 0.5 - body.position.y - 0.05
	collision.rotation.y = deg_to_rad(45.0)
	collision.shape = shape
	body.add_child(collision)
	if SHOW_VEHICLE_COLLISION_DEBUG and debug_material != null:
		var debug_plane := MeshInstance3D.new()
		debug_plane.name = "CollisionDebug%d" % strip_index
		var debug_mesh := PlaneMesh.new()
		debug_mesh.size = size
		debug_mesh.material = debug_material
		debug_plane.position = collision.position
		debug_plane.position.y = 0.04 - body.position.y
		debug_plane.rotation.y = collision.rotation.y
		debug_plane.mesh = debug_mesh
		debug_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(debug_plane)


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
