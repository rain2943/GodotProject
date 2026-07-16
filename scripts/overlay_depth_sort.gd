class_name OverlayDepthSort
extends RefCounted

const DEPTH_SCALE := 10.0
const DEPTH_LIMIT := 4000
const PLAYER_SEPARATION := 2


static func world_depth(position: Vector3) -> int:
	return clampi(roundi((position.x + position.z) * DEPTH_SCALE), -DEPTH_LIMIT, DEPTH_LIMIT)


static func building_depth(
	building_position: Vector3,
	player_position: Vector3,
	overlaps_player: bool,
	occludes_player: bool
) -> int:
	var base_depth := world_depth(building_position)
	if not overlaps_player:
		return base_depth
	var player_depth := world_depth(player_position)
	return player_depth + PLAYER_SEPARATION if occludes_player else player_depth - PLAYER_SEPARATION
