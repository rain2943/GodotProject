extends Node3D

const MOVE_SPEED := 2.45
const WORLD_MIN := Vector2(-3.1, -2.65)
const WORLD_MAX := Vector2(2.85, 0.55)

@onready var player: CharacterBody3D = $Player
@onready var player_sprite: Sprite3D = $Player/Survivor
@onready var touch_stick: Control = $HUD/TouchStick
@onready var touch_knob: Control = $HUD/TouchStick/Knob
@onready var location_label: Label = $HUD/TopRight/Location

var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO
var elapsed := 0.0


func _ready() -> void:
	touch_stick.visible = DisplayServer.is_touchscreen_available()


func _physics_process(delta: float) -> void:
	elapsed += delta
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		keyboard.y += 1.0

	var input_vector := keyboard.limit_length(1.0)
	if touch_vector.length_squared() > input_vector.length_squared():
		input_vector = touch_vector

	player.velocity = Vector3(input_vector.x, -input_vector.y, 0.0) * MOVE_SPEED
	player.move_and_slide()
	player.position.x = clampf(player.position.x, WORLD_MIN.x, WORLD_MAX.x)
	player.position.y = clampf(player.position.y, WORLD_MIN.y, WORLD_MAX.y)

	var depth_ratio := inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, player.position.y)
	var depth_scale := lerpf(1.0, 0.72, depth_ratio)
	var bob := sin(elapsed * (9.0 if input_vector.length() > 0.05 else 2.0)) * 0.018
	player_sprite.scale = Vector3.ONE * depth_scale
	player_sprite.position.y = bob
	if absf(input_vector.x) > 0.05:
		player_sprite.flip_h = input_vector.x < 0.0

	var district_x := roundi(remap(player.position.x, WORLD_MIN.x, WORLD_MAX.x, 118, 132))
	location_label.text = "종로구  ·  %d-7 구역" % district_x


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
