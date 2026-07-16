extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var city: Node3D = load("res://scripts/procedural_map.gd").new()
	city.set("map_seed", 42)
	root.add_child(city)
	await process_frame
	await physics_frame

	var playground_cells: Array = city.get("playground_cells")
	assert(not playground_cells.is_empty())
	var center: Vector3 = city.call("_cell_center", playground_cells[0])
	var projectile: Area3D = load("res://scripts/bullet_projectile.gd").new()
	projectile.set("direction", Vector3.RIGHT)
	projectile.position = center + Vector3(-9.3, 1.0, 0.0)
	city.add_child(projectile)
	var projectile_id := projectile.get_instance_id()

	for frame in range(12):
		await physics_frame
		if not is_instance_id_valid(projectile_id):
			break
	assert(not is_instance_id_valid(projectile_id), "Projectile crossed the sealed playground footprint")

	var apartment_origin: Vector2i = city.get("apartment_origin")
	var apartment_gate_cell := apartment_origin + Vector2i(2, 0)
	var gate_center: Vector3 = city.call("_cell_center", apartment_gate_cell)
	var gate_projectile: Area3D = load("res://scripts/bullet_projectile.gd").new()
	gate_projectile.set("direction", Vector3.FORWARD)
	gate_projectile.position = Vector3(gate_center.x, 1.0, -204.0)
	city.add_child(gate_projectile)
	var gate_projectile_id := gate_projectile.get_instance_id()
	for frame in range(24):
		await physics_frame
		if not is_instance_id_valid(gate_projectile_id):
			break
	assert(not is_instance_id_valid(gate_projectile_id), "Projectile crossed the closed apartment portal gate")
	print("LANDMARK_PROJECTILE_COLLISION_OK playground=sealed apartment_gate=sealed")
	quit(0)
