class_name ProceduralCityMap
extends Node3D

signal shelter_portal_entered

const GRID_SIZE := 18
const CELL_SIZE := 10.0
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const MAP_MODULES := GRID_SIZE * 10
const SIDEWALK_WIDTH := 2.0
const ISOMETRIC_VERTICAL_PROJECTION := 0.816496580927726
const BUILDING_CATALOG := preload("res://scripts/building_catalog.gd")
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")
const RIVER_TEXTURE_PATH := "res://assets/tiles/river_water_generated.png"
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
var building_cells := {}
var parking_cells := {}
var open_cells := {}
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
var shelter_material: StandardMaterial3D
var shelter_glow_material: StandardMaterial3D
var vehicle_collision_material: StandardMaterial3D


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
	vertical_roads = [2, rng.randi_range(6, 7), rng.randi_range(10, 12), rng.randi_range(15, 16)]
	horizontal_roads = [2, rng.randi_range(6, 7), rng.randi_range(10, 12), rng.randi_range(15, 16)]
	vertical_roads.sort()
	horizontal_roads.sort()

	var river_x := rng.randi_range(8, 10)
	for z in range(GRID_SIZE):
		if z > 0 and z % 2 == 0:
			river_x = clampi(river_x + rng.randi_range(-1, 1), 5, GRID_SIZE - 4)
		river_columns.append(river_x)

	var eligible_cells: Array[Vector2i] = []
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var cell := Vector2i(x, z)
			if cell == SHELTER_CELL or _is_road_cell(cell) or _is_river_cell(cell):
				continue
			eligible_cells.append(cell)
			if rng.randf() < 0.44:
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
	riverbank_material = _color_material(Color("#4f5146"))
	bridge_material = _color_material(Color("#575b5d"))
	shelter_material = _color_material(Color("#3f4d49"))
	shelter_glow_material = _color_material(Color("#62e6a5"))
	shelter_glow_material.emission_enabled = true
	shelter_glow_material.emission = Color("#42d990")
	shelter_glow_material.emission_energy_multiplier = 2.6
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


func _build_river_cell(center: Vector3, block_movement: bool) -> void:
	_add_plane("RiverWater", center, Vector2(CELL_SIZE, CELL_SIZE), water_material, -0.04)
	_add_plane("RiverBankLeft", center + Vector3(-4.65, 0, 0), Vector2(0.7, CELL_SIZE), riverbank_material, 0.015)
	_add_plane("RiverBankRight", center + Vector3(4.65, 0, 0), Vector2(0.7, CELL_SIZE), riverbank_material, 0.015)
	if block_movement:
		var blocker := StaticBody3D.new()
		blocker.name = "RiverBarrier"
		blocker.position = center + Vector3(0, 0.45, 0)
		blocker.collision_layer = 1
		add_child(blocker)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(CELL_SIZE - 0.8, 0.9, CELL_SIZE)
		collision.shape = shape
		blocker.add_child(collision)


func _build_bridge_cell(center: Vector3, vertical: bool, horizontal: bool) -> void:
	_add_plane("BridgeDeck", center, Vector2(CELL_SIZE, CELL_SIZE), bridge_material, 0.13)
	_add_plane("BridgeRoad", center, Vector2(CELL_SIZE - 0.8, CELL_SIZE), asphalt_material, 0.145)
	if horizontal and not vertical:
		_add_lane_dash(center + Vector3(0, 0.15, 0), false)
	for side in [-1.0, 1.0]:
		_add_box("BridgeRail", center + Vector3(0, 0.48, side * 4.65), Vector3(CELL_SIZE, 0.7, 0.22), curb_material)


func _build_zoned_lots() -> void:
	for cell in parking_cells:
		_build_parking_lot(cell)
	for cell in building_cells:
		_try_build_building(cell)
	for cell in open_cells:
		_build_open_lot(cell)


