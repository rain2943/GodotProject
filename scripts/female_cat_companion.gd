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
var max_health := 70
var health := 70
var downed := false
var hit_stun_time := 0.0
var hit_flash_time := 0.0
var hit_velocity := Vector3.ZERO
var health_bar_background: Sprite3D
var health_bar_fill: Sprite3D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	sprite.sprite_frames = _create_sprite_frames()
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.render_priority = 126
	sprite.no_depth_test = true
	target = get_node_or_null(target_path) as Node3D
	_setup_health_bar()
	_play_animation()


func _physics_process(delta: float) -> void:
	hit_stun_time = maxf(0.0, hit_stun_time - delta)
	hit_flash_time = maxf(0.0, hit_flash_time - delta)
	if hit_flash_time <= 0.0 and not downed:
		sprite.modulate = Color.WHITE
	if downed:
		velocity = Vector3.ZERO
		return
	if hit_stun_time > 0.0:
		velocity = hit_velocity
		hit_velocity = hit_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
		move_and_slide()
		return
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


func _setup_health_bar() -> void:
	health_bar_background = Sprite3D.new()
	health_bar_background.name = "CompanionHealthBackground"
	health_bar_background.texture = _create_bar_texture(Color(0.035, 0.04, 0.04, 0.94), true)
	health_bar_background.position = Vector3(0, 1.72, 0)
	health_bar_background.pixel_size = 0.007
	health_bar_background.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_background.shaded = false
	health_bar_background.no_depth_test = true
	health_bar_background.render_priority = 120
	health_bar_background.visible = false
	add_child(health_bar_background)
	health_bar_fill = Sprite3D.new()
	health_bar_fill.name = "CompanionHealthFill"
	health_bar_fill.texture = _create_bar_texture(Color("#67d899"), false)
	health_bar_fill.position = Vector3(0, 1.72, 0)
	health_bar_fill.pixel_size = 0.007
	health_bar_fill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_fill.shaded = false
	health_bar_fill.no_depth_test = true
	health_bar_fill.render_priority = 121
	health_bar_fill.centered = false
	health_bar_fill.offset = Vector2(-35, -4)
	health_bar_fill.region_enabled = true
	health_bar_fill.visible = false
	add_child(health_bar_fill)


func _create_bar_texture(color: Color, bordered: bool) -> Texture2D:
	var image := Image.create(70, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	if bordered:
		image.fill_rect(Rect2i(0, 0, 70, 8), Color(0.0, 0.0, 0.0, 0.86))
		image.fill_rect(Rect2i(2, 2, 66, 4), color)
	else:
		image.fill_rect(Rect2i(0, 0, 70, 8), color)
	return ImageTexture.create_from_image(image)


func _update_health_bar() -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_bar_background.visible = ratio < 0.999 and not downed
	health_bar_fill.visible = health_bar_background.visible
	health_bar_fill.region_rect = Rect2(0, 0, maxf(1.0, 70.0 * ratio), 8)


func get_projectile_hit_center() -> Vector3:
	return global_position + Vector3(0, 0.52, 0)


func get_projectile_hit_radius() -> float:
	return 0.46


func take_damage(amount: int) -> void:
	take_hit(amount, Vector3.ZERO)


func take_hit(amount: int, hit_direction: Vector3) -> void:
	if downed:
		return
	health = maxi(0, health - amount)
	hit_flash_time = 0.18
	hit_stun_time = 0.12
	sprite.modulate = Color(2.0, 0.24, 0.18, 1.0)
	var knockback := hit_direction
	knockback.y = 0.0
	if knockback.length_squared() > 0.01:
		hit_velocity = knockback.normalized() * 2.5
	_update_health_bar()
	if health <= 0:
		downed = true
		collision_layer = 0
		collision_mask = 0
		velocity = Vector3.ZERO
		sprite.modulate = Color(0.32, 0.31, 0.3, 0.76)
		sprite.rotation.z = deg_to_rad(78.0)
		sprite.position.y = 0.06
		health_bar_background.visible = false
		health_bar_fill.visible = false


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
