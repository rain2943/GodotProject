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
		"node_name": "KoreanApartmentGateway",
		"texture_path": "res://assets/landmarks/korean_apartment_gateway_36x32_aligned.png",
		"footprint_modules": Vector2i(36, 32),
		"footprint_corners_px": [
			Vector2(60, 466),
			Vector2(866, 63),
			Vector2(1670, 631),
			Vector2(390, 932),
		],
		# A large estate continues beyond the north map edge. Only its closed
		# frontage is reachable; the central gap is filled by a modular portal
		# blocker in procedural_map.gd so it can be replaced by a portal later.
		"collision_boxes": [
			{"offset": Vector2(-13.0, -4.0), "size": Vector2(8.0, 22.0), "height": 3.4},
			{"offset": Vector2(13.0, -4.0), "size": Vector2(8.0, 22.0), "height": 3.4},
			{"offset": Vector2(0.0, -11.0), "size": Vector2(14.0, 8.0), "height": 3.4},
			{"offset": Vector2(-17.4, -2.0), "size": Vector2(1.2, 27.0), "height": 2.8},
			{"offset": Vector2(17.4, -2.0), "size": Vector2(1.2, 27.0), "height": 2.8},
			{"offset": Vector2(0.0, -15.4), "size": Vector2(36.0, 1.2), "height": 2.8},
			{"offset": Vector2(-12.0, 15.4), "size": Vector2(12.0, 1.2), "height": 2.8},
			{"offset": Vector2(12.0, 15.4), "size": Vector2(12.0, 1.2), "height": 2.8},
			{"offset": Vector2(-10.0, 12.4), "size": Vector2(5.0, 5.0), "height": 3.4},
		],
	},
}


static func get_definition(landmark_id: String) -> Dictionary:
	return DEFINITIONS.get(landmark_id, {}).duplicate(true)
