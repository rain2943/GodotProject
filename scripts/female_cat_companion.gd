extends CharacterBody3D


const ANIMATION_ROOT := "res://assets/characters/female_cat_companion"
const DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const DIRECTION_STATES := {
	"n": "up",
	"ne": "up_right",
	"e": "right",
	"se": "down_right",
	"s": "down",
	"sw": "down_left",
	"w": "left",
	"nw": "up_left",
}
const FRAME_COUNT := 4
const WALK_SPEED := 5.7
const STOP_DISTANCE := 2.15
const RESUME_DISTANCE := 2.55

@export var target_path: NodePath

@onready var sprite: AnimatedSprite3D = $Sprite

var target: Node3D
var facing := "s"
var motion_state := "idle"
var following := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	sprite.sprite_frames = _create_sprite_frames()
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.render_priority = 126
	sprite.no_depth_test = true
	target = get_node_or_null(target_path) as Node3D
	_play_animation()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		_set_motion_state("idle")
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if following:
		following = distance > STOP_DISTANCE
	else:
		following = distance > RESUME_DISTANCE

	if following and distance > 0.01:
		var move_direction := offset / distance
		velocity = move_direction * WALK_SPEED
		_set_facing_from_world_direction(move_direction)
		_set_motion_state("walk")
	else:
		velocity = Vector3.ZERO
		_set_motion_state("idle")
	move_and_slide()


func _set_facing_from_world_direction(world_direction: Vector3) -> void:
	if world_direction.length_squared() <= 0.01:
		return
	var screen_direction := Vector2(
		world_direction.x - world_direction.z,
		world_direction.x + world_direction.z
	).normalized()
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % DIRECTION_NAMES.size()
	_set_facing(DIRECTION_NAMES[index])


func _set_facing(next_facing: String) -> void:
	if facing == next_facing:
		return
	facing = next_facing
	_play_animation()


func _set_motion_state(next_state: String) -> void:
	if motion_state == next_state:
		return
	motion_state = next_state
	_play_animation()


func _play_animation() -> void:
	sprite.flip_h = false
	sprite.play("%s_%s" % [motion_state, facing])


func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in DIRECTION_NAMES:
		var state_prefix: String = DIRECTION_STATES[direction_name]
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 4.0 if state == "idle" else 8.0)
			for frame_index in FRAME_COUNT:
				var texture_path := "%s/%s_%s_%d.png" % [
					ANIMATION_ROOT, state_prefix, state, frame_index
				]
				var texture := load(texture_path) as Texture2D
				if texture == null:
					push_error("Missing female cat companion frame: %s" % texture_path)
					continue
				frames.add_frame(animation_name, texture)
	return frames
