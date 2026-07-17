extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _block_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _assert_isometric_footprint(definition: Dictionary) -> void:
	var corners: Array = definition["footprint_corners_px"]
	var left: Vector2 = corners[0]
	var top: Vector2 = corners[1]
	var right: Vector2 = corners[2]
	var bottom: Vector2 = corners[3]
	assert(left + right == top + bottom)
	assert(absf((right.y - top.y) / (right.x - top.x) - 0.5) < 0.002)
	assert(absf((left.y - top.y) / (left.x - top.x) + 0.5) < 0.002)
	assert(absf((bottom.y - left.y) / (bottom.x - left.x) - 0.5) < 0.002)
	assert(absf((bottom.y - right.y) / (bottom.x - right.x) + 0.5) < 0.002)


func _assert_sealed_landmark(city: Node3D, cell: Vector2i, node_prefix: String) -> void:
	var matching_bodies: Array[StaticBody3D] = []
	for child in city.get_children():
		if child is StaticBody3D and str(child.name).begins_with(node_prefix):
			matching_bodies.append(child)
	assert(not matching_bodies.is_empty())
	var collision := matching_bodies[0].get_child(0) as CollisionShape3D
	assert(collision != null)
	var box := collision.shape as BoxShape3D
	assert(box != null)
	assert(box.size == Vector3(16.0, 2.4, 16.0))
	assert(matching_bodies[0].collision_layer == 1)

	var center: Vector3 = city.call("_cell_center", cell)
	var query := PhysicsRayQueryParameters3D.create(
		center + Vector3(-8.5, 1.0, 0.0),
		center + Vector3(8.5, 1.0, 0.0),
		1
	)
	var hit := city.get_world_3d().direct_space_state.intersect_ray(query)
	assert(not hit.is_empty())
	var hit_name := str((hit["collider"] as Node).name)
	assert(hit_name.begins_with(node_prefix), "Expected %s, hit %s" % [node_prefix, hit_name])


