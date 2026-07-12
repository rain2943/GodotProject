class_name BuildingCatalog
extends RefCounted

const MODULE_SIZE := 1.0
const MODULES_PER_CELL := 10

const DEFINITIONS := {
	"hanbit_8x8": {
		"node_name": "HanbitBuilding",
		"texture_path": "res://assets/buildings/hanbit_building_v2.png",
		"footprint_modules": Vector2i(8, 8),
		"height_world": 14.5,
		"footprint_corners_px": [
			Vector2(409, 1148),
			Vector2(768, 941),
			Vector2(1127, 1148),
			Vector2(768, 1355),
		],
		"occlusion_depth": 14.0,
	},
	"academy_8x8": {
		"node_name": "AcademyBuilding",
		"texture_path": "res://assets/buildings/academy_building_v2.png",
		"footprint_modules": Vector2i(8, 8),
		"height_world": 15.0,
		"footprint_corners_px": [
			Vector2(409, 1148),
			Vector2(768, 941),
			Vector2(1127, 1148),
			Vector2(768, 1355),
		],
		"occlusion_depth": 14.5,
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
