extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_run")
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var main_scene: Node = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	await physics_frame

	assert(bool(main_scene.get("has_ak")))
	assert(main_scene.get("ak_pickup") == null)
	assert(bool(game_state.get("has_ak")))
	assert((main_scene.get("ammo_pickups") as Array).size() == 4)

	var player := main_scene.get("player") as Node3D
	var food_before := int(game_state.get("canned_food"))
	var food_pickup: Node3D = main_scene.call(
		"_create_loot_pickup",
		"canned_food",
		player.global_position,
		{"amount": 2, "display_name": "통조림"}
	)
	main_scene.set("nearby_ammo_pickup", food_pickup)
	main_scene.call("_collect_nearby_ammo")
	assert(int(game_state.get("canned_food")) == food_before + 2)
	assert((main_scene.get("inventory_ui") as Control).get("food_slot_label").text == "x2")

	var mp5_before := int(game_state.call("get_weapon_count", "mp5"))
	var weapon_pickup: Node3D = main_scene.call(
		"_create_loot_pickup",
		"weapon",
		player.global_position,
		{"amount": 1, "weapon_id": "mp5", "display_name": "MP5"}
	)
	main_scene.set("nearby_ammo_pickup", weapon_pickup)
	main_scene.call("_collect_nearby_ammo")
	assert(int(game_state.call("get_weapon_count", "mp5")) == mp5_before + 1)
	assert((main_scene.get("inventory_ui") as Control).get("weapon_slot_label").text == "x1")

	var enemies := main_scene.get("enemies") as Array
	var pickup_count_before := (main_scene.get("ammo_pickups") as Array).size()
	var random_drop: Node3D = main_scene.call("_spawn_enemy_loot", enemies[0])
	assert(is_instance_valid(random_drop))
	assert((main_scene.get("ammo_pickups") as Array).size() == pickup_count_before + 1)
	assert(["ammo", "canned_food", "weapon"].has(str(random_drop.get_meta("loot_type"))))

	print("LOOT_DROP_OK start_weapon=ak47 food=%d mp5=%d random=%s" % [
		game_state.get("canned_food"),
		game_state.call("get_weapon_count", "mp5"),
		random_drop.get_meta("loot_type"),
	])
	quit(0)
