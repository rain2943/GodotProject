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

	print("LANDMARK_PROJECTILE_COLLISION_OK playground=sealed apartment_gate=open")
	quit(0)
