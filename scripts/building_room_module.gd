extends Node3D

var room_index := 0
var room_size := Vector2(7.0, 8.0)
var entrance_sign := 1.0
var room_type := "open_office"
var room_seed := 1


func configure(index: int, size_value: Vector2, front_sign: float, type_value: String, seed_value: int) -> void:
	room_index = index
	room_size = size_value
	entrance_sign = signf(front_sign)
	room_type = type_value
	room_seed = seed_value
	set_meta("room_index", room_index)
	set_meta("room_type", room_type)
	set_meta("module_size", room_size)


func _ready() -> void:
	add_to_group("building_room_module")
	_build_shell()
	_build_furniture()


func _build_shell() -> void:
	var floor_color := Color("#303538")
	match room_type:
		"executive": floor_color = Color("#3b3934")
		"storage": floor_color = Color("#292d2d")
		"server": floor_color = Color("#252d33")
		"meeting": floor_color = Color("#34363b")
	_add_box("RoomFloor", Vector3(0, -0.08, 0), Vector3(room_size.x, 0.16, room_size.y), floor_color, false)
	var wall_color := Color("#4c5356")
	var half_x := room_size.x * 0.5
	var half_z := room_size.y * 0.5
	_add_box("BackWall", Vector3(0, 1.25, -entrance_sign * half_z), Vector3(room_size.x, 2.5, 0.22), wall_color, true)
	_add_box("LeftWall", Vector3(-half_x, 1.25, 0), Vector3(0.22, 2.5, room_size.y), wall_color, true)
	_add_box("RightWall", Vector3(half_x, 1.25, 0), Vector3(0.22, 2.5, room_size.y), wall_color, true)
	var front_z := entrance_sign * half_z
	var door_width := 1.55
	var side_width := maxf(0.4, (room_size.x - door_width) * 0.5)
	_add_box("FrontWallLeft", Vector3(-(door_width + side_width) * 0.5, 1.25, front_z), Vector3(side_width, 2.5, 0.22), wall_color, true)
	_add_box("FrontWallRight", Vector3((door_width + side_width) * 0.5, 1.25, front_z), Vector3(side_width, 2.5, 0.22), wall_color, true)
	_add_box("DoorHeader", Vector3(0, 2.15, front_z), Vector3(door_width, 0.7, 0.22), Color("#596064"), true)


func _build_furniture() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = room_seed
	match room_type:
		"storage":
			for index in 3:
				var x := lerpf(-room_size.x * 0.28, room_size.x * 0.28, float(index) / 2.0)
				_add_box("StorageRack%d" % index, Vector3(x, 0.72, -entrance_sign * 1.35), Vector3(1.15, 1.44, 2.35), Color("#525044"), true)
		"server":
			for index in 3:
				var x := lerpf(-room_size.x * 0.28, room_size.x * 0.28, float(index) / 2.0)
				_add_box("ServerRack%d" % index, Vector3(x, 0.9, -entrance_sign * 1.5), Vector3(1.0, 1.8, 2.1), Color("#1b252b"), true)
				_add_box("ServerLight%d" % index, Vector3(x, 1.2, -entrance_sign * 0.42), Vector3(0.55, 0.1, 0.04), Color("#52b7a8"), false)
		"meeting":
			_add_box("MeetingTable", Vector3(0, 0.42, -entrance_sign * 0.45), Vector3(minf(4.6, room_size.x - 1.5), 0.84, 2.0), Color("#594c3f"), true)
			for chair_index in 4:
				var side := -1.0 if chair_index < 2 else 1.0
				var x := -1.35 if chair_index % 2 == 0 else 1.35
				_add_box("MeetingChair%d" % chair_index, Vector3(x, 0.34, side * 1.65 - entrance_sign * 0.45), Vector3(0.72, 0.68, 0.72), Color("#354048"), true)
		"executive":
			_add_desk(Vector3(0, 0, -entrance_sign * 1.55), 0, Color("#654f3c"))
			_add_box("ExecutiveCabinet", Vector3(-room_size.x * 0.32, 0.72, -entrance_sign * 2.55), Vector3(1.25, 1.44, 0.48), Color("#55473d"), true)
		_:
			var desk_count := clampi(roundi(room_size.x / 2.4), 2, 4)
			for desk_index in desk_count:
				var ratio := (float(desk_index) + 0.5) / float(desk_count)
				var desk_x := lerpf(-room_size.x * 0.38, room_size.x * 0.38, ratio)
				var desk_z := -entrance_sign * random.randf_range(1.0, 2.15)
				_add_desk(Vector3(desk_x, 0, desk_z), desk_index, Color("#514b43"))


func _add_desk(local_position: Vector3, index: int, color: Color) -> void:
	_add_box("Desk%d" % index, local_position + Vector3(0, 0.42, 0), Vector3(1.55, 0.84, 0.82), color, true)
	_add_box("Monitor%d" % index, local_position + Vector3(0, 1.05, -entrance_sign * 0.18), Vector3(0.7, 0.48, 0.12), Color("#182125"), true)
	_add_box("Chair%d" % index, local_position + Vector3(0, 0.34, entrance_sign * 0.92), Vector3(0.7, 0.68, 0.7), Color("#30383b"), true)


func _add_box(node_name: String, local_position: Vector3, size: Vector3, color: Color, collision_enabled: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "%sVisual" % node_name
	mesh_instance.position = local_position
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	mesh.material = material
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name = "%sCollision" % node_name
	body.position = local_position
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
