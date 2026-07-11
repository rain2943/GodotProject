class_name BuildingCatalog
extends RefCounted

const MODULE_SIZE := 1.0
const MODULES_PER_CELL := 10

const DEFINITIONS := {
	"hanbit_8x8": {
		"node_name": "HanbitBuilding",
		"texture_path": "res://assets/buildings/hanbit_building.png",
		"footprint_modules": Vector2i(8, 8),
		"wall_inset_modules": Vector2(0.4, 0.4),
		"height_world": 14.5,
		"base_pixel_width": 980.0,
		"ground_pixel_y": 1260.0,
		"occlusion_depth": 14.0,
	}
}


static func get_definition(building_id: String) -> Dictionary:
	return DEFINITIONS.get(building_id, {}).duplicate(true)


static func is_valid_definition(definition: Dictionary) -> bool:
	if definition.is_empty():
		return false
	var footprint: Vector2i = definition.get("footprint_modules", Vector2i.ZERO)
	return (
		footprint.x >= 2
		and footprint.y >= 2
		and footprint.x % 2 == 0
		and footprint.y % 2 == 0
		and float(definition.get("base_pixel_width", 0.0)) > 0.0
		and float(definition.get("height_world", 0.0)) > 0.0
	)
