extends Area3D

const BUILDING_SCENE_PATH := "res://scenes/building_interior.tscn"

@export var building_id := "office_tower"
@export var seed_offset := 0
@export_range(2, 12, 1) var floor_count := 5
@export var return_offset := Vector3(0.0, 0.0, 2.2)

var nearby_player: Node3D
@onready var BuildingRunState: Node = get_node("/root/BuildingRunState")
@onready var GameState: Node = get_node("/root/GameState")


func _ready() -> void:
	add_to_group("building_entrance_portal")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_E:
		return
	enter_building(nearby_player)
	get_viewport().set_input_as_handled()


func enter_building(player_body: Node3D) -> void:
	var current := get_tree().current_scene
	var source_path := current.scene_file_path if current != null else "res://scenes/main.tscn"
	var return_point := global_position + global_basis * return_offset
	BuildingRunState.begin_run(
		building_id,
		int(GameState.map_seed) ^ seed_offset ^ building_id.hash(),
		source_path,
		return_point,
		floor_count
	)
	get_tree().change_scene_to_file(BUILDING_SCENE_PATH)


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		nearby_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == nearby_player:
		nearby_player = null
