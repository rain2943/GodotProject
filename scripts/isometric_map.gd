extends Node3D

const MAP_HALF := 32.0
const ROAD_CENTERS := [-16.0, 0.0, 16.0]
const BLOCK_CENTERS := [-24.0, -8.0, 8.0, 24.0]
const SIGN_TEXTS := ["서울약국", "종로식당", "대방상회", "한빛마트", "을지로상가", "청계정비"]

var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}


func _ready() -> void:
	rng.seed = 2943
	_build_ground()
	_build_roads()
	_build_city_blocks()
	_build_abandoned_cars()
	_build_debris()
	_build_landmark()


func _build_ground() -> void:
	_box("Ground", Vector3(0, -0.18, 0), Vector3(66, 0.3, 66), Color("#171b19"), true)


func _build_roads() -> void:
	var asphalt := Color("#252a29")
	var sidewalk := Color("#454a46")
	var line_color := Color("#8b8152")
	for center in ROAD_CENTERS:
		_box("RoadNS", Vector3(center, 0.015, 0), Vector3(5.8, 0.08, 64), asphalt)
		_box("RoadEW", Vector3(0, 0.02, center), Vector3(64, 0.08, 5.8), asphalt)
		_box("SidewalkNSL", Vector3(center - 3.55, 0.09, 0), Vector3(1.25, 0.18, 64), sidewalk)
		_box("SidewalkNSR", Vector3(center + 3.55, 0.09, 0), Vector3(1.25, 0.18, 64), sidewalk)
		_box("SidewalkEWT", Vector3(0, 0.095, center - 3.55), Vector3(64, 0.18, 1.25), sidewalk)
		_box("SidewalkEWB", Vector3(0, 0.095, center + 3.55), Vector3(64, 0.18, 1.25), sidewalk)
		for dash in range(-28, 29, 4):
			_box("RoadDash", Vector3(center, 0.075, dash), Vector3(0.12, 0.025, 1.6), line_color)
			_box("RoadDash", Vector3(dash, 0.08, center), Vector3(1.6, 0.025, 0.12), line_color)
	for stripe in range(-4, 5):
		_box("Crosswalk", Vector3(stripe * 0.48, 0.09, 3.0), Vector3(0.26, 0.025, 1.5), Color("#9b9d91"))
		_box("Crosswalk", Vector3(3.0, 0.09, stripe * 0.48), Vector3(1.5, 0.025, 0.26), Color("#9b9d91"))


func _build_city_blocks() -> void:
	var index := 0
	for x in BLOCK_CENTERS:
		for z in BLOCK_CENTERS:
			var height := rng.randf_range(4.6, 8.2)
			var footprint := rng.randf_range(7.2, 8.6)
			_build_building(Vector3(x, 0, z), Vector2(footprint, footprint), height, index)
			index += 1


func _build_building(origin: Vector3, footprint: Vector2, height: float, index: int) -> void:
	var wall_colors := [Color("#343936"), Color("#3d3d39"), Color("#303638"), Color("#46413b")]
	var wall_color: Color = wall_colors[index % wall_colors.size()]
	_box("Lot", origin + Vector3(0, 0.12, 0), Vector3(10.2, 0.22, 10.2), Color("#363b37"))
	var building := _box(
		"Building_%02d" % index,
		origin + Vector3(0, height * 0.5 + 0.23, 0),
		Vector3(footprint.x, height, footprint.y),
		wall_color,
		true
	)
	building.add_to_group("camera_occluder")
	var window_color := Color("#62706f") if index % 4 else Color("#7c6747")
	for floor_index in range(3):
		var y := -height * 0.5 + 1.35 + floor_index * 1.35
		if y > height * 0.45:
			continue
		for column in [-2.4, -0.8, 0.8, 2.4]:
			if absf(column) < footprint.x * 0.43:
				_mesh_box(building, Vector3(column, y, footprint.y * 0.5 + 0.035), Vector3(0.72, 0.56, 0.06), window_color, 0.2)
			if absf(column) < footprint.y * 0.43:
				_mesh_box(building, Vector3(footprint.x * 0.5 + 0.035, y, column), Vector3(0.06, 0.56, 0.72), window_color, 0.2)
	_mesh_box(building, Vector3(0, height * 0.5 + 0.32, 0), Vector3(1.5, 0.55, 1.2), Color("#272c2b"))
	_add_sign(building, footprint, height, SIGN_TEXTS[index % SIGN_TEXTS.size()], index)


