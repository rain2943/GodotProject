extends Node3D

const MOVE_SPEED := 5.2
const MAP_LIMIT := 43.5
const OCCLUSION_LATERAL_LIMIT := 5.1
const OCCLUSION_DEPTH_LIMIT := 14.0
const SILHOUETTE_COLOR := Color("#26343b")
const ANIMATION_SHEETS := {
	"s": preload("res://assets/characters/survivor_anim_s.png"),
	"se": preload("res://assets/characters/survivor_anim_se.png"),
	"e": preload("res://assets/characters/survivor_anim_e.png"),
	"ne": preload("res://assets/characters/survivor_anim_ne.png"),
	"n": preload("res://assets/characters/survivor_anim_n.png"),
}
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const FRAME_SIZE := Vector2(384, 384)

@onready var player: CharacterBody3D = $Player
@onready var survivor: AnimatedSprite3D = $Player/Survivor
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var touch_stick: Control = $HUD/TouchStick
@onready var touch_knob: Control = $HUD/TouchStick/Knob
@onready var location_label: Label = $HUD/TopRight/Location
@onready var state_label: Label = $HUD/TopRight/State

var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO
var facing := "s"
var motion_state := "idle"
var occlusion_masks := {}


func _ready() -> void:
	camera.position = Vector3(10.5, 10.5, 10.5)
	camera.look_at(Vector3.ZERO)
	$SmokeA.emitting = false
	$SmokeB.emitting = false
	survivor.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	survivor.render_priority = 127
	survivor.no_depth_test = true
	touch_stick.visible = DisplayServer.is_touchscreen_available()
	_build_sprite_frames()
	_set_facing("s")


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W): input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_vector.y += 1.0
	input_vector = input_vector.limit_length(1.0)
	if touch_vector.length_squared() > input_vector.length_squared():
		input_vector = touch_vector

	var world_direction := Vector3(input_vector.x + input_vector.y, 0, -input_vector.x + input_vector.y)
	if world_direction.length_squared() > 0.01:
		world_direction = world_direction.normalized()
		player.velocity = world_direction * MOVE_SPEED
		_update_facing(input_vector)
		_set_motion_state("walk")
		state_label.text = "이동 중"
	else:
		player.velocity = Vector3.ZERO
		_set_motion_state("idle")
		state_label.text = "경계 중"

	player.move_and_slide()
	player.position.x = clampf(player.position.x, -MAP_LIMIT, MAP_LIMIT)
	player.position.z = clampf(player.position.z, -MAP_LIMIT, MAP_LIMIT)
	_update_camera_occluders(delta)
	camera_rig.position = camera_rig.position.lerp(Vector3(player.position.x, 0, player.position.z), 1.0 - exp(-7.0 * delta))
	$CameraRig/Rain.position.y = 8.0
	location_label.text = "종로 생존구역  ·  %02d / %02d" % [roundi(player.position.x + 32), roundi(player.position.z + 32)]


func _update_facing(screen_direction: Vector2) -> void:
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % 8
	_set_facing(SCREEN_DIRECTION_NAMES[index])


func _set_facing(direction_name: String) -> void:
	if facing == direction_name and survivor.is_playing():
		return
	facing = direction_name
	_play_directional_animation()


func _set_motion_state(next_state: String) -> void:
	if motion_state == next_state:
		return
	motion_state = next_state
	_play_directional_animation()


func _play_directional_animation() -> void:
	var source := facing
	var flipped := false
	match facing:
		"sw": source = "se"; flipped = true
		"w": source = "e"; flipped = true
		"nw": source = "ne"; flipped = true
	survivor.flip_h = flipped
	survivor.play("%s_%s" % [motion_state, source])


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in ANIMATION_SHEETS:
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 7.0 if state == "idle" else 8.5)
			var first_frame := 0 if state == "idle" else 8
			for frame_index in range(first_frame, first_frame + 8):
				var atlas := AtlasTexture.new()
				atlas.atlas = ANIMATION_SHEETS[direction_name]
				atlas.region = Rect2(
					(frame_index % 4) * FRAME_SIZE.x,
					(frame_index / 4) * FRAME_SIZE.y,
					FRAME_SIZE.x,
					FRAME_SIZE.y
				)
				var cycle_index := frame_index - first_frame
				var duration := 1.6 if state == "walk" and direction_name == "ne" and cycle_index in [2, 6] else 1.0
				frames.add_frame(animation_name, atlas, duration)
	survivor.sprite_frames = frames


