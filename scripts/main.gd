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
const ARMED_ANIMATION_SHEETS := {
	"s": preload("res://assets/characters/survivor_armed_s.png"),
	"se": preload("res://assets/characters/survivor_armed_se.png"),
	"e": preload("res://assets/characters/survivor_armed_e.png"),
	"ne": preload("res://assets/characters/survivor_armed_ne.png"),
	"n": preload("res://assets/characters/survivor_armed_n.png"),
}
const FIRE_ANIMATION_SHEETS := {
	"s": preload("res://assets/characters/survivor_fire_s.png"),
	"se": preload("res://assets/characters/survivor_fire_se.png"),
	"e": preload("res://assets/characters/survivor_fire_e.png"),
	"ne": preload("res://assets/characters/survivor_fire_ne.png"),
	"n": preload("res://assets/characters/survivor_fire_n.png"),
}
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const FRAME_SIZE := Vector2(384, 384)
const WEAPON_FRAME_SIZE := Vector2(192, 192)
const AK_DROP_TEXTURE := preload("res://assets/weapons/ak47_drop.png")
const AK_DIRECTIONAL_TEXTURE := preload("res://assets/weapons/ak47_directional.png")
const AMMO_762_TEXTURE := preload("res://assets/items/ammo_762.png")
const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const AK_PICKUP_POSITION := Vector3(1.15, 0.32, 0.7)
const PICKUP_DISTANCE := 1.75
const PICKUP_HOLD_DURATION := 0.9
const FIRE_INTERVAL := 0.12
const AMMO_PICKUP_AMOUNT := 30
const AMMO_PICKUP_POSITIONS := [
	Vector3(2, 0.3, 2),
	Vector3(15, 0.3, -4),
	Vector3(-14, 0.3, 16),
	Vector3(18, 0.3, 18),
]
const DIRECTION_VECTORS := {
	"n": Vector2(0, -1),
	"ne": Vector2(1, -1),
	"e": Vector2(1, 0),
	"se": Vector2(1, 1),
	"s": Vector2(0, 1),
	"sw": Vector2(-1, 1),
	"w": Vector2(-1, 0),
	"nw": Vector2(-1, -1),
}

@onready var player: CharacterBody3D = $Player
@onready var survivor: AnimatedSprite3D = $Player/Survivor
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var touch_stick: Control = $HUD/TouchStick
@onready var touch_knob: Control = $HUD/TouchStick/Knob
@onready var location_label: Label = $HUD/TopRight/Location
@onready var state_label: Label = $HUD/TopRight/State

var touch_id := -1
var fire_touch_id := -1
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO
var facing := "s"
var motion_state := "idle"
var occlusion_masks := {}
var weapon_sprite: AnimatedSprite3D
var ak_pickup: Node3D
var pickup_panel: PanelContainer
var pickup_progress: ProgressBar
var pickup_touch_held := false
var pickup_keyboard_held := false
var pickup_hold_time := 0.0
var equipment_panel: PanelContainer
var equipment_label: Label
var fire_button: Button
var fire_cooldown := 0.0
var fire_button_held := false
var has_ak := false
var magazine_ammo := 30
var reserve_ammo := 90
var gunshot_players: Array[AudioStreamPlayer3D] = []
var gunshot_index := 0
var building_canvas: CanvasLayer
var building_overlays := {}
var survivor_overlay: Sprite2D
var weapon_overlay: Sprite2D
var unarmed_sprite_frames: SpriteFrames
var armed_sprite_frames: SpriteFrames
var is_firing_animation := false
var ammo_pickups: Array[Node3D] = []
var ammo_notice: Label
var ammo_notice_time := 0.0


