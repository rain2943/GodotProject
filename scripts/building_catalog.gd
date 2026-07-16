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
		"height_class": "high",
		"density_weight": 0.35,
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
		"height_class": "high",
		"density_weight": 0.25,
	},
	"gangnam_single_story_8x4_aligned": {
		"node_name": "GangnamSingleStory",
		"texture_path": "res://assets/buildings/gangnam_single_story_8x4_aligned.png",
		"footprint_modules": Vector2i(8, 4),
		"height_world": 3.6,
		"footprint_corners_px": [
			Vector2(40, 678),
			Vector2(399, 498),
			Vector2(1229, 913),
			Vector2(870, 1102),
		],
		"occlusion_depth": 5.5,
		"height_class": "low",
		"density_weight": 3.0,
	},
	"gangnam_ruined_lowrise_6x8_aligned": {
		"node_name": "GangnamRuinedLowrise",
		"texture_path": "res://assets/buildings/gangnam_ruined_lowrise_6x8_aligned.png",
		"footprint_modules": Vector2i(6, 8),
		"height_world": 8.5,
		"footprint_corners_px": [
			Vector2(40, 1013),
			Vector2(694, 686),
			Vector2(1219, 949),
			Vector2(563, 1220),
		],
		"occlusion_depth": 10.0,
		"height_class": "mid",
		"density_weight": 1.1,
	},
	"gangnam_glass_tower_6x4_aligned": {
		"node_name": "GangnamGlassTower",
		"texture_path": "res://assets/buildings/gangnam_glass_tower_6x4_aligned.png",
		"footprint_modules": Vector2i(6, 4),
		"height_world": 15.5,
		"footprint_corners_px": [
			Vector2(332, 1021),
			Vector2(549, 912),
			Vector2(922, 1099),
			Vector2(695, 1227),
		],
		"occlusion_depth": 14.0,
		"height_class": "high",
		"density_weight": 0.2,
	},
	"gangnam_lowrise_commercial_8x4_aligned": {
		"node_name": "GangnamLowriseCommercial",
		"texture_path": "res://assets/buildings/gangnam_lowrise_commercial_8x4_aligned.png",
		# The generated artwork's long axis runs along world Z. Treating it as
		# 8x4 rotated its collision box ninety degrees away from the storefront.
		"footprint_modules": Vector2i(4, 8),
		"height_world": 5.6,
		"footprint_corners_px": [
			Vector2(263, 927),
			Vector2(1029, 544),
			Vector2(1269, 663),
			Vector2(502, 1047),
		],
		"occlusion_depth": 6.8,
		"height_class": "low",
		"density_weight": 3.2,
	},
	"gangnam_lowrise_garage_8x4_aligned": {
		"node_name": "GangnamLowriseGarage",
		"texture_path": "res://assets/buildings/gangnam_lowrise_garage_8x4_aligned.png",
		"footprint_modules": Vector2i(8, 4),
		"height_world": 3.8,
		"footprint_corners_px": [
			Vector2(93, 703),
			Vector2(450, 525),
			Vector2(1176, 888),
			Vector2(819, 1066),
		],
		"occlusion_depth": 5.0,
		"height_class": "low",
		"density_weight": 3.5,
	},
	"gangnam_clinic_pharmacy_6x4_aligned": {
		"node_name": "GangnamClinicPharmacy",
		"texture_path": "res://assets/buildings/gangnam_clinic_pharmacy_6x4_aligned.png",
		"footprint_modules": Vector2i(6, 4),
		"height_world": 8.0,
		"footprint_corners_px": [
			Vector2(466, 795),
			Vector2(829, 613),
			Vector2(1065, 731),
			Vector2(702, 913),
		],
		"occlusion_depth": 9.2,
		"height_class": "mid",
		"density_weight": 1.35,
	},
	"gangnam_food_alley_4x6_aligned": {
		"node_name": "GangnamFoodAlley",
		"texture_path": "res://assets/buildings/gangnam_food_alley_4x6_aligned.png",
		"footprint_modules": Vector2i(4, 6),
		"height_world": 5.4,
		"footprint_corners_px": [
			Vector2(122, 1093),
			Vector2(620, 844),
			Vector2(907, 988),
			Vector2(409, 1237),
		],
		"occlusion_depth": 6.6,
		"height_class": "low",
		"density_weight": 2.8,
	},
	"gangnam_damaged_officetel_6x6_aligned": {
		"node_name": "GangnamDamagedOfficetel",
		"texture_path": "res://assets/buildings/gangnam_damaged_officetel_6x6_aligned.png",
		"footprint_modules": Vector2i(6, 6),
		"height_world": 13.0,
		"footprint_corners_px": [
			Vector2(279, 942),
			Vector2(629, 767),
			Vector2(975, 940),
			Vector2(625, 1115),
		],
		"occlusion_depth": 13.8,
		"height_class": "mid",
		"density_weight": 0.65,
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
