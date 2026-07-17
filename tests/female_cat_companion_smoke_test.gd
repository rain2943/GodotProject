extends SceneTree


const DIRECTIONS := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var companion := main_scene.get_node("FemaleCatCompanion") as CharacterBody3D
	var sprite := companion.get_node("Sprite") as AnimatedSprite3D
	assert(companion != null)
	assert(companion.get("target") == main_scene.get_node("Player"))
	assert(sprite != null)
	assert(not bool(main_scene.get("companion_active")))
	assert(not companion.visible)
	assert(companion.collision_layer == 0)
	assert(not sprite.visible)
	var companion_overlay := main_scene.get("companion_overlay") as Sprite2D
	assert(companion_overlay != null)
	assert(not companion_overlay.visible)
	assert(is_equal_approx(sprite.pixel_size, 0.0098))
	for direction in DIRECTIONS:
		for state in ["idle", "walk"]:
			var animation := "%s_%s" % [state, direction]
			assert(sprite.sprite_frames.has_animation(animation))
			assert(sprite.sprite_frames.get_frame_count(animation) == 4)
			assert(is_equal_approx(
				sprite.sprite_frames.get_animation_speed(animation),
				4.0 if state == "idle" else 8.0
			))

	companion.call("_set_facing_from_world_direction", Vector3(1, 0, 1))
	assert(companion.get("facing") == "s")
	companion.call("_set_facing_from_world_direction", Vector3(-1, 0, -1))
	assert(companion.get("facing") == "n")
	assert(not sprite.flip_h)

	main_scene.call("activate_companion")
	assert(bool(main_scene.get("companion_active")))
	assert(companion.visible)
	assert(companion.collision_layer == 16)
	assert(companion_overlay.visible)

	var player := main_scene.get_node("Player") as CharacterBody3D
	player.position = Vector3(0, 0.78, 0)
	companion.position = Vector3(-6, 0.78, 0)
	var distance_before := companion.position.distance_to(player.position)
	for _frame in 8:
		await physics_frame
	assert(companion.position.distance_to(player.position) < distance_before)
	assert(companion.get("motion_state") == "walk")
	assert(sprite.animation.begins_with("walk_"))

	companion.position = player.position + Vector3(1.5, 0, 0)
	await physics_frame
	await physics_frame
	assert(companion.get("motion_state") == "idle")
	assert(sprite.animation.begins_with("idle_"))
	companion.position = player.position + Vector3(2.0, 0, 2.0)
	main_scene.call("_update_building_overlays")
	var survivor_overlay := main_scene.get("survivor_overlay") as Sprite2D
	assert(companion_overlay.z_index > survivor_overlay.z_index)

	var enemies := main_scene.get("enemies") as Array
	assert(not enemies.is_empty())
	var enemy := enemies[0] as CharacterBody3D
	enemy.global_position = player.global_position + Vector3(100, 0, 100)
	main_scene.call("_update_enemy_visibility")
	assert(not enemy.visible)
	enemy.global_position = player.global_position + Vector3(0.75, 0, 0.75)
	main_scene.call("_update_enemy_visibility")
	assert(enemy.visible)

	print("FEMALE_CAT_COMPANION_OK animations=16 frames=64 follow=walk_stop overlay_depth=sorted enemy_fog=hidden_visible")
	quit(0)
