extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var city: Node3D = load("res://scripts/procedural_map.gd").new()
	city.set("map_seed", 42)
	root.add_child(city)
	await process_frame
	await physics_frame

	var outer_grounds := get_nodes_in_group("outer_city_ground")
	assert(outer_grounds.size() == 1)
	var outer_ground := outer_grounds[0] as MeshInstance3D
	assert(bool(outer_ground.get_meta("collision_free")))
	assert(outer_ground.position.y < -0.2)
	var ground_mesh := outer_ground.mesh as PlaneMesh
	assert(ground_mesh != null)
	assert(ground_mesh.size == Vector2(1040.0, 1040.0))
	var ground_material := ground_mesh.material as StandardMaterial3D
	assert(ground_material != null)
	assert(ground_material.texture_repeat)
	assert(ground_material.uv1_scale == Vector3(12.0, 12.0, 1.0))

	var skylines := get_nodes_in_group("distant_city_backdrop")
	assert(skylines.size() == 6)
	for skyline_node in skylines:
		var skyline := skyline_node as Sprite3D
		assert(skyline != null)
		assert(skyline.texture != null)
		assert(skyline.billboard == BaseMaterial3D.BILLBOARD_ENABLED)
		assert(not skyline.no_depth_test)
		assert(bool(skyline.get_meta("collision_free")))
		assert(float(skyline.get_meta("world_width")) == 460.0)
		assert(skyline.scale == Vector3.ONE)
		assert(skyline.get_child_count() == 0)

	# The visual ground must never extend the playable collision floor.
	var outside_query := PhysicsRayQueryParameters3D.create(
		Vector3(300.0, 2.0, 300.0),
		Vector3(300.0, -2.0, 300.0),
		1
	)
	var outside_hit := city.get_world_3d().direct_space_state.intersect_ray(outside_query)
	assert(outside_hit.is_empty())

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_instance := main_scene.instantiate()
	var camera := main_instance.get_node("CameraRig/Camera3D") as Camera3D
	assert(camera.far >= 1200.0)
	main_instance.free()

	print("DISTANT_SEOUL_BACKDROP_OK ground=1040 skylines=6 collision=none")
	quit(0)