func _add_sign(building: Node3D, footprint: Vector2, height: float, text_value: String, index: int) -> void:
	var sign_color: Color = [Color("#315448"), Color("#633b32"), Color("#445466")][index % 3]
	var local_y := 1.45 - (height * 0.5 + 0.23)
	_mesh_box(building, Vector3(0, local_y, footprint.y * 0.5 + 0.12), Vector3(3.1, 0.8, 0.16), sign_color)
	var label := Label3D.new()
	label.name = "StoreSign"
	label.position = Vector3(0, local_y, footprint.y * 0.5 + 0.22)
	label.text = text_value
	label.font = load("res://assets/fonts/Pretendard-Regular.otf")
	label.font_size = 48
	label.pixel_size = 0.008
	label.modulate = Color("#d9d6c4")
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 0.75)
	building.add_child(label)


func _build_abandoned_cars() -> void:
	var cars := [
		[Vector3(-1.4, 0.42, 8.5), 0.12], [Vector3(8.5, 0.42, -1.2), 1.48],
		[Vector3(-16, 0.42, -8), 0.08], [Vector3(-16.5, 0.42, 11), -0.12],
		[Vector3(16, 0.42, 6), 0.18], [Vector3(15.6, 0.42, -23), -0.08],
		[Vector3(-7, 0.42, 0), 1.48], [Vector3(10, 0.42, 0.3), 1.62],
		[Vector3(25, 0.42, -16), 1.45], [Vector3(-24, 0.42, 16), 1.72]
	]
	for i in cars.size():
		_build_car(cars[i][0], cars[i][1], i)


func _build_car(pos: Vector3, yaw: float, index: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Wreck_%02d" % index
	body.position = pos
	body.rotation.y = yaw
	add_child(body)
	var body_color: Color = [Color("#354b50"), Color("#4b4035"), Color("#38413c")][index % 3]
	_mesh_box(body, Vector3.ZERO, Vector3(1.25, 0.42, 2.25), body_color)
	_mesh_box(body, Vector3(0, 0.38, -0.08), Vector3(1.05, 0.42, 1.05), Color("#202827"))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.35, 0.9, 2.35)
	collision.shape = shape
	body.add_child(collision)


func _build_debris() -> void:
	for i in 72:
		var on_vertical := i % 2 == 0
		var road_center: float = ROAD_CENTERS[i % ROAD_CENTERS.size()]
		var p: Vector3
		if on_vertical:
			p = Vector3(road_center + rng.randf_range(-2.25, 2.25), 0.16, rng.randf_range(-30, 30))
		else:
			p = Vector3(rng.randf_range(-30, 30), 0.16, road_center + rng.randf_range(-2.25, 2.25))
		if p.length() < 5.0:
			continue
		var size := Vector3(rng.randf_range(0.12, 0.42), rng.randf_range(0.08, 0.22), rng.randf_range(0.12, 0.55))
		var debris := _box("Debris", p, size, Color("#3d3a34"))
		debris.rotation.y = rng.randf_range(0, TAU)


func _build_landmark() -> void:
	var base := Vector3(-29, 0, -29)
	_box("NamsanBase", base + Vector3(0, 2.5, 0), Vector3(2.2, 5, 2.2), Color("#343b3d"))
	var tower := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.42
	mesh.height = 7.0
	tower.mesh = mesh
	tower.position = base + Vector3(0, 8.5, 0)
	tower.material_override = _material(Color("#737b78"), 0.0)
	add_child(tower)
	_box("TowerDeck", base + Vector3(0, 11.6, 0), Vector3(2.5, 0.42, 2.5), Color("#525c5b"))


func _box(node_name: String, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> Node3D:
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name
		body.position = pos
		add_child(body)
		_mesh_box(body, Vector3.ZERO, size, color)
		var collision_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
		return body
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color)
	add_child(instance)
	return instance


func _mesh_box(parent: Node3D, local_pos: Vector3, size: Vector3, color: Color, emission: float = 0.0) -> void:
	var instance := MeshInstance3D.new()
	instance.position = local_pos
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color, emission)
	parent.add_child(instance)


func _material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), emission]
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	materials[key] = material
	return material