func _run() -> void:
	var map_script: Script = load("res://scripts/procedural_map.gd")
	var building_catalog = load("res://scripts/building_catalog.gd")
	var landmark_catalog = load("res://scripts/urban_landmark_catalog.gd")
	for landmark_id in ["playground"]:
		var definition: Dictionary = landmark_catalog.get_definition(landmark_id)
		_assert_isometric_footprint(definition)
		assert(definition["collision_boxes"].size() == 1)
		assert(definition["collision_boxes"][0]["size"] == Vector2(8.0, 8.0))
		assert(float(definition["collision_boxes"][0]["height"]) == 2.4)
	for building_id in [
		"gangnam_clinic_pharmacy_6x4_aligned",
		"gangnam_food_alley_4x6_aligned",
		"gangnam_damaged_officetel_6x6_aligned",
		"seoul_market_row_8x4_v1",
		"seoul_multifamily_villa_6x6_v1",
		"gangnam_luxury_showroom_6x6_v1",
	]:
		var definition: Dictionary = building_catalog.get_definition(building_id)
		assert(building_catalog.is_valid_definition(definition))
		assert(ResourceLoader.exists(str(definition["texture_path"])))
		_assert_isometric_footprint(definition)
	assert(building_catalog.get_definition("seoul_market_row_8x4_v1")["districts"].has("market_lane"))
	assert(building_catalog.get_definition("seoul_multifamily_villa_6x6_v1")["districts"].has("multi_family"))
	assert(building_catalog.get_definition("gangnam_luxury_showroom_6x6_v1")["districts"].has("luxury_core"))
	var generated_lowrise_ids := {}
	for seed in [1, 7, 42, 1337, 24681357]:
		var city: Node3D = map_script.new()
		city.set("map_seed", seed)
		root.add_child(city)
		await process_frame
		await physics_frame

		var parks: Array = city.get("park_cells")
		var playgrounds: Array = city.get("playground_cells")
		var subways: Array = city.get("subway_cells")
		var apartment_cells: Array = city.get("apartment_cells")
		var apartment_origin: Vector2i = city.get("apartment_origin")
		assert(parks.is_empty())
		assert(playgrounds.size() == 2)
		assert(subways.size() == 2)
		assert(get_nodes_in_group("urban_pocket_park").is_empty())
		assert(get_nodes_in_group("urban_playground").size() == 2)
		assert(get_nodes_in_group("urban_subway_entrance").size() == 2)
		_assert_sealed_landmark(city, playgrounds[0], "UrbanPlaygroundCollision")
		assert(apartment_cells.size() == 5)
		assert(get_nodes_in_group("urban_apartment_complex").size() == 1)
		assert(get_nodes_in_group("apartment_gate").size() == 1)
		assert(get_nodes_in_group("apartment_portal_site").size() == 1)
		assert(get_nodes_in_group("apartment_portal_blocker").size() == 1)
		assert(apartment_origin.y == 0)
		assert(city.get("vertical_roads").has(apartment_origin.x + 2))
		assert(float(city.call("get_map_limit")) > 210.0)
		var gate_kinds := {}
		for gate in get_nodes_in_group("apartment_gate"):
			gate_kinds[str(gate.get_meta("gate_kind"))] = true
			assert(bool(gate.get_meta("road_connected")))
			assert(bool(gate.get_meta("future_portal")))
			assert(not bool(gate.get_meta("portal_ready")))
		assert(gate_kinds.has("main_entrance"))
		var apartment: Node3D = get_nodes_in_group("urban_apartment_complex")[0]
		assert(apartment.global_position.z < -float(city.call("get_map_limit")))
		assert(apartment.get_meta("site_size_cells") == Vector2i(5, 1))
		assert(bool(apartment.get_meta("map_edge_attached")))
		assert(apartment.is_in_group("camera_occluder"))
		var apartment_sprite := apartment.get_node("BuildingSprite") as Sprite3D
		assert(apartment_sprite != null)
		assert(apartment.get_meta("overlay_focus_local") == Vector3(0.0, 1.6, 30.8))
		assert(apartment.get_meta("overlay_focus_fade_pixels") == Vector2(32.0, 150.0))
		var blocker: StaticBody3D = get_nodes_in_group("apartment_portal_blocker")[0]
		assert(blocker.collision_layer == 1)
		var blocker_collision := blocker.get_child(0) as CollisionShape3D
		var blocker_box := blocker_collision.shape as BoxShape3D
		assert(blocker_box.size == Vector3(12.0, 3.2, 2.4))
		var gate_cell: Vector2i = apartment_origin + Vector2i(2, 0)
		var gate_x: float = (city.call("_cell_center", gate_cell) as Vector3).x
		var query := PhysicsRayQueryParameters3D.create(
			Vector3(gate_x, 1.0, -204.0),
			Vector3(gate_x, 1.0, -216.0),
			1
		)
		var gate_hit := city.get_world_3d().direct_space_state.intersect_ray(query)
		assert(not gate_hit.is_empty())
		assert((gate_hit["collider"] as Node).is_in_group("apartment_portal_blocker"))

		var anchors: Dictionary = city.get("district_anchors")
		var zones: Dictionary = city.get("cell_zones")
		var signature_roads: Dictionary = city.get("district_signature_road_cells")
		var building_by_cell: Dictionary = city.get("building_type_by_cell")
		var expected_anchor_buildings := {
			"market_lane": "seoul_market_row_8x4_v1",
			"multi_family": "seoul_multifamily_villa_6x6_v1",
			"luxury_core": "gangnam_luxury_showroom_6x6_v1",
		}
		for district_name in expected_anchor_buildings:
			assert(anchors.has(district_name))
			assert(signature_roads.has(district_name))
			var anchor_cell: Vector2i = anchors[district_name]
			assert(str(zones[anchor_cell]) == district_name)
			assert(str(building_by_cell[anchor_cell]) == str(expected_anchor_buildings[district_name]))
			for other_name in expected_anchor_buildings:
				if other_name == district_name:
					continue
				assert(_block_distance(anchor_cell, anchors[other_name]) >= 6)
		assert(get_nodes_in_group("market_handcart").size() >= 1)
		for handcart in get_nodes_in_group("market_handcart"):
			assert(handcart is StaticBody3D)
			assert((handcart as StaticBody3D).collision_layer == 1)
			assert((handcart as Node).get_node_or_null("HandcartCollision") != null)
		var has_luxury_sedan := false
		for vehicle in get_nodes_in_group("vehicle_obstacle"):
			if str((vehicle as Node).get_meta("vehicle_type")) == "luxury_sedan":
				has_luxury_sedan = true
				break
		assert(has_luxury_sedan)

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
			for playground_cell in playgrounds:
				assert(_block_distance(building_cell, playground_cell) > 2)
			for apartment_cell in apartment_cells:
				assert(_block_distance(building_cell, apartment_cell) > 2)
		assert(low_count > high_count)

		city.queue_free()
		await process_frame

	assert(generated_lowrise_ids.has("gangnam_lowrise_commercial_8x4_aligned"))
	assert(generated_lowrise_ids.has("gangnam_lowrise_garage_8x4_aligned"))
	assert(generated_lowrise_ids.has("seoul_market_row_8x4_v1"))
	assert(building_catalog.get_definition("gangnam_lowrise_commercial_8x4_aligned")["footprint_modules"] == Vector2i(4, 8))
	print("CITY_PLANNING_OK seeds=5 parks=0 playgrounds=2 subways=2 apartments=1 districts=3 lowrise_types=%d" % generated_lowrise_ids.size())
	quit(0)
