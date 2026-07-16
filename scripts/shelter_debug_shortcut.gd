extends Node

const SHELTER_SCENE_PATH := "res://scenes/shelter_interior.tscn"


func is_shelter_shortcut(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	var key := event.keycode if event.keycode != 0 else event.physical_keycode
	return key == KEY_1


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not is_shelter_shortcut(event as InputEventKey):
		return
	var current := get_tree().current_scene
	if current != null and current.scene_file_path == SHELTER_SCENE_PATH:
		return
	get_viewport().set_input_as_handled()
	get_tree().call_deferred("change_scene_to_file", SHELTER_SCENE_PATH)
