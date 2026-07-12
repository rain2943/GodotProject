class_name BuildingCatalog
extends RefCounted

const MODULE_SIZE := 1.0
const MODULES_PER_CELL := 10

const DEFINITIONS := {
	"hanbit_apartment_8x4": {
		"node_name": "HanbitApartment",
		"texture_path": "res://assets/buildings/hanbit_apartment_8x4.png",
		"footprint_modules": Vector2i(8, 4),
		"height_world": 12.5,
		"footprint_corners_px": [
			Vector2(289, 1116),
			Vector2(528, 996),
			Vector2(1007, 1235),
			Vector2(768, 1355),
		],
		"occlusion_depth": 11.0,
	},
	"academy_tower_6x4": {
		"node_name": "AcademyTower",
		"texture_path": "res://assets/buildings/academy_tower_6x4.png",
		"footprint_modules": Vector2i(6, 4),
		"height_world": 16.0,
		"footprint_corners_px": [
			Vector2(337, 1140),
			Vector2(624, 996),
			Vector2(1055, 1211),
			Vector2(768, 1355),
		],
		"occlusion_depth": 13.0,
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
