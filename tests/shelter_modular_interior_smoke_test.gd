extends SceneTree

const SHELTER_SCENE_PATH := "res://scenes/shelter_interior.tscn"
const SHELL_TEXTURE_PATH := "res://assets/interiors/shelter_stage1_modular_shell_v2.png"
const BED_TEXTURE_PATH := "res://assets/interiors/shelter_bed_module_v2.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(ResourceLoader.exists(SHELL_TEXTURE_PATH))
	assert(ResourceLoader.exists(BED_TEXTURE_PATH))
	var shelter := load(SHELTER_SCENE_PATH).instantiate() as Node3D
	root.add_child(shelter)
	await process_frame
	await physics_frame

	var room_art := shelter.get_node("ShelterInteriorArt") as MeshInstance3D
	assert(room_art != null)
	var room_mesh := room_art.mesh as PlaneMesh
	assert(room_mesh.size == Vector2(36.0, 20.25))
	var room_material := room_mesh.material as StandardMaterial3D
	assert(room_material.albedo_texture.resource_path == SHELL_TEXTURE_PATH)

	var module_root := shelter.get_node("StageOneModules") as Node3D
	assert(int(module_root.get_meta("stage")) == 1)
	assert(int(module_root.get_meta("cat_capacity")) == 5)
	assert(module_root.get_meta("module_grid_size") == Vector2(3.45, 2.65))
	assert(get_nodes_in_group("shelter_module_slot").size() == 5)
	assert(get_nodes_in_group("shelter_bed").size() == 5)
	for slot in get_nodes_in_group("shelter_module_slot"):
		assert(bool(slot.get_meta("replaceable")))
		assert(str(slot.get_meta("module_kind")) == "bed")
		assert((slot as Node).get_node("ModuleFloorPlate") is MeshInstance3D)
	for bed in get_nodes_in_group("shelter_bed"):
		var sprite := (bed as Node).get_node("BedSprite") as Sprite3D
		assert(sprite.texture.resource_path == BED_TEXTURE_PATH)
		var collision := (bed as Node).get_node("BedBody/CollisionShape3D") as CollisionShape3D
		var shape := collision.shape as BoxShape3D
		assert(shape.size == Vector3(2.55, 0.9, 2.05))

	assert(shelter.get_node("ShelterPlayer") is CharacterBody3D)
	for wall_name in [
		"NorthWallCollision", "SouthWallLeftCollision", "SouthWallRightCollision",
		"WestWallCollision", "EastWallCollision",
	]:
		assert(shelter.get_node(wall_name) is StaticBody3D)

	var shortcut := root.get_node_or_null("ShelterDebugShortcut")
	assert(shortcut != null)
	assert(str(ProjectSettings.get_setting("autoload/ShelterDebugShortcut")).ends_with("shelter_debug_shortcut.gd"))
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_1
	key_event.pressed = true
	assert(bool(shortcut.call("is_shelter_shortcut", key_event)))

	print("SHELTER_MODULAR_OK beds=5 slots=5 shortcut=KEY_1 walls=5")
	quit(0)
