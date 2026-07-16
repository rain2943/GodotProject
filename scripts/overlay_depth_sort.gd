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


static func focused_overlay_alpha(
	focus_screen_position: Vector2,
	viewport_size: Vector2,
	fade_start_pixels: float,
	fade_end_pixels: float
) -> float:
	var outside := Vector2(
		maxf(0.0, maxf(-focus_screen_position.x, focus_screen_position.x - viewport_size.x)),
		maxf(0.0, maxf(-focus_screen_position.y, focus_screen_position.y - viewport_size.y))
	)
	var outside_distance := outside.length()
	if outside_distance <= fade_start_pixels:
		return 1.0
	if outside_distance >= fade_end_pixels:
		return 0.0
	return 1.0 - smoothstep(fade_start_pixels, fade_end_pixels, outside_distance)
