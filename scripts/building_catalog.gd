class_name BuildingCatalog
extends RefCounted

const MODULE_SIZE := 1.0
const MODULES_PER_CELL := 10

const DEFINITIONS := {
	"hanbit_8x8": {
		"node_name": "HanbitBuilding",
		"texture_path": "res://assets/buildings/hanbit_building.png",
		"footprint_modules": Vector2i(8, 8),
		"wall_inset_modules": Vector2(1.0, 1.0),
		"height_world": 14.5,
		"footprint_corners_px": [
			Vector2(132, 940),
			Vector2(640, 645),
			Vector2(1148, 940),
			Vector2(640, 1235),
		],
		"occlusion_depth": 14.0,
	}
}


static func get_definition(building_id: String) -> Dictionary:
	return DEFINITIONS.get(building_id, {}).duplicate(true)


static func is_valid_definition(definition: Dictionary) -> bool:
	if definition.is_empty():
		return false
	var footprint: Vector2i = definition.get("footprint_modules", Vector2i.ZERO)
	var corners: Array = definition.get("footprint_corners_px", [])
	return (
		footprint.x >= 2
		and footprint.y >= 2
		and footprint.x % 2 == 0
		and footprint.y % 2 == 0
		and corners.size() == 4
		and float(definition.get("height_world", 0.0)) > 0.0
	)
