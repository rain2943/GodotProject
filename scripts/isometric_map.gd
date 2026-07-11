extends Node3D

const GRID_SIZE := 9
const CELL_SIZE := 10.0
const ROAD_INDICES := [2, 6]
const MAP_SIZE := GRID_SIZE * CELL_SIZE
const SIDEWALK_WIDTH := 1.4
const HANBIT_BUILDING := preload("res://assets/buildings/hanbit_building.png")
const ASPHALT_TEXTURE := preload("res://assets/tiles/asphalt.png")
const CONCRETE_TEXTURE := preload("res://assets/tiles/concrete.png")

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
	_build_sprite_building(Vector3(10, 0, 10))


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


func _build_sprite_building(origin: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "HanbitBuilding"
	body.position = origin
	body.add_to_group("camera_occluder")
	add_child(body)

	var sprite := Sprite3D.new()
	sprite.name = "BuildingSprite"
	sprite.texture = HANBIT_BUILDING
	sprite.position.y = 7.05
	sprite.pixel_size = 0.0118
	sprite.billboard = 1
	sprite.transparent = true
	sprite.shaded = false
	sprite.alpha_cut = 0
	sprite.render_priority = 0
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(sprite)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.2, 14.5, 8.2)
	collision.position.y = 7.25
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


func _texture_material(texture: Texture2D, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 0.96
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _color_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