func _build_parking_lot(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	_add_plane("ParkingAsphalt", center, Vector2(8.2, 8.2), asphalt_material, 0.045)
	for offset in [-3.0, -1.5, 0.0, 1.5, 3.0]:
		_add_plane("ParkingStripe", center + Vector3(offset, 0, 0), Vector2(0.07, 3.4), marking_material, 0.055)
	var types := VEHICLE_TEXTURES.keys()
	var vehicle_type: String = types[rng.randi_range(0, types.size() - 1)]
	var position := center + Vector3(0, 0.1, rng.randf_range(-0.55, 0.55))
	_spawn_vehicle("Parked_%d_%d" % [cell.x, cell.y], vehicle_type, position)


func _build_open_lot(cell: Vector2i) -> void:
	var center := _cell_center(cell)
	var dirt := _color_material(Color("#666357"))
	_add_plane("OpenLot", center, Vector2(7.2, 7.2), dirt, 0.035)
	for index in range(rng.randi_range(2, 5)):
		var size := rng.randf_range(0.25, 0.6)
		_add_box("Debris", center + Vector3(rng.randf_range(-3, 3), size * 0.25, rng.randf_range(-3, 3)), Vector3(size, size * 0.5, size), curb_material)


func _try_build_building(cell: Vector2i) -> void:
	var left_margin := 2 if _is_road_cell(cell + Vector2i.LEFT) else 1
	var right_margin := 2 if _is_road_cell(cell + Vector2i.RIGHT) else 1
	var top_margin := 2 if _is_road_cell(cell + Vector2i.UP) else 1
	var bottom_margin := 2 if _is_road_cell(cell + Vector2i.DOWN) else 1
	var usable_size := Vector2i(10 - left_margin - right_margin, 10 - top_margin - bottom_margin)
	var definitions: Array[Dictionary] = []
	for building_id in BUILDING_CATALOG.DEFINITIONS:
		var definition: Dictionary = BUILDING_CATALOG.get_definition(building_id)
		var footprint: Vector2i = definition.get("footprint_modules", Vector2i.ZERO)
		if footprint.x <= usable_size.x and footprint.y <= usable_size.y:
			definitions.append({"id": building_id, "definition": definition})
	if definitions.is_empty():
		return
	var selected: Dictionary = definitions[rng.randi_range(0, definitions.size() - 1)]
	var definition: Dictionary = selected["definition"]
	var footprint: Vector2i = definition["footprint_modules"]
	var cell_origin := cell * 10
	var min_offset := Vector2i(left_margin, top_margin)
	var max_offset := Vector2i(10 - right_margin - footprint.x, 10 - bottom_margin - footprint.y)
	var module_origin := cell_origin + Vector2i(
		rng.randi_range(min_offset.x, maxi(min_offset.x, max_offset.x)),
		rng.randi_range(min_offset.y, maxi(min_offset.y, max_offset.y))
	)
	_spawn_building(selected["id"], definition, module_origin)


func _spawn_building(building_id: String, definition: Dictionary, module_origin: Vector2i) -> void:
	var footprint_modules: Vector2i = definition["footprint_modules"]
	var footprint_world := Vector2(footprint_modules) * BUILDING_CATALOG.MODULE_SIZE
	var center_x := -MAP_SIZE * 0.5 + (module_origin.x + footprint_modules.x * 0.5) * BUILDING_CATALOG.MODULE_SIZE
	var center_z := -MAP_SIZE * 0.5 + (module_origin.y + footprint_modules.y * 0.5) * BUILDING_CATALOG.MODULE_SIZE
	var texture := load(definition["texture_path"]) as Texture2D
	if texture == null:
		return
	var body := StaticBody3D.new()
	body.name = "%s_%d_%d" % [building_id, module_origin.x, module_origin.y]
	body.position = Vector3(center_x, 0, center_z)
	body.add_to_group("camera_occluder")
	body.collision_layer = 1
	add_child(body)
	var sprite := Sprite3D.new()
	sprite.name = "BuildingSprite"
	sprite.texture = texture
	var corners: Array = definition["footprint_corners_px"]
	var base_pixel_width := absf((corners[2] as Vector2).x - (corners[0] as Vector2).x)
	var projected_width := (footprint_world.x + footprint_world.y) / sqrt(2.0)
	sprite.pixel_size = projected_width / base_pixel_width
	sprite.position = Vector3(footprint_world.x * 0.5, ((corners[3] as Vector2).y - texture.get_height() * 0.5) * sprite.pixel_size / ISOMETRIC_VERTICAL_PROJECTION, footprint_world.y * 0.5)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.transparent = true
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var height := float(definition["height_world"])
	shape.size = Vector3(footprint_world.x, height, footprint_world.y)
	collision.position.y = height * 0.5
	collision.shape = shape
	body.add_child(collision)
	body.set_meta("occlusion_lateral_limit", (footprint_world.x + footprint_world.y) / (2.0 * sqrt(2.0)))
	body.set_meta("occlusion_depth_limit", float(definition["occlusion_depth"]))


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
	var shelter := Node3D.new()
	shelter.name = "ShelterSafehouse"
	shelter.position = center
	shelter.add_to_group("safe_zone")
	add_child(shelter)
	_add_cylinder_to(shelter, "SafeZone", Vector3(0, 0.04, 0), 5.0, 0.05, shelter_glow_material)
	_add_box_to(shelter, "ShelterBase", Vector3(0, 1.25, 0), Vector3(6.2, 2.5, 6.0), shelter_material)
	_add_box_to(shelter, "ShelterRoof", Vector3(0, 2.7, 0), Vector3(6.8, 0.35, 6.6), curb_material)
	_add_box_to(shelter, "PortalFrameLeft", Vector3(3.18, 1.0, -1.1), Vector3(0.35, 2.0, 0.35), shelter_glow_material)
	_add_box_to(shelter, "PortalFrameRight", Vector3(3.18, 1.0, 1.1), Vector3(0.35, 2.0, 0.35), shelter_glow_material)
	_add_box_to(shelter, "PortalFrameTop", Vector3(3.18, 2.0, 0), Vector3(0.35, 0.28, 2.55), shelter_glow_material)
	var label := Label3D.new()
	label.text = "SHELTER 01"
	label.position = Vector3(0, 3.35, 0)
	label.font_size = 48
	label.modulate = Color("#9fffd0")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shelter.add_child(label)
	var light := OmniLight3D.new()
	light.position = Vector3(3.4, 1.4, 0)
	light.light_color = Color("#5dffb2")
	light.light_energy = 2.0
	light.omni_range = 6.0
	shelter.add_child(light)
	var portal := Area3D.new()
	portal.name = "ShelterPortal"
	portal.position = Vector3(3.6, 0.9, 0)
	portal.collision_layer = 0
	portal.collision_mask = 1
	shelter.add_child(portal)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.8, 2.2)
	collision.shape = shape
	portal.add_child(collision)
	portal.body_entered.connect(_on_shelter_portal_body_entered)