func _ready() -> void:
	camera.size = 28.0
	camera.position = Vector3(10.5, 10.5, 10.5)
	camera.look_at(Vector3.ZERO)
	$SmokeA.emitting = false
	$SmokeB.emitting = false
	survivor.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	survivor.render_priority = 127
	survivor.no_depth_test = true
	touch_stick.visible = DisplayServer.is_touchscreen_available()
	_build_sprite_frames()
	_setup_weapon_layer()
	_spawn_ak_pickup()
	_spawn_ammo_pickups()
	_build_weapon_hud()
	_build_gunshot_audio()
	_setup_building_overlays()
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
	_update_pickup(delta)
	_update_ammo_pickups(delta)
	_update_firing(delta)
	_update_camera_occluders(delta)
	camera_rig.position = camera_rig.position.lerp(Vector3(player.position.x, 0, player.position.z), 1.0 - exp(-7.0 * delta))
	_update_building_overlays()
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
	if is_firing_animation:
		return
	var source := facing
	var flipped := false
	match facing:
		"sw": source = "se"; flipped = true
		"w": source = "e"; flipped = true
		"nw": source = "ne"; flipped = true
	survivor.flip_h = flipped
	survivor.play("%s_%s" % [motion_state, source])
	if weapon_sprite and has_ak and not weapon_sprite.animation.begins_with("fire_"):
		weapon_sprite.play("idle_%s" % facing)


func _build_sprite_frames() -> void:
	unarmed_sprite_frames = _create_character_frames(ANIMATION_SHEETS, false)
	armed_sprite_frames = _create_character_frames(ARMED_ANIMATION_SHEETS, true)
	survivor.sprite_frames = unarmed_sprite_frames
	survivor.animation_finished.connect(_on_survivor_animation_finished)


func _create_character_frames(sheets: Dictionary, include_fire: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in sheets:
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 7.0 if state == "idle" else 8.5)
			var first_frame := 0 if state == "idle" else 8
			for frame_index in range(first_frame, first_frame + 8):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheets[direction_name]
				atlas.region = Rect2(
					(frame_index % 4) * FRAME_SIZE.x,
					(frame_index / 4) * FRAME_SIZE.y,
					FRAME_SIZE.x,
					FRAME_SIZE.y
				)
				var cycle_index := frame_index - first_frame
				var duration := 1.6 if state == "walk" and direction_name == "ne" and cycle_index in [2, 6] else 1.0
				frames.add_frame(animation_name, atlas, duration)
		if include_fire:
			var fire_name := "fire_%s" % direction_name
			frames.add_animation(fire_name)
			frames.set_animation_loop(fire_name, false)
			frames.set_animation_speed(fire_name, 16.0)
			for frame_index in 4:
				var fire_atlas := AtlasTexture.new()
				fire_atlas.atlas = FIRE_ANIMATION_SHEETS[direction_name]
				fire_atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
				frames.add_frame(fire_name, fire_atlas)
	return frames


func _on_survivor_animation_finished() -> void:
	if is_firing_animation:
		is_firing_animation = false
		_play_directional_animation()


func _play_survivor_fire_animation() -> void:
	var source := facing
	var flipped := false
	match facing:
		"sw": source = "se"; flipped = true
		"w": source = "e"; flipped = true
		"nw": source = "ne"; flipped = true
	is_firing_animation = true
	survivor.flip_h = flipped
	survivor.play("fire_%s" % source)


func _setup_weapon_layer() -> void:
	weapon_sprite = AnimatedSprite3D.new()
	weapon_sprite.name = "EquippedAK47"
	weapon_sprite.position = Vector3(0, 0.32, 0)
	weapon_sprite.pixel_size = 0.0072
	weapon_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	weapon_sprite.shaded = false
	weapon_sprite.transparent = true
	weapon_sprite.no_depth_test = true
	weapon_sprite.offset = Vector2(0, -28)
	weapon_sprite.visible = false
	player.add_child(weapon_sprite)

	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_index in SCREEN_DIRECTION_NAMES.size():
		var direction_name: String = SCREEN_DIRECTION_NAMES[direction_index]
		var idle_name := "idle_%s" % direction_name
		var fire_name := "fire_%s" % direction_name
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.add_frame(idle_name, _weapon_atlas_frame(direction_index, 0))
		frames.add_animation(fire_name)
		frames.set_animation_loop(fire_name, false)
		frames.set_animation_speed(fire_name, 18.0)
		frames.add_frame(fire_name, _weapon_atlas_frame(direction_index, 1), 1.0)
		frames.add_frame(fire_name, _weapon_atlas_frame(direction_index, 0), 1.0)
	weapon_sprite.sprite_frames = frames
	weapon_sprite.animation_finished.connect(_on_weapon_animation_finished)


