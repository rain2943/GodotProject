extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_run")
	game_state.set("scrap", 500)
	game_state.set("canned_food", 3)
	game_state.set("rescued_workers", 3)
	game_state.call("_ensure_resident_records")
	for resident_id in game_state.get("resident_cat_ids"):
		game_state.call("assign_worker_to_scratcher", resident_id)
	game_state.set("weapon_durability", 42.0)
	game_state.set("shelter_last_progress_time", int(Time.get_unix_time_from_system()) - 7200)
	game_state.set("workbench_repair_active", true)
	var shelter := load("res://scenes/shelter_interior.tscn").instantiate() as Node3D
	root.add_child(shelter)
	await process_frame
	await physics_frame

	if int(game_state.get("scrap")) <= 500:
		_fail("scratcher bank did not produce offline scrap")
	if float(game_state.get("weapon_durability")) <= 42.0:
		_fail("workbench did not repair weapon offline")
	var live_scrap_before := int(game_state.get("scrap"))
	game_state.call("tick_shelter_live", 60.0)
	if int(game_state.get("scrap")) <= live_scrap_before:
		_fail("live shelter worker tick did not add scrap")

	var workbench := get_nodes_in_group("shelter_workbench")[0] as Node
	workbench.call("interact")
	await process_frame
	if root.find_child("WorkbenchUILayer", true, false) == null:
		_fail("workbench did not create an interaction layer")

	var bank := get_nodes_in_group("scratcher_bank")[0] as Node
	bank.call("interact")
	await process_frame

	var before_level := int(game_state.get("scratcher_bank_level"))
	var upgraded := bool(game_state.call("try_upgrade_scratcher_bank"))
	if not upgraded or int(game_state.get("scratcher_bank_level")) != before_level + 1:
		_fail("scratcher bank upgrade failed")

	print("SHELTER_ECONOMY_OK scrap=%d durability=%.1f workers=%d" % [
		game_state.get("scrap"),
		game_state.get("weapon_durability"),
		game_state.call("get_active_scratcher_workers"),
	])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
