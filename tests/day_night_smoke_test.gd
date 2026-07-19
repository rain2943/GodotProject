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
	assert(enemies.size() == 17)
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
	var night_aim_radius := float(visibility_material.get_shader_parameter("inner_radius"))
	assert(night_aim_radius >= 150.0 and night_aim_radius < 220.0)
	assert(float(visibility_material.get_shader_parameter("near_radius")) < 80.0)
	main_scene.set("reinforcement_timer", 0.0)
	main_scene.call("_update_enemy_pressure", 1.0)
	await process_frame
	enemies = main_scene.get("enemies")
	assert(enemies.size() == 18)
	var enemy: Node = enemies[0]
	assert(enemy.get_node_or_null("VisionFan") == null)
	assert(float(enemy.call("_get_vision_range")) >= 18.0)
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
	enemy.call("receive_reinforcement_order", (enemy as Node3D).global_position + Vector3(3.0, 0.0, 0.0))
	assert(enemy.get("alerted"))
	assert(enemy.get_node("ThreatMarker").text == "!")

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

	var perception := main_scene.get("perception_system") as CanvasLayer
	assert(perception != null)
	assert(not perception.has_method("emit_player_gunshot"))
	assert(not perception.has_method("emit_enemy_gunshot"))
	assert(not enemy.has_method("hear_sound"))

	var grenadier: Node
	for candidate in enemies:
		if str(candidate.get("enemy_kind")) == "grenadier":
			grenadier = candidate
			break
	assert(grenadier != null)
	grenadier.set("target", main_scene.get("player"))
	grenadier.set("pending_attack_direction", Vector3.FORWARD)
	grenadier.set("grenade_target_position", (main_scene.get("player") as Node3D).global_position)
	var main_child_count_before_grenade := main_scene.get_child_count()
	grenadier.call("_throw_grenade")
	assert(main_scene.get_child_count() == main_child_count_before_grenade + 1)
	var spawned_grenade := main_scene.get_child(main_scene.get_child_count() - 1)
	assert(spawned_grenade.get_script() == load("res://scripts/enemy_grenade.gd"))
	spawned_grenade.queue_free()
	var bat_sprite: Sprite3D = main_scene.get("melee_bat_sprite")
	assert(bat_sprite != null and bat_sprite.texture != null)
	main_scene.call("_play_bat_swing", Vector3(1.0, 0.0, 0.0))
	assert((main_scene.get("melee_bat_overlay") as Sprite2D).visible)
	assert(main_scene.get("melee_button") != null)
	assert(main_scene.get("mobile_context_button") is Button)
	assert(main_scene.get("mobile_reload_button") is Button)
	assert(main_scene.get("mobile_flashlight_button") is Button)
	assert(main_scene.get("mobile_map_button") is Button)
	main_scene.call("_on_mobile_flashlight_toggled", true)
	assert(bool(main_scene.get("laser_aim_held")))
	var fatigue_before_flashlight := float(main_scene.get("fatigue"))
	main_scene.call("_update_fatigue", 1.0, false)
	assert(float(main_scene.get("fatigue")) > fatigue_before_flashlight)
	main_scene.call("_on_mobile_flashlight_toggled", false)
	assert(not bool(main_scene.get("laser_aim_held")))
	main_scene.set("magazine_ammo", 24)
	main_scene.set("reserve_ammo", 95)
	main_scene.call("_update_equipment_ui")
	assert((main_scene.get("equipment_ammo_label") as Label).text.contains("24 / 30"))
	assert((main_scene.get("equipment_condition_label") as Label).text.contains("완전 탄창 3개 + 낱탄 5발"))
	assert((main_scene.get("quick_slot_buttons") as Array)[0].text.contains("24/30 · 예비 95"))
	assert((main_scene.get_node("HUD/TopLeft/Margin/VBox/Stats") as Label).text.contains("탄 24/30 +95"))

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
	print("COMBAT_ALERT_SMOKE_OK threat=%.2f enemies=%d burst=%d" % [
		main_scene.get("night_intensity"),
		enemies.size(),
		pistol_enemy.get("burst_shots_remaining"),
	])
	quit(0)
