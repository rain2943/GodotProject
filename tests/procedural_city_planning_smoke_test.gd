extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _block_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _run() -> void:
	var map_script: Script = load("res://scripts/procedural_map.gd")
	var generated_lowrise_ids := {}
	for seed in [1, 7, 42, 1337, 24681357]:
		var city: Node3D = map_script.new()
		city.set("map_seed", seed)
		root.add_child(city)
		await process_frame

		var parks: Array = city.get("park_cells")
		var playgrounds: Array = city.get("playground_cells")
		var subways: Array = city.get("subway_cells")
		assert(parks.size() == 2)
		assert(playgrounds.size() == 2)
		assert(subways.size() == 2)
		assert(get_nodes_in_group("urban_pocket_park").size() == 2)
		assert(get_nodes_in_group("urban_playground").size() == 2)
		assert(get_nodes_in_group("urban_subway_entrance").size() == 2)

		var low_count := 0
		var high_count := 0
		for building in get_nodes_in_group("camera_occluder"):
			if not building.has_meta("height_class"):
				continue
			var height_class := str(building.get_meta("height_class"))
			if height_class == "low":
				low_count += 1
				generated_lowrise_ids[str(building.get_meta("building_id"))] = true
			if height_class != "high":
				continue
			high_count += 1
			var building_cell: Vector2i = building.get_meta("planning_cell")
			for park_cell in parks:
				assert(_block_distance(building_cell, park_cell) > 2)
		assert(low_count > high_count)

		city.queue_free()
		await process_frame

	assert(generated_lowrise_ids.has("gangnam_lowrise_commercial_8x4_aligned"))
	assert(generated_lowrise_ids.has("gangnam_lowrise_garage_8x4_aligned"))
	print("CITY_PLANNING_OK seeds=5 parks=2 playgrounds=2 subways=2 lowrise_types=%d" % generated_lowrise_ids.size())
	quit(0)
