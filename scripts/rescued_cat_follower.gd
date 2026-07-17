class_name RescuedCatFollower
extends CharacterBody3D


const ANIMATION_ROOT := "res://assets/characters/worker_cat"
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
const WALK_SPEED := 5.4

var follow_target: Node3D
var formation_index := 0
var facing := "s"
var motion_state := "idle"
var sprite: AnimatedSprite3D


func setup(target: Node3D, index: int) -> void:
	follow_target = target
	formation_index = index


func _ready() -> void:
	add_to_group("rescued_follower")
	collision_layer = 0
	collision_mask = 1
	sprite = AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = _create_sprite_frames()
	sprite.pixel_size = 0.0078
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.render_priority = 125
	sprite.no_depth_test = true
	sprite.modulate = Color.WHITE
	add_child(sprite)
	_play_animation()

	var marker := Label3D.new()
	marker.name = "RescueMarker"
	marker.text = "+"
	marker.position = Vector3(0, 1.65, 0)
	marker.font_size = 34
	marker.modulate = Color("#85d5ae")
	marker.outline_size = 8
	marker.no_depth_test = true
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(marker)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(follow_target):
		velocity = Vector3.ZERO
		_set_motion_state("idle")
		return
	var lateral_side := -1.0 if formation_index % 2 == 0 else 1.0
	var row := floori(formation_index / 2.0)
	var back_direction := Vector3(0, 0, 1)
	if follow_target is CharacterBody3D:
		var target_velocity := (follow_target as CharacterBody3D).velocity
		target_velocity.y = 0.0
		if target_velocity.length_squared() > 0.1:
			back_direction = -target_velocity.normalized()
	var lateral_direction := Vector3(-back_direction.z, 0, back_direction.x)
	var target_position := (
		follow_target.global_position
		+ back_direction * (1.9 + row * 1.05)
		+ lateral_direction * lateral_side * (0.85 + row * 0.14)
	)
	var offset := target_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > 0.55:
		var direction := offset / distance
		var catchup := clampf(distance / 3.2, 1.0, 1.55)
		velocity = direction * WALK_SPEED * catchup
		_set_facing_from_world_direction(direction)
		_set_motion_state("walk")
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		_set_motion_state("idle")


func _set_facing_from_world_direction(world_direction: Vector3) -> void:
	var screen_direction := Vector2(
		world_direction.x - world_direction.z,
		world_direction.x + world_direction.z
	).normalized()
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % DIRECTION_NAMES.size()
	var next_facing: String = DIRECTION_NAMES[index]
	if facing != next_facing:
		facing = next_facing
		_play_animation()


func _set_motion_state(next_state: String) -> void:
	if motion_state == next_state:
		return
	motion_state = next_state
	_play_animation()


func _play_animation() -> void:
	if sprite:
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
				var texture_path := "%s/%s_%s-frame-%d.png" % [
					ANIMATION_ROOT,
					state_prefix,
					state,
					frame_index,
				]
				var texture := load(texture_path) as Texture2D
				if texture:
					frames.add_frame(animation_name, texture)
				else:
					push_error("Missing worker cat frame: %s" % texture_path)
	return frames
