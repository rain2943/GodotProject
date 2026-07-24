extends Node

const OUTPUT_PATH := "res://test-output/shelter_workstations_isometric_v4.png"
const FULL_OUTPUT_PATH := "res://test-output/shelter_workstations_isometric_v4_full.png"


func _ready() -> void:
	var shelter := get_node("ShelterInterior")
	for _frame in 12:
		await get_tree().process_frame
	shelter.set_physics_process(false)
	for child in shelter.get_children():
		if child is CanvasLayer:
			child.visible = false
	var camera := shelter.get_node_or_null("ShelterCamera") as Camera3D
	if camera != null:
		var focus := Vector3(0.0, 0.0, -10.5)
		camera.size = 18.5
		camera.position = focus + Vector3(18.0, 18.0, 18.0)
		camera.look_at(focus)
	for _frame in 4:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	if error == OK:
		print("VISUAL_CAPTURE_OK ", ProjectSettings.globalize_path(OUTPUT_PATH))
	else:
		push_error("Visual capture failed: %s" % error_string(error))
	if camera != null:
		var full_focus := Vector3.ZERO
		camera.size = 27.0
		camera.position = full_focus + Vector3(18.0, 18.0, 18.0)
		camera.look_at(full_focus)
	for _frame in 4:
		await get_tree().process_frame
	var full_image := get_viewport().get_texture().get_image()
	var full_error := full_image.save_png(FULL_OUTPUT_PATH)
	if full_error == OK:
		print("VISUAL_CAPTURE_OK ", ProjectSettings.globalize_path(FULL_OUTPUT_PATH))
	else:
		push_error("Full visual capture failed: %s" % error_string(full_error))
		if error == OK:
			error = full_error
	get_tree().quit(error)