func _on_shelter_portal_body_entered(body: Node3D) -> void:
	if portal_locked or body.name != "Player":
		return
	portal_locked = true
	shelter_portal_entered.emit()


func get_shelter_exit_position() -> Vector3:
	return _cell_center(SHELTER_CELL) + Vector3(6.2, 0.78, 0)


func get_map_limit() -> float:
	return MAP_SIZE * 0.5 - 1.5


func is_position_in_safe_zone(world_position: Vector3) -> bool:
	var shelter_center := _cell_center(SHELTER_CELL)
	return Vector2(world_position.x, world_position.z).distance_to(Vector2(shelter_center.x, shelter_center.z)) <= 6.0


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


func _cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE and cell.y < GRID_SIZE


func _cell_center(cell: Vector2i) -> Vector3:
	return Vector3(-MAP_SIZE * 0.5 + (cell.x + 0.5) * CELL_SIZE, 0, -MAP_SIZE * 0.5 + (cell.y + 0.5) * CELL_SIZE)


func _world_to_cell(position: Vector3) -> Vector2i:
	return Vector2i(floori((position.x + MAP_SIZE * 0.5) / CELL_SIZE), floori((position.z + MAP_SIZE * 0.5) / CELL_SIZE))


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
	var curb_center := center + direction * (CELL_SIZE * 0.5 - 0.07)
	if abs(direction.x) > 0.5:
		_add_plane("Sidewalk", sidewalk_center, Vector2(SIDEWALK_WIDTH, CELL_SIZE), sidewalk_material, 0.022)
		_add_plane("Curb", curb_center, Vector2(0.14, CELL_SIZE), curb_material, 0.034)
	else:
		_add_plane("Sidewalk", sidewalk_center, Vector2(CELL_SIZE, SIDEWALK_WIDTH), sidewalk_material, 0.022)
		_add_plane("Curb", curb_center, Vector2(CELL_SIZE, 0.14), curb_material, 0.034)


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


func _add_cylinder_to(parent: Node, node_name: String, position: Vector3, radius: float, height: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
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