func _weapon_atlas_frame(direction_index: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = AK_DIRECTIONAL_TEXTURE
	atlas.region = Rect2(
		direction_index * WEAPON_FRAME_SIZE.x,
		row * WEAPON_FRAME_SIZE.y,
		WEAPON_FRAME_SIZE.x,
		WEAPON_FRAME_SIZE.y
	)
	return atlas


func _on_weapon_animation_finished() -> void:
	if has_ak:
		weapon_sprite.play("idle_%s" % facing)


func _spawn_ak_pickup() -> void:
	ak_pickup = Node3D.new()
	ak_pickup.name = "AK47Pickup"
	ak_pickup.position = AK_PICKUP_POSITION
	add_child(ak_pickup)

	var sprite := Sprite3D.new()
	sprite.name = "DropSprite"
	sprite.texture = AK_DROP_TEXTURE
	sprite.pixel_size = 0.0034
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	sprite.render_priority = 90
	ak_pickup.add_child(sprite)

	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0, 0, 0, 0.32)
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.46
	shadow_mesh.bottom_radius = 0.46
	shadow_mesh.height = 0.012
	shadow_mesh.radial_segments = 20
	shadow_mesh.material = shadow_material
	var shadow := MeshInstance3D.new()
	shadow.name = "DropShadow"
	shadow.position.y = -0.29
	shadow.mesh = shadow_mesh
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ak_pickup.add_child(shadow)


func _spawn_ammo_pickups() -> void:
	for index in AMMO_PICKUP_POSITIONS.size():
		var pickup := Node3D.new()
		pickup.name = "Ammo762_%d" % index
		pickup.position = AMMO_PICKUP_POSITIONS[index]
		pickup.set_meta("base_y", pickup.position.y)
		add_child(pickup)
		var sprite := Sprite3D.new()
		sprite.texture = AMMO_762_TEXTURE
		sprite.pixel_size = 0.0032
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.transparent = true
		sprite.no_depth_test = true
		sprite.render_priority = 88
		pickup.add_child(sprite)
		ammo_pickups.append(pickup)


func _update_ammo_pickups(delta: float) -> void:
	ammo_notice_time = maxf(0.0, ammo_notice_time - delta)
	if ammo_notice and ammo_notice_time <= 0.0:
		ammo_notice.visible = false
	var player_ground := Vector2(player.position.x, player.position.z)
	for pickup in ammo_pickups.duplicate():
		if not is_instance_valid(pickup):
			ammo_pickups.erase(pickup)
			continue
		var base_y := float(pickup.get_meta("base_y", 0.3))
		pickup.position.y = base_y + sin(Time.get_ticks_msec() * 0.004 + pickup.position.x) * 0.04
		var pickup_ground := Vector2(pickup.position.x, pickup.position.z)
		if player_ground.distance_to(pickup_ground) <= 1.15:
			reserve_ammo += AMMO_PICKUP_AMOUNT
			ammo_notice.text = "+%d  7.62mm 탄약   잔탄 %d" % [AMMO_PICKUP_AMOUNT, reserve_ammo]
			ammo_notice.visible = true
			ammo_notice_time = 2.2
			_update_equipment_ui()
			ammo_pickups.erase(pickup)
			pickup.queue_free()


