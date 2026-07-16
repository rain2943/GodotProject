extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	assert(game_state != null)
	game_state.set("world_time_hours", 23.5)
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	await physics_frame
	assert(float(main_scene.get("night_intensity")) > 0.9)
	var enemies: Array = main_scene.get("enemies")
	assert(enemies.size() == 6)
	var visibility_material: ShaderMaterial = main_scene.get("visibility_material")
	assert(float(visibility_material.get_shader_parameter("inner_radius")) < 150.0)
	main_scene.set("reinforcement_timer", 0.0)
	main_scene.call("_update_enemy_pressure", 1.0)
	await process_frame
	enemies = main_scene.get("enemies")
	assert(enemies.size() == 7)
	var enemy: Node = enemies[0]
	enemy.call("_become_alerted")
	assert(enemy.get("alerted"))
	assert(enemy.get_node("ThreatMarker").visible)
	enemy.set("last_known_position", (enemy as Node3D).global_position + Vector3(5.0, 0.0, 0.0))
	enemy.call("_pursue_last_known_position")
	assert((enemy as CharacterBody3D).velocity.length() > 0.1)
	print("DAY_NIGHT_SMOKE_OK threat=%.2f enemies=%d" % [main_scene.get("night_intensity"), enemies.size()])
	quit(0)
