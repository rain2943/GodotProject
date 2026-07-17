extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	push_error("FIELD_PROGRESSION_SMOKE: %s" % message)
	quit(1)


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_run")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene could not be loaded")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var extraction_sites := main.get("extraction_sites") as Array
	if extraction_sites.size() != 3:
		_fail("expected three extraction beacons")
		return
	var field_interactions := main.get("field_interactions") as Array
	var salvage_count := 0
	var rescue_count := 0
	for point_value in field_interactions:
		var point := point_value as Node3D
		match str(point.get_meta("interaction_type", "")):
			"salvage": salvage_count += 1
			"rescue":
				rescue_count += 1
				var cowering_resident := point.get_node_or_null("CoweringResident") as Sprite3D
				if cowering_resident == null or cowering_resident.texture == null:
					_fail("rescue point is missing the cowering resident sprite")
					return
	if salvage_count < 5 or rescue_count != 3:
		_fail("field salvage/rescue objectives were not populated")
		return

	var player := main.get("player") as Node3D
	var visibility_probe := StaticBody3D.new()
	var probe_collision := CollisionShape3D.new()
	var probe_shape := BoxShape3D.new()
	probe_shape.size = Vector3(2.0, 2.0, 2.0)
	probe_collision.shape = probe_shape
	visibility_probe.add_child(probe_collision)
	main.add_child(visibility_probe)
	var facing_direction: Vector3 = main.call("_get_current_facing_world_direction")
	visibility_probe.global_position = player.global_position + facing_direction * 6.0
	if not bool(main.call("_structure_touches_visibility_sector", visibility_probe)):
		_fail("structure in the forward reveal sector was not detected")
		return
	visibility_probe.global_position = player.global_position - facing_direction * 6.0
	if bool(main.call("_structure_touches_visibility_sector", visibility_probe)):
		_fail("structure behind the player incorrectly entered the forward reveal sector")
		return
	visibility_probe.queue_free()
	var component_before := int(game_state.call("get_mod_component_count", "scope_lens"))
	var component_drop: Node3D = main.call(
		"_create_loot_pickup",
		"mod_component",
		player.global_position,
		{"component_id": "scope_lens", "amount": 1, "display_name": "스코프 렌즈"}
	)
	main.set("nearby_ammo_pickup", component_drop)
	main.call("_collect_nearby_ammo")
	if int(game_state.call("get_mod_component_count", "scope_lens")) != component_before + 1:
		_fail("mod component pickup was not stored")
		return

	main.set("fatigue", 100.0)
	if float(main.call("_get_fatigue_speed_multiplier")) >= 0.99:
		_fail("maximum fatigue did not reduce movement speed")
		return
	main.call("_add_rescued_follower", player.global_position + Vector3(1, 0, 1))
	if (main.get("rescued_followers") as Array).size() != 1:
		_fail("rescued follower was not added")
		return
	if float(main.call("_get_escort_speed_multiplier")) >= 1.0:
		_fail("escort did not apply movement penalty")
		return
	var workers_before := int(game_state.get("rescued_workers"))
	if int(main.call("_commit_rescued_followers")) != 1:
		_fail("rescued follower was not committed on extraction")
		return
	if int(game_state.get("rescued_workers")) != workers_before + 1:
		_fail("shelter worker total was not updated")
		return

	print("FIELD_PROGRESSION_SMOKE: PASS")
	quit(0)
