class_name VehicleCatalog
extends RefCounted

const DEFINITIONS := {
	"sedan": {
		"texture_path": "res://assets/vehicles/wrecked_sedan.png",
		"collision_size": Vector3(4.65, 1.45, 1.82),
		"footprint_corners_px": [
			Vector2(8, 358),
			Vector2(455, 134),
			Vector2(712, 263),
			Vector2(265, 487),
		],
	},
	"truck": {
		"texture_path": "res://assets/vehicles/wrecked_truck.png",
		"collision_size": Vector3(6.65, 2.85, 2.28),
		"footprint_corners_px": [
			Vector2(15, 590),
			Vector2(491, 352),
			Vector2(770, 492),
			Vector2(294, 730),
		],
	},
	"bus": {
		"texture_path": "res://assets/vehicles/wrecked_bus.png",
		"collision_size": Vector3(10.6, 3.15, 2.55),
		"footprint_corners_px": [
			Vector2(10, 487),
			Vector2(578, 203),
			Vector2(850, 339),
			Vector2(282, 623),
		],
	},
}


static func get_definition(vehicle_type: String) -> Dictionary:
	return DEFINITIONS.get(vehicle_type, {}).duplicate(true)