func _build_weapon_hud() -> void:
	var font := load("res://assets/fonts/Pretendard-Regular.otf") as Font
	pickup_panel = PanelContainer.new()
	pickup_panel.name = "PickupPrompt"
	pickup_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	pickup_panel.offset_left = -170
	pickup_panel.offset_top = -116
	pickup_panel.offset_right = 170
	pickup_panel.offset_bottom = -48
	pickup_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.025, 0.028, 0.94), Color("#d5b45b")))
	pickup_panel.visible = false
	$HUD.add_child(pickup_panel)

	var pickup_box := VBoxContainer.new()
	pickup_box.add_theme_constant_override("separation", 5)
	pickup_panel.add_child(pickup_box)
	var pickup_button := Button.new()
	pickup_button.custom_minimum_size = Vector2(330, 40)
	pickup_button.text = "AK-47  길게 눌러 줍기  [E]"
	pickup_button.add_theme_font_override("font", font)
	pickup_button.add_theme_font_size_override("font_size", 15)
	pickup_button.button_down.connect(func() -> void: pickup_touch_held = true)
	pickup_button.button_up.connect(func() -> void: pickup_touch_held = false)
	pickup_box.add_child(pickup_button)
	pickup_progress = ProgressBar.new()
	pickup_progress.custom_minimum_size = Vector2(330, 8)
	pickup_progress.max_value = PICKUP_HOLD_DURATION
	pickup_progress.show_percentage = false
	pickup_box.add_child(pickup_progress)

	equipment_panel = PanelContainer.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	equipment_panel.offset_left = -244
	equipment_panel.offset_top = -176
	equipment_panel.offset_right = -22
	equipment_panel.offset_bottom = -116
	equipment_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.025, 0.028, 0.94), Color("#83a68f")))
	equipment_panel.visible = false
	$HUD.add_child(equipment_panel)
	equipment_label = Label.new()
	equipment_label.custom_minimum_size = Vector2(220, 58)
	equipment_label.text = "AK-47\n30 / 90"
	equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equipment_label.add_theme_font_override("font", font)
	equipment_label.add_theme_font_size_override("font_size", 16)
	equipment_panel.add_child(equipment_label)

	fire_button = Button.new()
	fire_button.name = "FireButton"
	fire_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire_button.offset_left = -108
	fire_button.offset_top = -104
	fire_button.offset_right = -28
	fire_button.offset_bottom = -24
	fire_button.text = "발사"
	fire_button.tooltip_text = "AK-47 발사"
	fire_button.focus_mode = Control.FOCUS_NONE
	fire_button.add_theme_font_override("font", font)
	fire_button.add_theme_font_size_override("font_size", 17)
	fire_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.16, 0.055, 0.04, 0.92), Color("#d98155"), 40))
	fire_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.24, 0.075, 0.045, 0.94), Color("#e99a67"), 40))
	fire_button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.42, 0.12, 0.055, 0.96), Color("#ffc078"), 40))
	fire_button.button_down.connect(_on_fire_button_down)
	fire_button.button_up.connect(_on_fire_button_up)
	fire_button.visible = false
	$HUD.add_child(fire_button)

	ammo_notice = Label.new()
	ammo_notice.name = "AmmoNotice"
	ammo_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ammo_notice.offset_left = -170
	ammo_notice.offset_top = -170
	ammo_notice.offset_right = 170
	ammo_notice.offset_bottom = -132
	ammo_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_notice.add_theme_font_override("font", font)
	ammo_notice.add_theme_font_size_override("font_size", 16)
	ammo_notice.add_theme_color_override("font_color", Color("#f2d27a"))
	ammo_notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	ammo_notice.add_theme_constant_override("outline_size", 5)
	ammo_notice.visible = false
	$HUD.add_child(ammo_notice)


