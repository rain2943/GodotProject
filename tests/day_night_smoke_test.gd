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
	assert(enemies.size() == 10)
	var initial_spawn_distances: Array[float] = []
	for initial_enemy in enemies:
		initial_spawn_distances.append(
			(initial_enemy as Node3D).global_position.distance_to(
				(main_scene.get("player") as Node3D).global_position
			)
		)
	assert(initial_spawn_distances.min() < 45.0)
	assert(initial_spawn_distances.max() > 100.0)
	var visibility_material: ShaderMaterial = main_scene.get("visibility_material")
	assert(float(visibility_material.get_shader_parameter("inner_radius")) < 150.0)
	main_scene.set("reinforcement_timer", 0.0)
	main_scene.call("_update_enemy_pressure", 1.0)
	await process_frame
	enemies = main_scene.get("enemies")
	assert(enemies.size() == 11)
	var enemy: Node = enemies[0]
	assert(enemy.get_node_or_null("VisionFan") is MeshInstance3D)
	assert(float(enemy.call("_get_vision_range")) >= 9.5)
	enemy.set("facing_world_direction", Vector3.FORWARD)
	assert(enemy.call(
		"_is_position_inside_vision_fan",
		(enemy as Node3D).global_position + Vector3.FORWARD * 5.0,
		10.0
	))
	assert(not enemy.call(
		"_is_position_inside_vision_fan",
		(enemy as Node3D).global_position + Vector3.BACK * 5.0,
		10.0
	))
	var enemy_sprite := enemy.get_node("EnemySprite") as AnimatedSprite3D
	assert(is_equal_approx(enemy_sprite.pixel_size, 0.0092))
	for direction_name in ["n", "ne", "e", "se", "s", "sw", "w", "nw"]:
		assert(enemy_sprite.sprite_frames.has_animation("idle_%s" % direction_name))
		assert(enemy_sprite.sprite_frames.has_animation("walk_%s" % direction_name))
		assert(enemy_sprite.sprite_frames.get_frame_count("walk_%s" % direction_name) == 4)
	enemy.call("_set_motion_state", "idle")
	enemy.call("_set_facing", "w")
	assert(enemy_sprite.animation == "idle_w")
	assert(not enemy_sprite.flip_h)
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
	var ranged_weapon_ids: Array[String] = []
	for candidate in enemies:
		if candidate.get("enemy_kind") == "pistol":
			ranged_weapon_ids.append(str(candidate.get("weapon_id")))
			if candidate.get("weapon_id") == "mp5":
				pistol_enemy = candidate
	assert(pistol_enemy != null)
	assert(ranged_weapon_ids.has("m1911"))
	assert(ranged_weapon_ids.has("mp5"))
	assert(ranged_weapon_ids.has("ak47"))
	assert(ranged_weapon_ids.size() >= 8)
	assert(pistol_enemy.get_node_or_null("EquippedWeapon_mp5") is Sprite3D)
	pistol_enemy.call("set_threat_level", 1.0)
	pistol_enemy.set("attack_cooldown", 0.0)
	pistol_enemy.call("_update_pistol", Vector3(1.0, 0.0, 0.0), 8.0, 0.1)
	assert(pistol_enemy.get("combat_state") == "pistol_burst")
	assert(int(pistol_enemy.get("burst_shots_remaining")) == 8)
	assert(int(pistol_enemy.call("_get_weapon_burst_size")) == 9)

	var wave_script: Script = load("res://scripts/sound_wave.gd")
	var gunshot_wave: Control = wave_script.new()
	gunshot_wave.call("configure", "player_gunshot", 1.0)
	root.add_child(gunshot_wave)
	await process_frame
	assert(float(gunshot_wave.get("max_radius")) >= 650.0)
	assert(int(gunshot_wave.get("ring_count")) == 1)
	var perception := main_scene.get("perception_system") as CanvasLayer
	perception.process_mode = Node.PROCESS_MODE_DISABLED
	for existing_wave in perception.get("sound_waves") as Array:
		if is_instance_valid(existing_wave):
			existing_wave.free()
	perception.call("_prune_sound_waves")
	perception.call("_spawn_sound_wave", Vector3.ZERO, "heavy_step", 1.0)
	perception.call("_spawn_sound_wave", Vector3.ONE, "enemy_gunshot", 1.0)
	assert((perception.get("sound_waves") as Array).is_empty())
	perception.call("_spawn_sound_wave", Vector3.ONE * 2.0, "player_gunshot", 1.0)
	assert((perception.get("sound_waves") as Array).size() == 1)
	assert((perception.get("sound_waves") as Array)[0].get_meta("sound_kind") == "player_gunshot")
	var bat_sprite: Sprite3D = main_scene.get("melee_bat_sprite")
	assert(bat_sprite != null and bat_sprite.texture != null)
	main_scene.call("_play_bat_swing", Vector3(1.0, 0.0, 0.0))
	assert((main_scene.get("melee_bat_overlay") as Sprite2D).visible)
	assert(main_scene.get("melee_button") != null)

	pistol_enemy.set("magazine_ammo", 0)
	pistol_enemy.call("_start_reload")
	assert(pistol_enemy.get("combat_state") == "reloading")
	assert((pistol_enemy.get("reload_indicator") as Sprite3D).visible)
	pistol_enemy.set("combat_state", "normal")
	pistol_enemy.set("alerted", true)
	assert(pistol_enemy.call("start_reinforcement_call", 0.05))
	assert((pistol_enemy.get("reinforcement_call_indicator") as Sprite3D).visible)
	main_scene.set("active_reinforcement_caller", pistol_enemy)
	var enemy_count_before_call := enemies.size()
	pistol_enemy.call("_update_reinforcement_call", 1.1)
	assert((main_scene.get("enemies") as Array).size() >= enemy_count_before_call + 6)

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
