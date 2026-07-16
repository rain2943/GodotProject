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
	enemy.call("_clear_alert")
	enemy.call("hear_sound", (enemy as Node3D).global_position + Vector3(3.0, 0.0, 0.0), 1.0)
	assert(enemy.get("alerted"))
	assert(enemy.get_node("ThreatMarker").text == "?")

	var pistol_enemy: Node
	for candidate in enemies:
		if candidate.get("enemy_kind") == "pistol":
			pistol_enemy = candidate
			break
	assert(pistol_enemy != null)
	pistol_enemy.call("set_threat_level", 1.0)
	pistol_enemy.set("attack_cooldown", 0.0)
	pistol_enemy.call("_update_pistol", Vector3(1.0, 0.0, 0.0), 8.0, 0.1)
	assert(pistol_enemy.get("combat_state") == "pistol_burst")
	assert(int(pistol_enemy.get("burst_shots_remaining")) == 3)

	var wave_script: Script = load("res://scripts/sound_wave.gd")
	var gunshot_wave: Control = wave_script.new()
	gunshot_wave.call("configure", "player_gunshot", 1.0)
	root.add_child(gunshot_wave)
	await process_frame
	assert(float(gunshot_wave.get("max_radius")) >= 500.0)
	var bat_sprite: Sprite3D = main_scene.get("melee_bat_sprite")
	assert(bat_sprite != null and bat_sprite.texture != null)
	main_scene.call("_play_bat_swing", Vector3(1.0, 0.0, 0.0))
	assert(bat_sprite.visible)

	enemy.set("facing_world_direction", Vector3(1.0, 0.0, 0.0))
	var backstab_position := (enemy as Node3D).global_position - Vector3(1.0, 0.0, 0.0)
	assert(bool(enemy.call("is_backstab_from", backstab_position)))
	enemy.call("take_melee_hit", 38, Vector3(1.0, 0.0, 0.0), true)
	assert(enemy.get("backstab_stunned"))
	assert(int(enemy.get("health")) == 0)
	print("COMBAT_SOUND_SMOKE_OK threat=%.2f enemies=%d burst=%d" % [
		main_scene.get("night_intensity"),
		enemies.size(),
		pistol_enemy.get("burst_shots_remaining"),
	])
	quit(0)