func _make_panel_style(background: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _update_pickup(delta: float) -> void:
	if has_ak or not is_instance_valid(ak_pickup):
		return
	ak_pickup.position.y = AK_PICKUP_POSITION.y + sin(Time.get_ticks_msec() * 0.004) * 0.045
	var player_ground := Vector2(player.position.x, player.position.z)
	var pickup_ground := Vector2(ak_pickup.position.x, ak_pickup.position.z)
	var is_near := player_ground.distance_to(pickup_ground) <= PICKUP_DISTANCE
	pickup_panel.visible = is_near
	var holding := pickup_touch_held or pickup_keyboard_held
	if is_near and holding:
		pickup_hold_time = minf(pickup_hold_time + delta, PICKUP_HOLD_DURATION)
		if pickup_hold_time >= PICKUP_HOLD_DURATION:
			_equip_ak47()
	else:
		pickup_hold_time = 0.0
	pickup_progress.value = pickup_hold_time


func _equip_ak47() -> void:
	has_ak = true
	pickup_touch_held = false
	pickup_panel.visible = false
	if is_instance_valid(ak_pickup):
		ak_pickup.queue_free()
	weapon_sprite.visible = false
	survivor.sprite_frames = armed_sprite_frames
	is_firing_animation = false
	_play_directional_animation()
	equipment_panel.visible = true
	fire_button.visible = true
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "AK-47\n30"
	_update_equipment_ui()


func _update_firing(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if fire_button_held and has_ak and fire_cooldown <= 0.0:
		_fire_ak47()


func _on_fire_button_down() -> void:
	fire_button_held = true
	_try_fire_ak47()


func _on_fire_button_up() -> void:
	fire_button_held = false


func _try_fire_ak47() -> void:
	if has_ak and fire_cooldown <= 0.0:
		_fire_ak47()


func _fire_ak47() -> void:
	if magazine_ammo <= 0:
		_reload_ak47()
		return
	magazine_ammo -= 1
	fire_cooldown = FIRE_INTERVAL
	_play_survivor_fire_animation()
	var screen_direction: Vector2 = DIRECTION_VECTORS[facing]
	var world_direction := Vector3(
		screen_direction.x + screen_direction.y,
		0,
		-screen_direction.x + screen_direction.y
	).normalized()
	var projectile := Area3D.new()
	projectile.name = "AK47Bullet"
	projectile.set_script(BULLET_PROJECTILE)
	projectile.set("direction", world_direction)
	projectile.set("source_body", player)
	projectile.position = player.position + world_direction * 0.82 + Vector3(0, 0.05, 0)
	add_child(projectile)
	_play_gunshot()
	_spawn_muzzle_light(world_direction)
	_spawn_launch_fx(world_direction)
	_update_equipment_ui()


func _reload_ak47() -> void:
	if reserve_ammo <= 0:
		fire_cooldown = 0.35
		return
	var loaded := mini(30, reserve_ammo)
	magazine_ammo = loaded
	reserve_ammo -= loaded
	fire_cooldown = 0.85
	ammo_notice.text = "AK-47 재장전   %d / %d" % [magazine_ammo, reserve_ammo]
	ammo_notice.visible = true
	ammo_notice_time = 1.4
	_update_equipment_ui()


func _update_equipment_ui() -> void:
	equipment_label.text = "AK-47  장착\n%02d / %02d" % [magazine_ammo, reserve_ammo]
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "AK-47\n%d" % magazine_ammo


func _spawn_muzzle_light(direction: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color("#ffb347")
	flash.light_energy = 3.0
	flash.omni_range = 2.2
	flash.position = player.position + direction * 0.8 + Vector3(0, 0.2, 0)
	add_child(flash)
	get_tree().create_timer(0.045).timeout.connect(flash.queue_free)


func _spawn_launch_fx(direction: Vector3) -> void:
	var origin := player.position + direction * 0.86 + Vector3(0, 0.18, 0)
	_spawn_particle_burst(origin, direction, Color("#ffd36a"), 14, 0.16, 2.8, 6.0, 0.08, 0.24)
	_spawn_particle_burst(origin, direction + Vector3.UP * 0.25, Color(0.42, 0.44, 0.46, 0.58), 7, 0.42, 0.35, 1.2, 0.18, 0.52)


func _spawn_particle_burst(
	position: Vector3,
	direction: Vector3,
	color: Color,
	amount: int,
	lifetime: float,
	velocity_min: float,
	velocity_max: float,
	scale_min: float,
	scale_max: float
) -> void:
	var particles := GPUParticles3D.new()
	particles.position = position
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var process := ParticleProcessMaterial.new()
	process.direction = direction.normalized()
	process.spread = 24.0
	process.gravity = Vector3(0, 0.5, 0)
	process.initial_velocity_min = velocity_min
	process.initial_velocity_max = velocity_max
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.color = color
	particles.process_material = process
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 2.4
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.16, 0.16)
	mesh.material = material
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func _build_gunshot_audio() -> void:
	var stream := _create_gunshot_stream()
	for index in 4:
		var audio := AudioStreamPlayer3D.new()
		audio.name = "Gunshot%d" % index
		audio.stream = stream
		audio.unit_size = 7.0
		audio.max_distance = 42.0
		audio.volume_db = -3.0
		player.add_child(audio)
		gunshot_players.append(audio)


func _create_gunshot_stream() -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(mix_rate * 0.16)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 47047
	for index in sample_count:
		var time := float(index) / mix_rate
		var envelope := exp(-time * 27.0)
		var crack := random.randf_range(-1.0, 1.0) * envelope
		var body := sin(TAU * 118.0 * time) * exp(-time * 18.0)
		var sample := clampf(crack * 0.72 + body * 0.42, -1.0, 1.0)
		var encoded := int(sample * 32767.0)
		data[index * 2] = encoded & 0xff
		data[index * 2 + 1] = (encoded >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_gunshot() -> void:
	if gunshot_players.is_empty():
		return
	var audio := gunshot_players[gunshot_index]
	gunshot_index = (gunshot_index + 1) % gunshot_players.size()
	audio.play()


func _setup_building_overlays() -> void:
	building_canvas = CanvasLayer.new()
	building_canvas.name = "BuildingOverlay"
	building_canvas.layer = 0
	add_child(building_canvas)
	for node in get_tree().get_nodes_in_group("camera_occluder"):
		var building := node as Node3D
		var source := building.get_node_or_null("BuildingSprite") as Sprite3D
		if source == null or source.texture == null:
			continue
		var overlay := Sprite2D.new()
		overlay.name = "%sOverlay" % building.name
		overlay.texture = source.texture
		overlay.centered = true
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		overlay.z_index = roundi((building.global_position.x + building.global_position.z) * 10.0)
		building_canvas.add_child(overlay)
		building_overlays[building] = overlay
		source.visible = false
	survivor_overlay = Sprite2D.new()
	survivor_overlay.name = "SurvivorOverlay"
	survivor_overlay.centered = true
	survivor_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	building_canvas.add_child(survivor_overlay)
	weapon_overlay = Sprite2D.new()
	weapon_overlay.name = "WeaponOverlay"
	weapon_overlay.centered = true
	weapon_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	building_canvas.add_child(weapon_overlay)
	survivor.visible = false
	weapon_sprite.visible = false
	_update_building_overlays()


func _update_building_overlays() -> void:
	if building_canvas == null:
		return
	var viewport_height := get_viewport().get_visible_rect().size.y
	var screen_scale := viewport_height / camera.size
	for building in building_overlays:
		if not is_instance_valid(building):
			continue
		var source := building.get_node_or_null("BuildingSprite") as Sprite3D
		var overlay := building_overlays[building] as Sprite2D
		if source == null or overlay == null:
			continue
		overlay.position = camera.unproject_position(source.global_position)
		overlay.scale = Vector2.ONE * source.pixel_size * screen_scale
		overlay.offset = source.offset
		overlay.modulate = source.modulate
	var player_depth := roundi((player.global_position.x + player.global_position.z) * 10.0)
	var survivor_texture := survivor.sprite_frames.get_frame_texture(survivor.animation, survivor.frame)
	if survivor_texture:
		survivor_overlay.texture = survivor_texture
	survivor_overlay.position = camera.unproject_position(survivor.global_position)
	survivor_overlay.scale = Vector2.ONE * survivor.pixel_size * screen_scale
	survivor_overlay.flip_h = survivor.flip_h
	survivor_overlay.modulate = survivor.modulate
	survivor_overlay.z_index = player_depth
	weapon_overlay.visible = false


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
			var target_alpha := 0.52 if is_occluding else 1.0
			color.a = move_toward(color.a, target_alpha, delta * 5.5)
			sprite.modulate = color
	var target_player_color := SILHOUETTE_COLOR if player_is_occluded else Color.WHITE
	survivor.modulate = survivor.modulate.lerp(target_player_color, 1.0 - exp(-10.0 * delta))
	if weapon_sprite:
		weapon_sprite.modulate = weapon_sprite.modulate.lerp(target_player_color, 1.0 - exp(-10.0 * delta))


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
	if event is InputEventKey and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
		if key == KEY_E:
			pickup_keyboard_held = key_event.pressed
		elif key == KEY_SPACE and key_event.pressed:
			_try_fire_ak47()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if has_ak and fire_button.visible and fire_button.get_global_rect().has_point(touch.position):
				fire_touch_id = touch.index
				fire_button_held = true
				_try_fire_ak47()
			elif touch_id == -1 and touch.position.x < get_viewport().get_visible_rect().size.x * 0.55:
				touch_id = touch.index
				touch_origin = touch.position
				touch_vector = Vector2.ZERO
				touch_stick.visible = true
				touch_stick.position = touch_origin - touch_stick.size * 0.5
		else:
			if touch.index == fire_touch_id:
				fire_touch_id = -1
				fire_button_held = false
			if touch.index == touch_id:
				touch_id = -1
				touch_vector = Vector2.ZERO
				touch_knob.position = (touch_stick.size - touch_knob.size) * 0.5
	elif event is InputEventScreenDrag and event.index == touch_id:
		var drag := event as InputEventScreenDrag
		var radius := touch_stick.size.x * 0.34
		var offset := (drag.position - touch_origin).limit_length(radius)
		touch_vector = offset / radius
		touch_knob.position = (touch_stick.size - touch_knob.size) * 0.5 + offset
