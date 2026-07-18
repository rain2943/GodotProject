extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_run")
	game_state.set("scrap", 2_000_000)
	game_state.set("canned_food", 200)
	game_state.set("churu", 99)

	var initial_level := int(game_state.call("get_weapon_enhancement_level", "ak47"))
	if not bool(game_state.call("try_enhance_weapon", "ak47")):
		_fail("weapon enhancement could not be purchased")
	if int(game_state.call("get_weapon_enhancement_level", "ak47")) != initial_level + 1:
		_fail("weapon enhancement level did not persist in state")
	var equipped_mods: Array[String] = ["scope_2x"]
	game_state.set("equipped_weapon_mods", equipped_mods)
	if not bool(game_state.call("try_enhance_mod", "scope_2x")):
		_fail("equipped attachment enhancement could not be purchased")
	if int(game_state.call("get_mod_enhancement_level", "scope_2x")) != 1:
		_fail("attachment enhancement level did not persist in state")

	for index in game_state.ARTISAN_PITY_LIMIT:
		var result := game_state.call("roll_artisan_weapon") as Dictionary
		if result.is_empty():
			_fail("artisan weapon roll failed")
	if int(game_state.get("artisan_pity")) != 0:
		_fail("artisan pity did not reset on the guaranteed roll")

	if bool(game_state.call("is_raid_zone_unlocked", "namsan_core")):
		_fail("tier 5 zone should be locked at tier 1")
	game_state.set("shelter_tier", 5)
	if not bool(game_state.call("is_raid_zone_unlocked", "namsan_core")):
		_fail("tier 5 zone did not unlock")
	if not bool(game_state.call("select_raid_zone", "namsan_core")):
		_fail("unlocked raid zone could not be selected")

	var shelter := load("res://scenes/shelter_interior.tscn").instantiate() as Node3D
	root.add_child(shelter)
	await process_frame
	await physics_frame
	var module_root := shelter.get_node_or_null("StageOneModules")
	if module_root == null:
		_fail("shelter module root is missing")
	var rack_count := 0
	for child in module_root.get_children():
		if child.name.begins_with("DormitoryRack"):
			rack_count += 1
	if rack_count != 9:
		_fail("tier 5 shelter should show nine five-cat dormitory racks")

	var test_save_path := "res://.godot/shelter_progression_smoke.json"
	game_state.set("persistence_enabled", true)
	game_state.set("persistence_path", test_save_path)
	game_state.set("scrap", 123456)
	game_state.set("catnip", 77.5)
	if not bool(game_state.call("save_persistent_state")):
		_fail("persistent shelter save could not be written")
	game_state.set("scrap", 1)
	game_state.set("catnip", 0.0)
	if not bool(game_state.call("load_persistent_state")):
		_fail("persistent shelter save could not be loaded")
	if int(game_state.get("scrap")) != 123456 or not is_equal_approx(float(game_state.get("catnip")), 77.5):
		_fail("persistent shelter save did not restore resource values")
	game_state.set("persistence_enabled", false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))

	print("SHELTER_PROGRESSION_OK level=%d zone=%s racks=%d" % [
		game_state.call("get_weapon_enhancement_level", "ak47"),
		game_state.get("selected_raid_zone"),
		rack_count,
	])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
