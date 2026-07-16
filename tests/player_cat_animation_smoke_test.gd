extends SceneTree


const DIRECTIONS := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]


func _initialize() -> void:
	call_deferred("_run")


func _assert_cat_frames(sprite: AnimatedSprite3D) -> void:
	assert(sprite != null)
	assert(is_equal_approx(sprite.pixel_size, 0.0098))
	for direction in DIRECTIONS:
		for state in ["idle", "walk"]:
			var animation := "%s_%s" % [state, direction]
			assert(sprite.sprite_frames.has_animation(animation))
			assert(sprite.sprite_frames.get_frame_count(animation) == 4)
			var expected_fps := 4.0 if state == "idle" else 8.0
			assert(is_equal_approx(sprite.sprite_frames.get_animation_speed(animation), expected_fps))


func _run() -> void:
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var field_sprite := main_scene.get_node("Player/Survivor") as AnimatedSprite3D
	_assert_cat_frames(field_sprite)
	for direction in DIRECTIONS:
		main_scene.call("_set_facing", direction)
		assert(field_sprite.animation == "idle_%s" % direction)
		assert(not field_sprite.flip_h)
	main_scene.queue_free()
	await process_frame

	var shelter_scene: Node = load("res://scenes/shelter_interior.tscn").instantiate()
	root.add_child(shelter_scene)
	await process_frame
	var shelter_sprite := shelter_scene.get_node("ShelterPlayer/Survivor") as AnimatedSprite3D
	_assert_cat_frames(shelter_sprite)

	print("PLAYER_CAT_ANIMATION_OK animations=16 frames=64 scenes=2")
	quit(0)