func _update_camera_occluders(delta: float) -> void:
	var camera_direction := Vector2(1, 1).normalized()
	var player_position := Vector2(player.position.x, player.position.z)
	var player_is_occluded := false
	for node in get_tree().get_nodes_in_group("camera_occluder"):
		var building := node as Node3D
		var player_offset := Vector2(building.global_position.x, building.global_position.z) - player_position
		var depth := player_offset.dot(camera_direction)
		var lateral := absf(player_offset.cross(camera_direction))
		var lateral_limit := float(building.get_meta("occlusion_lateral_limit", OCCLUSION_LATERAL_LIMIT))
		var depth_limit := float(building.get_meta("occlusion_depth_limit", OCCLUSION_DEPTH_LIMIT))
		var sprite := building.get_node_or_null("BuildingSprite") as Sprite3D
		var is_occluding := (
			sprite != null
			and depth > 0.8
			and depth < depth_limit
			and lateral < lateral_limit
			and _is_player_inside_sprite_screen_rect(sprite)
		)
		player_is_occluded = player_is_occluded or is_occluding
		if sprite:
			var color := sprite.modulate
			var target_alpha := 0.38 if is_occluding else 1.0
			color.a = move_toward(color.a, target_alpha, delta * 3.8)
			sprite.modulate = color
	var target_player_color := SILHOUETTE_COLOR if player_is_occluded else Color.WHITE
	survivor.modulate = survivor.modulate.lerp(target_player_color, 1.0 - exp(-10.0 * delta))


func _is_player_inside_sprite_screen_rect(sprite: Sprite3D) -> bool:
	if sprite.texture == null or camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		return false
	var viewport_height := get_viewport().get_visible_rect().size.y
	var screen_scale := viewport_height / camera.size
	var sprite_size := Vector2(sprite.texture.get_width(), sprite.texture.get_height()) * sprite.pixel_size * screen_scale
	var sprite_center := camera.unproject_position(sprite.global_position)
	var sprite_rect := Rect2(sprite_center - sprite_size * 0.5, sprite_size)
	var player_screen_position := camera.unproject_position(survivor.global_position)
	if not sprite_rect.has_point(player_screen_position):
		return false
	var mask_key := sprite.texture.resource_path
	var mask: Image = occlusion_masks.get(mask_key)
	if mask == null:
		mask = sprite.texture.get_image()
		occlusion_masks[mask_key] = mask
	var uv := (player_screen_position - sprite_rect.position) / sprite_rect.size
	var pixel := Vector2i(
		clampi(floori(uv.x * mask.get_width()), 0, mask.get_width() - 1),
		clampi(floori(uv.y * mask.get_height()), 0, mask.get_height() - 1)
	)
	return mask.get_pixelv(pixel).a > 0.1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch.position.x < get_viewport().get_visible_rect().size.x * 0.55:
			touch_id = touch.index
			touch_origin = touch.position
			touch_vector = Vector2.ZERO
			touch_stick.visible = true
			touch_stick.position = touch_origin - touch_stick.size * 0.5
		elif not touch.pressed and touch.index == touch_id:
			touch_id = -1
			touch_vector = Vector2.ZERO
			touch_knob.position = (touch_stick.size - touch_knob.size) * 0.5
	elif event is InputEventScreenDrag and event.index == touch_id:
		var drag := event as InputEventScreenDrag
		var radius := touch_stick.size.x * 0.34
		var offset := (drag.position - touch_origin).limit_length(radius)
		touch_vector = offset / radius
		touch_knob.position = (touch_stick.size - touch_knob.size) * 0.5 + offset
