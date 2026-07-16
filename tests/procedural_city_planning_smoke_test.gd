extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _block_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _run() -> void:
	var map_script: Script = load("res://scripts/procedural_map.gd")
	var building_catalog = load("res://scripts/building_catalog.gd")
	var generated_lowrise_ids := {}
	for seed in [1, 7, 42, 1337, 24681357]:
		var city: Node3D = map_script.new()
		city.set("map_seed", seed)
		root.add_child(city)
		await process_frame

		var parks: Array = city.get("park_cells")
		var playgrounds: Array = city.get("playground_cells")
		var subways: Array = city.get("subway_cells")
		var apartment_cells: Array = city.get("apartment_cells")
		var apartment_origin: Vector2i = city.get("apartment_origin")
		assert(parks.size() == 2)
		assert(playgrounds.size() == 2)
		assert(subways.size() == 2)
		assert(get_nodes_in_group("urban_pocket_park").size() == 2)
		assert(get_nodes_in_group("urban_playground").size() == 2)
		assert(get_nodes_in_group("urban_subway_entrance").size() == 2)
		assert(apartment_cells.size() == 4)
		assert(get_nodes_in_group("urban_apartment_complex").size() == 1)
		assert(get_nodes_in_group("apartment_gate").size() == 2)
		assert(city.get("vertical_roads").has(apartment_origin.x + 2))
		assert(city.get("horizontal_roads").has(apartment_origin.y + 2))
		assert(float(city.call("get_map_limit")) > 210.0)
		var gate_kinds := {}
		for gate in get_nodes_in_group("apartment_gate"):
			gate_kinds[str(gate.get_meta("gate_kind"))] = true
			assert(bool(gate.get_meta("road_connected")))
		assert(gate_kinds.has("main_entrance"))
		assert(gate_kinds.has("service_exit"))

		var low_count := 0
		var high_count := 0
		for building in get_nodes_in_group("camera_occluder"):
			if not building.has_meta("height_class"):
				continue
			var height_class := str(building.get_meta("height_class"))
			var definition: Dictionary = building_catalog.get_definition(str(building.get_meta("building_id")))
			var footprint: Vector2i = definition["footprint_modules"]
			var collision := building.get_node_or_null("BuildingCollision") as CollisionShape3D
			assert(collision != null)
			var collision_box := collision.shape as BoxShape3D
			assert(is_equal_approx(collision_box.size.x, footprint.x * 2.0))
			assert(is_equal_approx(collision_box.size.z, footprint.y * 2.0))
			var sprite := building.get_node_or_null("BuildingSprite") as Sprite3D
			var corners: Array = definition["footprint_corners_px"]
			assert(is_equal_approx(sprite.offset.x, sprite.texture.get_width() * 0.5 - (corners[3] as Vector2).x))
			var planning_cell: Vector2i = building.get_meta("planning_cell")
			var cell_center: Vector3 = city.call("_cell_center", planning_cell)
			var half_size := Vector2(collision_box.size.x, collision_box.size.z) * 0.5
			if city.call("_is_road_cell", planning_cell + Vector2i.LEFT):
				assert(building.global_position.x - half_size.x >= cell_center.x - 6.01)
			if city.call("_is_road_cell", planning_cell + Vector2i.RIGHT):
				assert(building.global_position.x + half_size.x <= cell_center.x + 6.01)
			if city.call("_is_road_cell", planning_cell + Vector2i.UP):
				assert(building.global_position.z - half_size.y >= cell_center.z - 6.01)
			if city.call("_is_road_cell", planning_cell + Vector2i.DOWN):
				assert(building.global_position.z + half_size.y <= cell_center.z + 6.01)
			if height_class == "low":
				low_count += 1
				generated_lowrise_ids[str(building.get_meta("building_id"))] = true
			if height_class != "high":
				continue
			high_count += 1
			var building_cell: Vector2i = building.get_meta("planning_cell")
			for park_cell in parks:
				assert(_block_distance(building_cell, park_cell) > 2)
			for apartment_cell in apartment_cells:
				assert(_block_distance(building_cell, apartment_cell) > 2)
		assert(low_count > high_count)

		city.queue_free()
		await process_frame

	assert(generated_lowrise_ids.has("gangnam_lowrise_commercial_8x4_aligned"))
	assert(generated_lowrise_ids.has("gangnam_lowrise_garage_8x4_aligned"))
	assert(building_catalog.get_definition("gangnam_lowrise_commercial_8x4_aligned")["footprint_modules"] == Vector2i(4, 8))
	print("CITY_PLANNING_OK seeds=5 parks=2 playgrounds=2 subways=2 apartments=1 lowrise_types=%d" % generated_lowrise_ids.size())
	quit(0)
