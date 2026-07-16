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
	print("OVERLAY_DEPTH_SORT_OK")
	quit(0)
