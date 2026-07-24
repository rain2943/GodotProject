extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.set("persistence_enabled", false)
	game_state.call("reset_run")
	game_state.set("scrap", 500)
	game_state.set("canned_food", 20)
	game_state.set("rescued_workers", 4)
	game_state.call("_ensure_resident_records")
	var resident_ids := game_state.get("resident_cat_ids") as Array
	for resident_index in range(3):
		game_state.call("assign_worker_to_scratcher", resident_ids[resident_index])
	game_state.call("assign_worker_to_catnip", resident_ids[3])
	game_state.set("weapon_durability", 42.0)
	game_state.set("shelter_last_progress_time", int(Time.get_unix_time_from_system()) - 7200)
	game_state.set("workbench_repair_active", true)
	var shelter := load("res://scenes/shelter_interior.tscn").instantiate() as Node3D
	root.add_child(shelter)
	await process_frame
	await physics_frame
	var stats := shelter.get("stats_label") as Label
	if stats == null:
		_fail("shelter resource stats label is missing")
	var inventory_button := shelter.find_child("InventoryButton", true, false) as Button
	if inventory_button == null or inventory_button.icon == null:
		_fail("shelter inventory button is missing or has no backpack icon")
	var currency_labels := shelter.get("shelter_currency_labels") as Dictionary
	for resource_data in [
		["scrap", "고철"],
		["catnip", "캣닢"],
		["food", "통조림"],
		["churu", "츄르"],
	]:
		var resource_id := str(resource_data[0])
		var resource_name := str(resource_data[1])
		if not currency_labels.has(resource_id):
			_fail("shelter resource value is missing for %s" % resource_name)
			return
		var resource_label := currency_labels[resource_id] as Label
		if resource_label == null or not resource_label.text.contains(resource_name):
			_fail("shelter resource value is unreadable for %s" % resource_name)
			return
		var resource_icon := shelter.find_child("%sIcon" % resource_name, true, false) as TextureRect
		if resource_icon == null or resource_icon.texture == null:
			_fail("shelter resource icon is missing for %s" % resource_name)
			return
	var resident_nodes := get_nodes_in_group("shelter_resident")
	if resident_nodes.size() != 4:
		_fail("rescued residents were not instantiated in the shelter")
	if shelter.find_child("PlayerBed", true, false) == null:
		_fail("the single player bed is missing")
	if shelter.find_children("BedModule*", "Node3D", true, false).size() > 0:
		_fail("obsolete resident beds are still present")
	if shelter.find_children("ScratcherLineSlot*", "Node3D", true, false).size() != int(game_state.call("get_scratcher_worker_slots")):
		_fail("scratcher production line does not match unlocked slots")
	if shelter.find_children("CatnipLineSlot*", "Node3D", true, false).size() != int(game_state.call("get_catnip_worker_slots")):
		_fail("catnip production line does not match unlocked slots")
	var working_residents := 0
	for resident in resident_nodes:
		if bool(resident.get_meta("assigned_to_scratcher", false)):
			working_residents += 1
			var resident_sprite := resident.get_node_or_null("ResidentSprite") as AnimatedSprite3D
			if resident_sprite == null or resident_sprite.animation != "kneading_ne":
				_fail("assigned scratcher worker is not playing the kneading animation")
			if resident_sprite.sprite_frames.get_frame_count("kneading_ne") != 6:
				_fail("kneading animation does not contain all six supplied frames")
	if working_residents != int(game_state.call("get_active_scratcher_workers")):
		_fail("visible scratcher workers do not match assigned worker data")
	var catnip_workers := 0
	for resident in resident_nodes:
		if str(resident.get_meta("assignment_kind", "")) == "catnip":
			catnip_workers += 1
	if catnip_workers != 1 or int(game_state.call("get_active_catnip_workers")) != 1:
		_fail("visible catnip worker does not match assigned worker data")

	if int(game_state.get("scrap")) <= 500:
		_fail("scratcher bank did not produce offline scrap")
	if float(game_state.get("weapon_durability")) <= 42.0:
		_fail("workbench did not repair weapon offline")
	if float(game_state.get("catnip")) <= 0.0:
		_fail("catnip scraper did not produce offline catnip")
	var live_scrap_before := int(game_state.get("scrap"))
	game_state.call("tick_shelter_live", 60.0)
	if int(game_state.get("scrap")) <= live_scrap_before:
		_fail("live shelter worker tick did not add scrap")
	game_state.set("canned_food", 0)
	var unfed_scrap_before := int(game_state.get("scrap"))
	game_state.call("tick_shelter_live", 3600.0)
	if int(game_state.get("scrap")) != unfed_scrap_before:
		_fail("unfed shelter workers should pause production")
	game_state.set("canned_food", 20)

	var workbench := get_nodes_in_group("shelter_workbench")[0] as Node
	workbench.call("interact")
	await process_frame
	if root.find_child("WorkbenchUILayer", true, false) == null:
		_fail("workbench did not create an interaction layer")

	var bank := get_nodes_in_group("scratcher_bank")[0] as Node
	bank.call("interact")
	await process_frame
	var bank_panel := root.find_child("ScratcherBankPanel", true, false) as Control
	var bank_body := root.find_child("ScratcherBankBody", true, false) as BoxContainer
	if bank_panel == null or bank_body == null:
		_fail("scratcher bank responsive panel structure is missing")
	var bank_viewport_size := bank.get_viewport().get_visible_rect().size
	if bank_panel.size.x > bank_viewport_size.x or bank_panel.size.y > bank_viewport_size.y:
		_fail("scratcher bank panel exceeds the viewport: panel=%s viewport=%s" % [bank_panel.size, bank_viewport_size])
	var assigned_ids := game_state.get("assigned_worker_ids") as Array
	if assigned_ids.is_empty():
		_fail("worker assignment data was unexpectedly empty")
	var toggled_resident_id := str(assigned_ids[0])
	bank.call("_toggle_worker", toggled_resident_id)
	await physics_frame
	var toggled_resident: Node
	for resident in resident_nodes:
		if str(resident.get_meta("resident_id", "")) == toggled_resident_id:
			toggled_resident = resident
			break
	if toggled_resident == null or bool(toggled_resident.get_meta("assigned_to_scratcher", true)):
		_fail("resident did not leave the scratcher after unassignment")
	var bank_layer := bank.get("ui_layer") as CanvasLayer
	if is_instance_valid(bank_layer):
		bank_layer.queue_free()
	await process_frame
	var catnip_module := get_nodes_in_group("catnip_scraper")[0] as Node
	catnip_module.call("interact")
	await process_frame
	var catnip_panel := root.find_child("CatnipScraperPanel", true, false) as Control
	var catnip_body := root.find_child("CatnipScraperBody", true, false) as BoxContainer
	if catnip_panel == null or catnip_body == null:
		_fail("catnip scraper responsive panel structure is missing")
	var catnip_viewport_size := catnip_module.get_viewport().get_visible_rect().size
	if catnip_panel.size.x > catnip_viewport_size.x or catnip_panel.size.y > catnip_viewport_size.y:
		_fail("catnip scraper panel exceeds the viewport: panel=%s viewport=%s" % [catnip_panel.size, catnip_viewport_size])
	var catnip_layer := catnip_module.get("ui_layer") as CanvasLayer
	if is_instance_valid(catnip_layer):
		catnip_layer.queue_free()
	await process_frame

	var before_level := int(game_state.get("scratcher_bank_level"))
	var upgraded := bool(game_state.call("try_upgrade_scratcher_bank"))
	if not upgraded or int(game_state.get("scratcher_bank_level")) != before_level + 1:
		_fail("scratcher bank upgrade failed")
	game_state.set("scrap", 1000)
	var catnip_level_before := int(game_state.get("catnip_scraper_level"))
	var catnip_rate_before := float(game_state.call("get_catnip_per_hour"))
	if not bool(game_state.call("try_upgrade_catnip_scraper")):
		_fail("catnip scraper upgrade failed")
	if int(game_state.get("catnip_scraper_level")) != catnip_level_before + 1:
		_fail("catnip scraper level did not increase")
	if float(game_state.call("get_catnip_per_hour")) <= catnip_rate_before:
		_fail("catnip scraper upgrade did not improve production")

	game_state.set("catnip", 25.0)
	if not bool(game_state.call("activate_catnip_boost")) or float(game_state.call("get_production_multiplier")) != 10.0:
		_fail("catnip production boost failed")
	game_state.set("scrap", 2000)
	game_state.set("churu", 1)
	if not bool(game_state.call("try_upgrade_shelter_tier")):
		_fail("shelter tier upgrade failed")
	if int(game_state.call("get_resident_capacity")) != 10 or int(game_state.call("get_scratcher_worker_slots")) != 6 or int(game_state.call("get_catnip_worker_slots")) != 2:
		_fail("tier 2 capacity table is inconsistent")

	print("SHELTER_ECONOMY_OK scrap=%d catnip=%.1f durability=%.1f workers=%d" % [
		game_state.get("scrap"),
		game_state.get("catnip"),
		game_state.get("weapon_durability"),
		game_state.call("get_active_scratcher_workers"),
	])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
