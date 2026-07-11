extends Node3D

const GRID_SIZE := 9
const CELL_SIZE := 10.0
const ROAD_INDICES := [2, 6]
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const HANBIT_BUILDING := preload("res://assets/buildings/hanbit_building.png")
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")

var asphalt_material: StandardMaterial3D
var concrete_material: StandardMaterial3D
var marking_material: StandardMaterial3D
var curb_material: StandardMaterial3D


func _ready() -> void:
	_build_materials()
	_build_floor_collision()
	_build_tile_grid()
	_build_sprite_building(Vector3(10, 0, 10))


func _build_materials() -> void:
	asphalt_material = _texture_material(ASPHALT_TEXTURE)
	concrete_material = _texture_material(CONCRETE_TEXTURE)
	marking_material = _color_material(Color("#c8bd78"))
	curb_material = _color_material(Color("#77766e"))


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
				_build_lot_cell(center)


func _build_lot_cell(center: Vector3) -> void:
	_add_plane("ConcreteLot", center, Vector2(CELL_SIZE, CELL_SIZE), concrete_material, 0.0)
	_add_curb_edges(center)


func _build_road_cell(center: Vector3, vertical: bool, horizontal: bool) -> void:
	_add_plane("AsphaltRoad", center, Vector2(CELL_SIZE, CELL_SIZE), asphalt_material, 0.0)
	if vertical and horizontal:
		_add_crosswalks(center)
	elif vertical:
		_add_lane_dash(center, true)
		_add_sidewalk_strip(center + Vector3(-4.55, 0, 0), Vector2(0.9, CELL_SIZE))
		_add_sidewalk_strip(center + Vector3(4.55, 0, 0), Vector2(0.9, CELL_SIZE))
	else:
		_add_lane_dash(center, false)
		_add_sidewalk_strip(center + Vector3(0, 0, -4.55), Vector2(CELL_SIZE, 0.9))
		_add_sidewalk_strip(center + Vector3(0, 0, 4.55), Vector2(CELL_SIZE, 0.9))


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


func _add_sidewalk_strip(center: Vector3, size: Vector2) -> void:
	_add_plane("Sidewalk", center, size, concrete_material, 0.018)


func _add_curb_edges(center: Vector3) -> void:
	_add_plane("Curb", center + Vector3(-4.93, 0, 0), Vector2(0.14, CELL_SIZE), curb_material, 0.026)
	_add_plane("Curb", center + Vector3(4.93, 0, 0), Vector2(0.14, CELL_SIZE), curb_material, 0.026)
	_add_plane("Curb", center + Vector3(0, 0, -4.93), Vector2(CELL_SIZE, 0.14), curb_material, 0.026)
	_add_plane("Curb", center + Vector3(0, 0, 4.93), Vector2(CELL_SIZE, 0.14), curb_material, 0.026)


func _build_sprite_building(origin: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "HanbitBuilding"
	body.position = origin
	body.add_to_group("camera_occluder")
	add_child(body)

	var sprite := Sprite3D.new()
	sprite.name = "BuildingSprite"
	sprite.texture = HANBIT_BUILDING
	sprite.position.y = 7.15
	sprite.pixel_size = 0.0115
	sprite.billboard = 1
	sprite.transparent = true
	sprite.shaded = false
	sprite.alpha_cut = 0
	sprite.render_priority = 0
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.4, 12.0, 9.4)
	collision.position.y = 6.0
	collision.shape = shape
	body.add_child(collision)


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


func _texture_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.96
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _color_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
