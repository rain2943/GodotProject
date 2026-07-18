extends Node

const BUILDING_SCENE_PATH := "res://scenes/building_interior.tscn"
const FIELD_SCENE_PATH := "res://scenes/main.tscn"

var active := false
var building_id := ""
var building_seed := 0
var current_floor := 1
var max_floors := 4
var source_scene_path := FIELD_SCENE_PATH
var return_position := Vector3.ZERO
var pending_field_return := false
var floor_state: Dictionary = {}


func begin_run(
	entrance_id: String,
	seed_value: int,
	source_path: String,
	field_position: Vector3,
	floor_count: int = 4
) -> void:
	active = true
	building_id = entrance_id
	building_seed = seed_value
	current_floor = 1
	max_floors = clampi(floor_count, 2, 12)
	source_scene_path = source_path if not source_path.is_empty() else FIELD_SCENE_PATH
	return_position = field_position
	pending_field_return = false
	floor_state.clear()


func get_floor_seed(floor_number: int) -> int:
	return absi(building_seed ^ (floor_number * 104729) ^ (floor_number * floor_number * 8191))


func get_floor_state(floor_number: int) -> Dictionary:
	if not floor_state.has(floor_number):
		floor_state[floor_number] = {
			"collected_loot": {},
			"defeated_enemies": {},
		}
	return floor_state[floor_number] as Dictionary


func mark_loot_collected(floor_number: int, loot_key: String) -> void:
	var state := get_floor_state(floor_number)
	(state["collected_loot"] as Dictionary)[loot_key] = true


func is_loot_collected(floor_number: int, loot_key: String) -> bool:
	var state := get_floor_state(floor_number)
	return bool((state["collected_loot"] as Dictionary).get(loot_key, false))


func mark_enemy_defeated(floor_number: int, enemy_key: String) -> void:
	var state := get_floor_state(floor_number)
	(state["defeated_enemies"] as Dictionary)[enemy_key] = true


func is_enemy_defeated(floor_number: int, enemy_key: String) -> bool:
	var state := get_floor_state(floor_number)
	return bool((state["defeated_enemies"] as Dictionary).get(enemy_key, false))


func leave_building() -> void:
	if not active:
		return
	active = false
	pending_field_return = true
	get_tree().change_scene_to_file(source_scene_path)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	var key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
	if key != KEY_2:
		return
	var current := get_tree().current_scene
	if current == null or current.scene_file_path != FIELD_SCENE_PATH:
		return
	var player := current.get_node_or_null("Player") as Node3D
	var field_position := player.global_position if player != null else Vector3.ZERO
	var game_state := get_node("/root/GameState")
	begin_run(
		"debug_office_tower",
		int(game_state.get("map_seed")) ^ 0x424C4447,
		FIELD_SCENE_PATH,
		field_position,
		5
	)
	get_viewport().set_input_as_handled()
	get_tree().call_deferred("change_scene_to_file", BUILDING_SCENE_PATH)


func _process(_delta: float) -> void:
	if not pending_field_return:
		return
	var current := get_tree().current_scene
	if current == null or current.scene_file_path != source_scene_path:
		return
	var player := current.get_node_or_null("Player") as Node3D
	if player == null:
		return
	player.global_position = return_position
	pending_field_return = false
