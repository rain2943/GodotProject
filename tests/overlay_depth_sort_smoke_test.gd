extends SceneTree

const DEPTH_SORT := preload("res://scripts/overlay_depth_sort.gd")


func _initialize() -> void:
	var building := Vector3(8.0, 0.0, 4.0)
	var player := Vector3(7.2, 0.0, 4.1)
	var player_depth := DEPTH_SORT.world_depth(player)
	assert(DEPTH_SORT.building_depth(building, player, true, false) < player_depth)
	assert(DEPTH_SORT.building_depth(building, player, true, true) > player_depth)
	assert(
		DEPTH_SORT.building_depth(building, player, false, false)
		== DEPTH_SORT.world_depth(building)
	)
	assert(DEPTH_SORT.world_depth(Vector3(1000.0, 0.0, 1000.0)) == 4000)
	var viewport_size := Vector2(1280.0, 720.0)
	assert(is_equal_approx(DEPTH_SORT.focused_overlay_alpha(Vector2(640.0, 360.0), viewport_size, 32.0, 150.0), 1.0))
	assert(is_equal_approx(DEPTH_SORT.focused_overlay_alpha(Vector2(-20.0, 360.0), viewport_size, 32.0, 150.0), 1.0))
	assert(is_equal_approx(DEPTH_SORT.focused_overlay_alpha(Vector2(-150.0, 360.0), viewport_size, 32.0, 150.0), 0.0))
	var fading_alpha := DEPTH_SORT.focused_overlay_alpha(Vector2(-80.0, 360.0), viewport_size, 32.0, 150.0)
	assert(fading_alpha > 0.0 and fading_alpha < 1.0)
	print("OVERLAY_DEPTH_SORT_OK")
	quit(0)
