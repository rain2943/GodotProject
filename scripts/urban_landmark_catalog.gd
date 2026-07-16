class_name UrbanLandmarkCatalog
extends RefCounted

const MODULES_PER_CELL := 10

const DEFINITIONS := {
	"pocket_park": {
		"node_name": "PocketPark",
		"texture_path": "res://assets/landmarks/urban_pocket_park_8x8_sealed_aligned.png",
		"footprint_modules": Vector2i(8, 8),
		"footprint_corners_px": [
			Vector2(55, 657),
			Vector2(628, 371),
			Vector2(1200, 657),
			Vector2(627, 943),
		],
		"collision_boxes": [
			{"offset": Vector2.ZERO, "size": Vector2(8.0, 8.0), "height": 2.4},
		],
	},
	"playground": {
		"node_name": "UrbanPlayground",
		"texture_path": "res://assets/landmarks/urban_playground_8x8_sealed_aligned.png",
		"footprint_modules": Vector2i(8, 8),
		"footprint_corners_px": [
			Vector2(25, 598),
			Vector2(624, 299),
			Vector2(1226, 600),
			Vector2(627, 899),
		],
		"collision_boxes": [
			{"offset": Vector2.ZERO, "size": Vector2(8.0, 8.0), "height": 2.4},
		],
	},
	"subway_entrance": {
		"node_name": "SubwayEntrance",
		"texture_path": "res://assets/landmarks/subway_entrance_4x4_aligned.png",
		"footprint_modules": Vector2i(4, 4),
		"footprint_corners_px": [
			Vector2(157, 885),
			Vector2(646, 641),
			Vector2(1100, 867),
			Vector2(610, 1139),
		],
		"collision_boxes": [
			{"offset": Vector2(0.0, 0.0), "size": Vector2(4.0, 4.0)},
		],
	},
	"apartment_complex": {
		"node_name": "KoreanApartmentComplex",
		"texture_path": "res://assets/landmarks/korean_apartment_complex_18x18_aligned.png",
		"footprint_modules": Vector2i(18, 18),
		"footprint_corners_px": [
			Vector2(47, 621),
			Vector2(550, 369),
			Vector2(1200, 694),
			Vector2(751, 871),
		],
		# Each apartment slab and the perimeter are separate collision modules.
		# The southern and eastern wall gaps deliberately match the two gates.
		"collision_boxes": [
			{"offset": Vector2(0.0, -5.9), "size": Vector2(7.2, 3.1)},
			{"offset": Vector2(-6.0, -1.2), "size": Vector2(3.2, 7.0)},
			{"offset": Vector2(6.0, -1.0), "size": Vector2(3.2, 6.2)},
			{"offset": Vector2(2.6, 5.1), "size": Vector2(4.2, 4.0)},
			{"offset": Vector2(0.0, -8.7), "size": Vector2(18.0, 0.6)},
			{"offset": Vector2(-8.7, 0.0), "size": Vector2(0.6, 18.0)},
			{"offset": Vector2(-7.4, 8.7), "size": Vector2(2.6, 0.6)},
			{"offset": Vector2(1.5, 8.7), "size": Vector2(12.0, 0.6)},
			{"offset": Vector2(8.7, -3.1), "size": Vector2(0.6, 11.2)},
			{"offset": Vector2(8.7, 7.3), "size": Vector2(0.6, 2.8)},
		],
	},
}


static func get_definition(landmark_id: String) -> Dictionary:
	return DEFINITIONS.get(landmark_id, {}).duplicate(true)
