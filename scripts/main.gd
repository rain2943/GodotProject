extends Node3D

const MOVE_SPEED := 5.2
const CAMERA_DIAGONAL_OFFSET := 13.5
const OCCLUSION_LATERAL_LIMIT := 5.1
const OCCLUSION_DEPTH_LIMIT := 14.0
const SILHOUETTE_COLOR := Color("#26343b")
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const CAT_ANIMATION_ROOT := "res://assets/characters/cat_8way"
const CAT_DIRECTION_STATES := {
	"n": "up",
	"ne": "up_right",
	"e": "right",
	"se": "down_right",
	"s": "down",
	"sw": "down_left",
	"w": "left",
	"nw": "up_left",
}
const CAT_FRAME_COUNT := 4
const WEAPON_FRAME_SIZE := Vector2(192, 192)
const AK_DROP_TEXTURE := preload("res://assets/weapons/ak47_drop.png")
const AK_DIRECTIONAL_TEXTURE := preload("res://assets/weapons/ak47_directional.png")
const AMMO_762_TEXTURE := preload("res://assets/items/ammo_762.png")
const BASEBALL_BAT_TEXTURE := preload("res://assets/weapons/baseball_bat_temp.png")
const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const INVENTORY_UI_SCRIPT := preload("res://scripts/inventory_ui.gd")
const PERCEPTION_SYSTEM_SCRIPT := preload("res://scripts/perception_system.gd")
const OVERLAY_DEPTH_SORT := preload("res://scripts/overlay_depth_sort.gd")
const ENEMY_MELEE_SHEETS := {
	"s": preload("res://assets/enemies/enemy_melee_anim_s.png"),
	"se": preload("res://assets/enemies/enemy_melee_anim_se.png"),
	"e": preload("res://assets/enemies/enemy_melee_anim_e.png"),
	"ne": preload("res://assets/enemies/enemy_melee_anim_ne.png"),
	"n": preload("res://assets/enemies/enemy_melee_anim_n.png"),
}
const ENEMY_PISTOL_SHEETS := {
	"s": preload("res://assets/enemies/enemy_pistol_anim_s.png"),
	"se": preload("res://assets/enemies/enemy_pistol_anim_se.png"),
	"e": preload("res://assets/enemies/enemy_pistol_anim_e.png"),
	"ne": preload("res://assets/enemies/enemy_pistol_anim_ne.png"),
	"n": preload("res://assets/enemies/enemy_pistol_anim_n.png"),
}
const AK_PICKUP_POSITION := Vector3(1.15, 0.32, 0.7)
const PICKUP_DISTANCE := 1.75
const PICKUP_HOLD_DURATION := 0.9
const FIRE_INTERVAL := 0.12
const AIM_HOLD_DURATION := 0.55
const AMMO_PICKUP_AMOUNT := 30
const MAP_CONTENT_SCALE := ProceduralCityMap.WORLD_SCALE
const SECONDS_PER_GAME_HOUR := 36.0
const NIGHT_START_HOUR := 19.0
const DEEP_NIGHT_HOUR := 22.0
const BASE_ENEMY_COUNT := 6
const MAX_NIGHT_ENEMY_COUNT := 16
const MELEE_ATTACK_COOLDOWN := 0.72
const MELEE_ATTACK_RANGE := 2.2
const MELEE_ATTACK_DAMAGE := 38
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
@onready var time_label: Label = $HUD/TopRight/Time
@onready var sun: DirectionalLight3D = $Sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment

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
var mouse_fire_held := false
var has_ak := false
var magazine_ammo := 30
var reserve_ammo := 90
var gunshot_players: Array[AudioStreamPlayer3D] = []
var gunshot_index := 0
var building_canvas: CanvasLayer
var building_overlays := {}
var vehicle_overlays := {}
var survivor_overlay: Sprite2D
var weapon_overlay: Sprite2D
var unarmed_sprite_frames: SpriteFrames
var ammo_pickups: Array[Node3D] = []
var ammo_notice: Label
var ammo_notice_time := 0.0
var ammo_pickup_chain_total := 0
var ammo_pickup_chain_time := 0.0
var ammo_prompt_panel: PanelContainer
var nearby_ammo_pickup: Node3D
var inventory_ui: Control
var visibility_material: ShaderMaterial
var perception_system: CanvasLayer
var aim_hold_time := 0.0
var locked_aim_direction := Vector3.ZERO
var smoke_particle_texture: ImageTexture
var loot_glow_texture: ImageTexture
var player_health := 82
var enemies: Array[CharacterBody3D] = []
var world_time_hours := 9.0
var night_intensity := 0.0
var enemy_spawn_serial := 0
var reinforcement_timer := 8.0
var day_night_tint: ColorRect
var current_day_phase := ""
var spawn_random := RandomNumberGenerator.new()
var melee_bat_sprite: Sprite3D
var melee_attack_cooldown := 0.0
var melee_arc_texture: ImageTexture


func _ready() -> void:
	world_time_hours = GameState.world_time_hours
	night_intensity = _get_night_intensity(world_time_hours)
	spawn_random.seed = GameState.map_seed + 9137
	player_health = GameState.player_health
	magazine_ammo = GameState.magazine_ammo
	reserve_ammo = GameState.reserve_ammo
	var restore_weapon := GameState.has_ak
	has_ak = false
	camera.size = 28.0
	player.collision_mask = 3
	camera.position = Vector3.ONE * CAMERA_DIAGONAL_OFFSET
	camera.look_at(Vector3.ZERO)
	$SmokeA.emitting = false
	$SmokeB.emitting = false
	survivor.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	survivor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	survivor.render_priority = 127
	survivor.no_depth_test = true
	touch_stick.visible = DisplayServer.is_touchscreen_available()
	_build_sprite_frames()
	_setup_weapon_layer()
	_setup_melee_weapon()
	_spawn_ak_pickup()
	_spawn_ammo_pickups()
	_build_weapon_hud()
	_build_gunshot_audio()
	_spawn_enemies()
	_setup_building_overlays()
	_build_day_night_tint()
	_build_visibility_fog()
	_install_perception_system()
	_update_day_night(0.0)
	_set_facing("s")
	var world := $World as ProceduralCityMap
	world.shelter_portal_entered.connect(_on_shelter_portal_entered)
	if GameState.returning_from_shelter:
		player.position = world.get_shelter_exit_position()
		GameState.returning_from_shelter = false
	else:
		player.position = world.find_nearest_open_position(player.position)
	var health_bar := get_node_or_null("HUD/TopLeft/Margin/VBox/Health") as ProgressBar
	if health_bar:
		health_bar.value = player_health
	if restore_weapon:
		_equip_ak47()


func _physics_process(delta: float) -> void:
	_update_day_night(delta)
	_update_enemy_pressure(delta)
	melee_attack_cooldown = maxf(0.0, melee_attack_cooldown - delta)
	aim_hold_time = maxf(0.0, aim_hold_time - delta)
	var aim_is_locked := has_ak and (fire_button_held or mouse_fire_held or aim_hold_time > 0.0)
	if _is_inventory_open():
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		return
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
		if not aim_is_locked:
			_update_facing(input_vector)
		_set_motion_state("walk")
		state_label.text = "이동 중"
	else:
		player.velocity = Vector3.ZERO
		_set_motion_state("idle")
		state_label.text = "경계 중"

	if aim_is_locked and locked_aim_direction.length_squared() > 0.01:
		_set_facing_from_world_direction(locked_aim_direction)
	_update_weapon_pose()

	player.move_and_slide()
	var map_limit := ($World as ProceduralCityMap).get_map_limit()
	player.position.x = clampf(player.position.x, -map_limit, map_limit)
	player.position.z = clampf(player.position.z, -map_limit, map_limit)
	_update_pickup(delta)
	_update_ammo_pickups(delta)
	_update_firing(delta)
	_update_camera_occluders(delta)
	camera_rig.position = camera_rig.position.lerp(Vector3(player.position.x, 0, player.position.z), 1.0 - exp(-7.0 * delta))
	_update_building_overlays()
	_update_visibility_fog()
	if perception_system:
		perception_system.call("set_aim_direction", _get_perception_aim_direction())
	$CameraRig/Rain.position.y = 8.0
	location_label.text = "종로 생존구역  ·  %02d / %02d" % [roundi(player.position.x + 32), roundi(player.position.z + 32)]


func _update_facing(screen_direction: Vector2) -> void:
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % 8
	_set_facing(SCREEN_DIRECTION_NAMES[index])


func _set_facing_from_world_direction(world_direction: Vector3) -> void:
	if world_direction.length_squared() <= 0.01:
		return
	var screen_direction := Vector2(
		world_direction.x - world_direction.z,
		world_direction.x + world_direction.z
	).normalized()
	_update_facing(screen_direction)


func _uses_mouse_aim() -> bool:
	return not DisplayServer.is_touchscreen_available()


func _lock_aim_direction(world_direction: Vector3) -> void:
	world_direction.y = 0.0
	if world_direction.length_squared() <= 0.01:
		return
	locked_aim_direction = world_direction.normalized()
	aim_hold_time = AIM_HOLD_DURATION


func _get_perception_aim_direction() -> Vector3:
	if has_ak and (fire_button_held or mouse_fire_held or aim_hold_time > 0.0) and locked_aim_direction.length_squared() > 0.01:
		return locked_aim_direction
	return _get_current_facing_world_direction()


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
	# The cat owns all eight views; never mirror one direction into another.
	survivor.flip_h = false
	survivor.play("%s_%s" % [motion_state, facing])
	if weapon_sprite and has_ak and not weapon_sprite.animation.begins_with("fire_"):
		weapon_sprite.play("idle_%s" % facing)
	_update_weapon_pose()


func _build_sprite_frames() -> void:
	unarmed_sprite_frames = _create_cat_frames()
	survivor.sprite_frames = unarmed_sprite_frames


func _create_cat_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in SCREEN_DIRECTION_NAMES:
		var state_prefix: String = CAT_DIRECTION_STATES[direction_name]
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 4.0 if state == "idle" else 8.0)
			for frame_index in CAT_FRAME_COUNT:
				var texture_path := "%s/%s_%s_%d.png" % [
					CAT_ANIMATION_ROOT, state_prefix, state, frame_index
				]
				var texture := load(texture_path) as Texture2D
				if texture == null:
					push_error("Missing cat animation frame: %s" % texture_path)
					continue
				frames.add_frame(animation_name, texture)
	return frames


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


func _setup_melee_weapon() -> void:
	melee_bat_sprite = Sprite3D.new()
	melee_bat_sprite.name = "TemporaryBaseballBat"
	melee_bat_sprite.texture = BASEBALL_BAT_TEXTURE
	melee_bat_sprite.pixel_size = 0.00125
	melee_bat_sprite.offset = Vector2(480, -480)
	melee_bat_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	melee_bat_sprite.shaded = false
	melee_bat_sprite.transparent = true
	melee_bat_sprite.no_depth_test = true
	melee_bat_sprite.render_priority = 126
	melee_bat_sprite.visible = false
	player.add_child(melee_bat_sprite)


func _try_melee_attack() -> void:
	if melee_attack_cooldown > 0.0 or player_health <= 0:
		return
	melee_attack_cooldown = MELEE_ATTACK_COOLDOWN
	var attack_direction := _get_mouse_world_direction() if _uses_mouse_aim() else _get_current_facing_world_direction()
	_lock_aim_direction(attack_direction)
	_set_facing_from_world_direction(attack_direction)
	_play_bat_swing(attack_direction)
	_spawn_player_melee_arc(attack_direction)
	get_tree().create_timer(0.09).timeout.connect(func() -> void:
		if is_inside_tree():
			_resolve_melee_hit(attack_direction)
	)


func _play_bat_swing(direction: Vector3) -> void:
	var player_screen := camera.unproject_position(player.global_position)
	var target_screen := camera.unproject_position(player.global_position + direction * 2.0)
	var screen_direction := (target_screen - player_screen).normalized()
	var screen_angle := atan2(screen_direction.y, screen_direction.x)
	var aligned_angle := screen_angle + PI * 0.25
	melee_bat_sprite.visible = true
	melee_bat_sprite.modulate = Color.WHITE
	melee_bat_sprite.position = direction * 0.2 + Vector3(0, 0.35, 0)
	melee_bat_sprite.rotation.z = aligned_angle - deg_to_rad(105.0)
	melee_bat_sprite.scale = Vector3.ONE * 0.78
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(melee_bat_sprite, "rotation:z", aligned_angle + deg_to_rad(48.0), 0.19).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(melee_bat_sprite, "position", direction * 0.42 + Vector3(0, 0.38, 0), 0.19)
	tween.tween_property(melee_bat_sprite, "scale", Vector3.ONE * 0.9, 0.19)
	tween.chain().tween_property(melee_bat_sprite, "modulate", Color(1, 1, 1, 0), 0.11)
	tween.chain().tween_callback(func() -> void:
		melee_bat_sprite.visible = false
	)


func _resolve_melee_hit(direction: Vector3) -> void:
	var closest_enemy: CharacterBody3D
	var closest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or bool(enemy.get("dying")):
			continue
		var offset := enemy.global_position - player.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= 0.05 or distance > MELEE_ATTACK_RANGE:
			continue
		if direction.dot(offset.normalized()) < cos(deg_to_rad(56.0)):
			continue
		var query := PhysicsRayQueryParameters3D.create(
			player.global_position + Vector3(0, 0.35, 0),
			enemy.global_position + Vector3(0, 0.35, 0),
			3
		)
		query.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.get("collider") != enemy:
			continue
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	if closest_enemy == null:
		return
	var backstab := bool(closest_enemy.call("is_backstab_from", player.global_position))
	closest_enemy.call("take_melee_hit", MELEE_ATTACK_DAMAGE, direction, backstab)


func _spawn_player_melee_arc(direction: Vector3) -> void:
	if melee_arc_texture == null:
		melee_arc_texture = _create_melee_arc_texture()
	var arc := Sprite3D.new()
	arc.name = "PlayerMeleeArc"
	arc.texture = melee_arc_texture
	arc.pixel_size = 0.012
	arc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arc.shaded = false
	arc.transparent = true
	arc.no_depth_test = true
	arc.render_priority = 125
	arc.position = player.position + direction * 0.95 + Vector3(0, 0.3, 0)
	add_child(arc)
	var player_screen := camera.unproject_position(player.global_position)
	var target_screen := camera.unproject_position(player.global_position + direction * 2.0)
	var screen_direction := (target_screen - player_screen).normalized()
	arc.rotation.z = atan2(screen_direction.y, screen_direction.x)
	arc.scale = Vector3.ONE * 0.72
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(arc, "scale", Vector3.ONE * 1.28, 0.18)
	tween.tween_property(arc, "modulate", Color(1.0, 0.52, 0.2, 0.0), 0.2)
	get_tree().create_timer(0.22).timeout.connect(arc.queue_free)


func _create_melee_arc_texture() -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(64, 64)
	for y in 128:
		for x in 128:
			var offset := Vector2(x, y) - center
			var radius := offset.length()
			var angle := rad_to_deg(atan2(offset.y, offset.x))
			if radius >= 40.0 and radius <= 57.0 and absf(angle) <= 68.0:
				var edge_alpha := 1.0 - absf(radius - 48.5) / 8.5
				image.set_pixel(x, y, Color(1.0, 0.7, 0.32, edge_alpha * 0.72))
	return ImageTexture.create_from_image(image)


func _spawn_ak_pickup() -> void:
	ak_pickup = Node3D.new()
	ak_pickup.name = "AK47Pickup"
	ak_pickup.position = _safe_map_position(_scale_map_position(AK_PICKUP_POSITION))
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
	_add_loot_highlight(ak_pickup, Color("#dfb94f"), 1.05)


func _spawn_ammo_pickups() -> void:
	for index in AMMO_PICKUP_POSITIONS.size():
		var pickup := Node3D.new()
		pickup.name = "Ammo762_%d" % index
		pickup.position = _safe_map_position(_scale_map_position(AMMO_PICKUP_POSITIONS[index]))
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
		_add_loot_highlight(pickup, Color("#f2d27a"), 0.88)
		ammo_pickups.append(pickup)


func _update_ammo_pickups(delta: float) -> void:
	ammo_notice_time = maxf(0.0, ammo_notice_time - delta)
	ammo_pickup_chain_time = maxf(0.0, ammo_pickup_chain_time - delta)
	if ammo_pickup_chain_time <= 0.0:
		ammo_pickup_chain_total = 0
	if ammo_notice and ammo_notice_time <= 0.0:
		ammo_notice.visible = false
	var player_ground := Vector2(player.position.x, player.position.z)
	var nearest_distance := INF
	nearby_ammo_pickup = null
	for pickup in ammo_pickups.duplicate():
		if not is_instance_valid(pickup):
			ammo_pickups.erase(pickup)
			continue
		var base_y := float(pickup.get_meta("base_y", 0.3))
		pickup.position.y = base_y + sin(Time.get_ticks_msec() * 0.004 + pickup.position.x) * 0.04
		var pickup_ground := Vector2(pickup.position.x, pickup.position.z)
		var distance := player_ground.distance_to(pickup_ground)
		_update_loot_highlight(pickup, distance, delta)
		if distance <= PICKUP_DISTANCE and distance < nearest_distance:
			nearest_distance = distance
			nearby_ammo_pickup = pickup
	if ammo_prompt_panel:
		ammo_prompt_panel.visible = is_instance_valid(nearby_ammo_pickup)


func _collect_nearby_ammo() -> void:
	if not is_instance_valid(nearby_ammo_pickup):
		return
	reserve_ammo += AMMO_PICKUP_AMOUNT
	GameState.reserve_ammo = reserve_ammo
	if ammo_pickup_chain_time <= 0.0:
		ammo_pickup_chain_total = 0
	ammo_pickup_chain_total += AMMO_PICKUP_AMOUNT
	ammo_pickup_chain_time = 2.4
	var total_ammo := magazine_ammo + reserve_ammo
	ammo_notice.text = "+%d  7.62mm   연속 획득 +%d\n탄창 %d / 30   예비 %d   총 %d" % [
		AMMO_PICKUP_AMOUNT,
		ammo_pickup_chain_total,
		magazine_ammo,
		reserve_ammo,
		total_ammo,
	]
	ammo_notice.visible = true
	ammo_notice_time = 2.2
	_update_equipment_ui()
	ammo_pickups.erase(nearby_ammo_pickup)
	nearby_ammo_pickup.queue_free()
	nearby_ammo_pickup = null
	ammo_prompt_panel.visible = false


func _add_loot_highlight(pickup: Node3D, color: Color, radius: float) -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.34)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.6

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = radius * 0.88
	ring_mesh.outer_radius = radius
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	ring_mesh.material = material
	var ring := MeshInstance3D.new()
	ring.name = "LootRing"
	ring.position.y = -0.26
	ring.mesh = ring_mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pickup.add_child(ring)

	var marker := Sprite3D.new()
	marker.name = "LootMarker"
	marker.texture = _get_loot_glow_texture()
	marker.position.y = 1.1
	marker.pixel_size = 0.006
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.shaded = false
	marker.transparent = true
	marker.no_depth_test = true
	marker.render_priority = 120
	marker.modulate = color
	pickup.add_child(marker)


func _update_loot_highlight(pickup: Node3D, distance: float, _delta: float) -> void:
	var ring := pickup.get_node_or_null("LootRing") as MeshInstance3D
	var marker := pickup.get_node_or_null("LootMarker") as Sprite3D
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006 + pickup.position.x)
	var near_boost := 1.0 if distance > PICKUP_DISTANCE else 1.28
	if ring:
		var scale_value := near_boost * (1.0 + pulse * 0.16)
		ring.scale = Vector3(scale_value, scale_value, scale_value)
	if marker:
		marker.position.y = 1.05 + pulse * 0.18
		var color := marker.modulate
		color.a = 0.58 + pulse * 0.36
		marker.modulate = color


func _get_loot_glow_texture() -> ImageTexture:
	if loot_glow_texture != null:
		return loot_glow_texture
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		for x in 96:
			var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / 96.0
			var center_distance := uv.distance_to(Vector2(0.5, 0.5))
			var diamond := absf(uv.x - 0.5) + absf(uv.y - 0.5)
			var alpha := maxf(0.0, 1.0 - diamond * 2.1)
			alpha = maxf(alpha, maxf(0.0, 1.0 - center_distance * 2.6) * 0.55)
			image.set_pixel(x, y, Color(1, 1, 1, alpha * alpha))
	loot_glow_texture = ImageTexture.create_from_image(image)
	return loot_glow_texture


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

	ammo_prompt_panel = PanelContainer.new()
	ammo_prompt_panel.name = "AmmoPickupPrompt"
	ammo_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ammo_prompt_panel.offset_left = -170
	ammo_prompt_panel.offset_top = -112
	ammo_prompt_panel.offset_right = 170
	ammo_prompt_panel.offset_bottom = -58
	ammo_prompt_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.025, 0.028, 0.94), Color("#b8a66d")))
	ammo_prompt_panel.visible = false
	$HUD.add_child(ammo_prompt_panel)
	var ammo_pickup_button := Button.new()
	ammo_pickup_button.custom_minimum_size = Vector2(330, 48)
	ammo_pickup_button.text = "7.62mm 탄약 획득  [E]"
	ammo_pickup_button.focus_mode = Control.FOCUS_NONE
	ammo_pickup_button.add_theme_font_override("font", font)
	ammo_pickup_button.add_theme_font_size_override("font_size", 15)
	ammo_pickup_button.pressed.connect(_collect_nearby_ammo)
	ammo_prompt_panel.add_child(ammo_pickup_button)

	equipment_panel = PanelContainer.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	equipment_panel.offset_left = -244
	equipment_panel.offset_top = -194
	equipment_panel.offset_right = -22
	equipment_panel.offset_bottom = -112
	equipment_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.025, 0.028, 0.94), Color("#83a68f")))
	equipment_panel.visible = false
	$HUD.add_child(equipment_panel)
	equipment_label = Label.new()
	equipment_label.custom_minimum_size = Vector2(220, 78)
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
	ammo_notice.offset_top = -196
	ammo_notice.offset_right = 170
	ammo_notice.offset_bottom = -138
	ammo_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_notice.add_theme_font_override("font", font)
	ammo_notice.add_theme_font_size_override("font_size", 16)
	ammo_notice.add_theme_color_override("font_color", Color("#f2d27a"))
	ammo_notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	ammo_notice.add_theme_constant_override("outline_size", 5)
	ammo_notice.visible = false
	$HUD.add_child(ammo_notice)

	inventory_ui = INVENTORY_UI_SCRIPT.new()
	inventory_ui.name = "InventoryUI"
	$HUD.add_child(inventory_ui)
	inventory_ui.call("setup", font, AK_DROP_TEXTURE, AMMO_762_TEXTURE)
	inventory_ui.connect("open_state_changed", _on_inventory_open_state_changed)
	_update_equipment_ui()


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
	var distance := player_ground.distance_to(pickup_ground)
	_update_loot_highlight(ak_pickup, distance, delta)
	var is_near := distance <= PICKUP_DISTANCE
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
	GameState.has_ak = true
	pickup_touch_held = false
	pickup_panel.visible = false
	if is_instance_valid(ak_pickup):
		ak_pickup.queue_free()
	weapon_sprite.visible = true
	survivor.sprite_frames = unarmed_sprite_frames
	_play_directional_animation()
	_update_weapon_pose()
	equipment_panel.visible = true
	fire_button.visible = true
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "AK-47\n30"
	_update_equipment_ui()


func _update_firing(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	var firing_held := fire_button_held or mouse_fire_held
	if firing_held and has_ak and fire_cooldown <= 0.0:
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
	GameState.magazine_ammo = magazine_ammo
	fire_cooldown = FIRE_INTERVAL
	var world_direction := _get_current_fire_direction()
	_lock_aim_direction(world_direction)
	_set_facing_from_world_direction(world_direction)
	_update_weapon_pose()
	if weapon_sprite:
		weapon_sprite.play("fire_%s" % facing)
	var projectile := Area3D.new()
	projectile.name = "AK47Bullet"
	projectile.set_script(BULLET_PROJECTILE)
	projectile.set("direction", world_direction)
	projectile.set("source_body", player)
	projectile.set("damage", 24 + (GameState.weapon_level - 1) * 6)
	projectile.position = _get_weapon_muzzle_position(world_direction)
	add_child(projectile)
	_play_gunshot()
	if perception_system:
		perception_system.call("emit_player_gunshot", player.global_position, 52.0)
	_spawn_muzzle_light(world_direction)
	_spawn_launch_fx(world_direction)
	_update_equipment_ui()


func _get_current_fire_direction() -> Vector3:
	if _uses_mouse_aim():
		return _get_mouse_world_direction()
	var screen_direction: Vector2 = DIRECTION_VECTORS[facing]
	return Vector3(
		screen_direction.x + screen_direction.y,
		0,
		-screen_direction.x + screen_direction.y
	).normalized()


func _update_weapon_pose() -> void:
	if weapon_sprite == null:
		return
	weapon_sprite.visible = has_ak and building_canvas == null
	if not has_ak:
		return
	var direction := _get_current_facing_world_direction()
	weapon_sprite.position = direction * 0.34 + Vector3(0, 0.34, 0)
	weapon_sprite.offset = _get_weapon_screen_offset()
	if not weapon_sprite.animation.begins_with("fire_"):
		weapon_sprite.play("idle_%s" % facing)


func _get_weapon_screen_offset() -> Vector2:
	match facing:
		"n": return Vector2(0, -34)
		"ne": return Vector2(24, -30)
		"e": return Vector2(34, -18)
		"se": return Vector2(28, -8)
		"s": return Vector2(0, -6)
		"sw": return Vector2(-28, -8)
		"w": return Vector2(-34, -18)
		"nw": return Vector2(-24, -30)
	return Vector2(0, -18)


func _get_weapon_muzzle_position(world_direction: Vector3) -> Vector3:
	var weapon_origin := weapon_sprite.global_position if weapon_sprite and has_ak else player.global_position
	return weapon_origin + world_direction * 0.48 + Vector3(0, 0.02, 0)


func _get_mouse_world_direction() -> Vector3:
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	var target_y := player.global_position.y
	if absf(ray_direction.y) < 0.001:
		return _get_current_facing_world_direction()
	var distance_to_plane := (target_y - ray_origin.y) / ray_direction.y
	var hit_position := ray_origin + ray_direction * distance_to_plane
	var direction := hit_position - player.global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return _get_current_facing_world_direction()
	return direction.normalized()


func _get_current_facing_world_direction() -> Vector3:
	var screen_direction: Vector2 = DIRECTION_VECTORS[facing]
	return Vector3(
		screen_direction.x + screen_direction.y,
		0,
		-screen_direction.x + screen_direction.y
	).normalized()


func _reload_ak47() -> void:
	if reserve_ammo <= 0 or magazine_ammo >= 30:
		fire_cooldown = 0.35
		return
	var needed := 30 - magazine_ammo
	var loaded := mini(needed, reserve_ammo)
	magazine_ammo += loaded
	reserve_ammo -= loaded
	GameState.magazine_ammo = magazine_ammo
	GameState.reserve_ammo = reserve_ammo
	fire_cooldown = 0.85
	ammo_notice.text = "AK-47 재장전  +%d\n탄창 %d / 30   예비 %d   총 %d" % [
		loaded,
		magazine_ammo,
		reserve_ammo,
		magazine_ammo + reserve_ammo,
	]
	ammo_notice.visible = true
	ammo_notice_time = 1.4
	_update_equipment_ui()


func _update_equipment_ui() -> void:
	var total_ammo := magazine_ammo + reserve_ammo
	if equipment_label:
		equipment_label.text = "AK-47  장착\n탄창 %02d / 30   예비 %03d\n총 탄약 %03d" % [magazine_ammo, reserve_ammo, total_ammo]
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "AK-47\n%d | %d" % [magazine_ammo, reserve_ammo] if has_ak else "빈 손\n-"
	if inventory_ui:
		inventory_ui.call("update_state", has_ak, magazine_ammo, reserve_ammo)


func _is_inventory_open() -> bool:
	return inventory_ui != null and bool(inventory_ui.call("is_open"))


func _toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.call("toggle")


func _on_inventory_open_state_changed(is_open: bool) -> void:
	if not is_open:
		return
	fire_button_held = false
	mouse_fire_held = false
	pickup_touch_held = false
	pickup_keyboard_held = false
	touch_vector = Vector2.ZERO


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
	_spawn_particle_burst(origin, direction, Color("#ffd98a"), 6, 0.09, 2.0, 4.2, 0.04, 0.12)
	_spawn_smoke_cloud(origin, direction)
	get_tree().create_timer(0.055).timeout.connect(func() -> void:
		_spawn_smoke_cloud(origin + direction * 0.08, direction)
	)


func _spawn_smoke_cloud(origin: Vector3, direction: Vector3) -> void:
	if smoke_particle_texture == null:
		smoke_particle_texture = _create_smoke_texture()
	var particles := GPUParticles3D.new()
	particles.position = origin
	particles.amount = 9
	particles.lifetime = 0.72
	particles.one_shot = true
	particles.explosiveness = 0.82
	particles.randomness = 0.7
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	var process := ParticleProcessMaterial.new()
	process.direction = (direction * 0.28 + Vector3.UP * 0.72).normalized()
	process.spread = 38.0
	process.gravity = Vector3(0, 0.42, 0)
	process.initial_velocity_min = 0.18
	process.initial_velocity_max = 0.8
	process.damping_min = 0.4
	process.damping_max = 1.1
	process.scale_min = 0.35
	process.scale_max = 0.85
	var alpha_gradient := Gradient.new()
	alpha_gradient.offsets = PackedFloat32Array([0.0, 0.18, 1.0])
	alpha_gradient.colors = PackedColorArray([
		Color(0.32, 0.34, 0.35, 0.0),
		Color(0.32, 0.34, 0.35, 0.52),
		Color(0.18, 0.2, 0.21, 0.0),
	])
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = alpha_gradient
	process.color_ramp = color_ramp
	particles.process_material = process
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = smoke_particle_texture
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.42, 0.42)
	mesh.material = material
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func _create_smoke_texture() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / 64.0
			var radius := uv.distance_to(Vector2(0.5, 0.5)) * 2.0
			var noise := sin(float(x * 17 + y * 31)) * 0.035
			var alpha := clampf((1.0 - radius + noise) * 2.3, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha * alpha))
	return ImageTexture.create_from_image(image)


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


func _spawn_enemies() -> void:
	var spawn_points := [
		Vector2(-8, -6),
		Vector2(10, -6),
		Vector2(-11, 7),
		Vector2(13, 4),
		Vector2(-18, -15),
		Vector2(20, -15),
		Vector2(-20, 18),
		Vector2(22, 18),
	]
	spawn_points.shuffle()
	for index in BASE_ENEMY_COUNT:
		var kind := "melee" if index < 3 else "pistol"
		var spawn_position := Vector3(spawn_points[index].x * MAP_CONTENT_SCALE, 0.78, spawn_points[index].y * MAP_CONTENT_SCALE)
		_spawn_enemy(kind, _safe_map_position(spawn_position), night_intensity)


func _spawn_enemy(kind: String, spawn_position: Vector3, threat: float) -> CharacterBody3D:
	var sheets := ENEMY_MELEE_SHEETS if kind == "melee" else ENEMY_PISTOL_SHEETS
	var enemy := CharacterBody3D.new()
	enemy.name = "%sEnemy%d" % [kind.capitalize(), enemy_spawn_serial]
	enemy_spawn_serial += 1
	enemy.set_script(ENEMY_SCRIPT)
	enemy.add_to_group("sound_source")
	enemy.position = spawn_position
	enemy.call("configure", kind, player, sheets, threat)
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)
	return enemy


func _on_enemy_died(enemy: CharacterBody3D) -> void:
	enemies.erase(enemy)
	reinforcement_timer = minf(reinforcement_timer, 2.5)


func _update_enemy_pressure(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			enemies.remove_at(index)
			continue
		enemy.call("set_threat_level", night_intensity)

	var target_count := BASE_ENEMY_COUNT + roundi(night_intensity * float(MAX_NIGHT_ENEMY_COUNT - BASE_ENEMY_COUNT))
	if enemies.size() >= target_count:
		reinforcement_timer = minf(reinforcement_timer, 3.0)
		return

	reinforcement_timer -= delta
	if reinforcement_timer > 0.0:
		return
	var spawn_position := _find_reinforcement_position()
	if spawn_position != Vector3.INF:
		var pistol_chance := lerpf(0.34, 0.52, night_intensity)
		var kind := "pistol" if spawn_random.randf() < pistol_chance else "melee"
		_spawn_enemy(kind, spawn_position, night_intensity)
	reinforcement_timer = lerpf(18.0, 3.8, night_intensity)


func _find_reinforcement_position() -> Vector3:
	var world := $World as ProceduralCityMap
	var map_limit := world.get_map_limit() - 4.0
	for attempt in 16:
		var angle := spawn_random.randf_range(0.0, TAU)
		var distance := spawn_random.randf_range(20.0, 34.0)
		var requested := player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		requested.x = clampf(requested.x, -map_limit, map_limit)
		requested.z = clampf(requested.z, -map_limit, map_limit)
		requested.y = 0.78
		var candidate := world.find_nearest_open_position(requested)
		if candidate.distance_to(player.global_position) < 17.0:
			continue
		if world.is_position_in_safe_zone(candidate):
			continue
		var overlaps_enemy := false
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(candidate) < 2.2:
				overlaps_enemy = true
				break
		if not overlaps_enemy:
			return candidate
	return Vector3.INF


func _build_day_night_tint() -> void:
	var tint_layer := CanvasLayer.new()
	tint_layer.name = "DayNightTint"
	tint_layer.layer = 1
	add_child(tint_layer)
	day_night_tint = ColorRect.new()
	day_night_tint.name = "NightColor"
	day_night_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_night_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint_layer.add_child(day_night_tint)


func _update_day_night(delta: float) -> void:
	world_time_hours = fposmod(world_time_hours + delta / SECONDS_PER_GAME_HOUR, 24.0)
	GameState.world_time_hours = world_time_hours
	night_intensity = _get_night_intensity(world_time_hours)
	var next_phase := _get_day_phase(world_time_hours)
	if next_phase != current_day_phase:
		current_day_phase = next_phase
	_update_day_night_visuals()
	_update_time_hud()
	if perception_system:
		perception_system.call("set_vision_range", lerpf(13.5, 5.0, night_intensity))


func _get_night_intensity(hour: float) -> float:
	if hour >= 19.0:
		return clampf(inverse_lerp(17.0, 24.0, hour), 0.0, 1.0)
	if hour < 4.5:
		return 1.0
	if hour < 7.0:
		return 1.0 - inverse_lerp(4.5, 7.0, hour)
	if hour >= 17.0:
		return inverse_lerp(17.0, 24.0, hour)
	return 0.0


func _get_day_phase(hour: float) -> String:
	if hour >= DEEP_NIGHT_HOUR or hour < 4.5:
		return "심야"
	if hour >= NIGHT_START_HOUR or hour < 6.0:
		return "밤"
	if hour >= 17.0:
		return "황혼"
	if hour < 7.0:
		return "새벽"
	return "낮"


func _update_day_night_visuals() -> void:
	if day_night_tint:
		var tint_color := Color(0.025, 0.055, 0.12, lerpf(0.0, 0.48, night_intensity))
		day_night_tint.color = tint_color
	if sun:
		sun.light_energy = lerpf(1.15, 0.18, night_intensity)
		sun.light_color = Color(0.72, 0.77, 0.8).lerp(Color(0.25, 0.34, 0.52), night_intensity)
	if world_environment and world_environment.environment:
		var environment := world_environment.environment
		environment.ambient_light_energy = lerpf(0.72, 0.2, night_intensity)
		environment.ambient_light_color = Color(0.54, 0.59, 0.62).lerp(Color(0.12, 0.18, 0.28), night_intensity)
		environment.fog_light_energy = lerpf(0.65, 0.18, night_intensity)
		environment.fog_light_color = Color(0.32, 0.36, 0.38).lerp(Color(0.08, 0.12, 0.2), night_intensity)
		environment.fog_density = lerpf(0.008, 0.014, night_intensity)


func _update_time_hud() -> void:
	var hour := floori(world_time_hours)
	var minute := floori((world_time_hours - float(hour)) * 60.0)
	var danger_tier := 1 + floori(night_intensity * 3.99)
	time_label.text = "%s  %02d:%02d  ·  위험 %d" % [current_day_phase, hour, minute, danger_tier]
	var phase_color := Color("#d6c891").lerp(Color("#ff6f5c"), night_intensity)
	time_label.add_theme_color_override("font_color", phase_color)


func _build_visibility_fog() -> void:
	$HUD.layer = 3
	var fog_layer := CanvasLayer.new()
	fog_layer.name = "VisibilityFog"
	fog_layer.layer = 2
	add_child(fog_layer)
	var darkness := ColorRect.new()
	darkness.name = "Darkness"
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_layer.add_child(darkness)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 player_screen = vec2(640.0, 360.0);
uniform float inner_radius = 245.0;
uniform float outer_radius = 430.0;
uniform float darkness = 0.86;

void fragment() {
	vec2 pixel_position = UV * viewport_size;
	float distance_from_player = length(pixel_position - player_screen);
	float fog_alpha = smoothstep(inner_radius, outer_radius, distance_from_player) * darkness;
	COLOR = vec4(0.008, 0.012, 0.015, fog_alpha);
}
"""
	visibility_material = ShaderMaterial.new()
	visibility_material.shader = shader
	darkness.material = visibility_material
	_update_visibility_fog()


func _update_visibility_fog() -> void:
	if visibility_material == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var inner_radius := lerpf(330.0, 125.0, night_intensity)
	var outer_radius := lerpf(560.0, 265.0, night_intensity)
	var edge_darkness := lerpf(0.68, 0.94, night_intensity)
	visibility_material.set_shader_parameter("viewport_size", viewport_size)
	visibility_material.set_shader_parameter("player_screen", camera.unproject_position(player.global_position))
	visibility_material.set_shader_parameter("inner_radius", inner_radius)
	visibility_material.set_shader_parameter("outer_radius", outer_radius)
	visibility_material.set_shader_parameter("darkness", edge_darkness)


func _install_perception_system() -> void:
	perception_system = PERCEPTION_SYSTEM_SCRIPT.new() as CanvasLayer
	perception_system.call("setup", player, camera)
	add_child(perception_system)


func take_damage(amount: int) -> void:
	player_health = maxi(0, player_health - amount)
	GameState.player_health = player_health
	var health_bar := get_node_or_null("HUD/TopLeft/Margin/VBox/Health") as ProgressBar
	if health_bar:
		health_bar.value = player_health
	if ammo_notice:
		ammo_notice.text = "피격  -%d   체력 %d/100" % [amount, player_health]
		ammo_notice.visible = true
		ammo_notice_time = 1.1
	if player_health <= 0:
		fire_button_held = false
		player.velocity = Vector3.ZERO
		state_label.text = "행동 불능"


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
	for node in get_tree().get_nodes_in_group("vehicle_obstacle"):
		var vehicle := node as Node3D
		var source := vehicle.get_node_or_null("VehicleSprite") as Sprite3D
		if source == null or source.texture == null:
			continue
		var overlay := Sprite2D.new()
		overlay.name = "%sOverlay" % vehicle.name
		overlay.texture = source.texture
		overlay.centered = true
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		building_canvas.add_child(overlay)
		vehicle_overlays[vehicle] = overlay
		source.visible = false
	survivor_overlay = Sprite2D.new()
	survivor_overlay.name = "SurvivorOverlay"
	survivor_overlay.centered = true
	survivor_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	var player_depth := OVERLAY_DEPTH_SORT.world_depth(player.global_position)
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
		overlay.z_index = OVERLAY_DEPTH_SORT.building_depth(
			building.global_position,
			player.global_position,
			bool(building.get_meta("overlay_overlaps_player", false)),
			bool(building.get_meta("overlay_occludes_player", false))
		)
	for vehicle in vehicle_overlays:
		if not is_instance_valid(vehicle):
			continue
		var source := vehicle.get_node_or_null("VehicleSprite") as Sprite3D
		var overlay := vehicle_overlays[vehicle] as Sprite2D
		if source == null or overlay == null:
			continue
		overlay.position = camera.unproject_position(source.global_position)
		overlay.scale = Vector2.ONE * source.pixel_size * screen_scale
		overlay.offset = source.offset
		overlay.modulate = source.modulate
		overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(vehicle.global_position)
	var survivor_texture := survivor.sprite_frames.get_frame_texture(survivor.animation, survivor.frame)
	if survivor_texture:
		survivor_overlay.texture = survivor_texture
	survivor_overlay.position = camera.unproject_position(survivor.global_position)
	survivor_overlay.scale = Vector2.ONE * survivor.pixel_size * screen_scale
	survivor_overlay.flip_h = survivor.flip_h
	survivor_overlay.modulate = survivor.modulate
	survivor_overlay.z_index = player_depth
	if has_ak and weapon_sprite and weapon_sprite.sprite_frames:
		var weapon_texture := weapon_sprite.sprite_frames.get_frame_texture(weapon_sprite.animation, weapon_sprite.frame)
		if weapon_texture:
			weapon_overlay.texture = weapon_texture
		weapon_overlay.visible = true
		weapon_overlay.position = camera.unproject_position(weapon_sprite.global_position)
		weapon_overlay.scale = Vector2.ONE * weapon_sprite.pixel_size * screen_scale
		weapon_overlay.offset = weapon_sprite.offset
		weapon_overlay.modulate = weapon_sprite.modulate
		weapon_overlay.z_index = player_depth + 1
	else:
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
		var overlaps_player := sprite != null and _is_player_inside_sprite_screen_rect(sprite)
		var is_occluding := (
			overlaps_player
			and depth > 0.8
			and depth < depth_limit
			and lateral < lateral_limit
		)
		building.set_meta("overlay_overlaps_player", overlaps_player)
		building.set_meta("overlay_occludes_player", is_occluding)
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


func _safe_map_position(requested_position: Vector3) -> Vector3:
	var world := get_node_or_null("World") as ProceduralCityMap
	if world == null:
		return requested_position
	return world.find_nearest_open_position(requested_position)


func _scale_map_position(position: Vector3) -> Vector3:
	return Vector3(position.x * MAP_CONTENT_SCALE, position.y, position.z * MAP_CONTENT_SCALE)


func _save_run_state() -> void:
	GameState.player_health = player_health
	GameState.magazine_ammo = magazine_ammo
	GameState.reserve_ammo = reserve_ammo
	GameState.has_ak = has_ak


func _on_shelter_portal_entered() -> void:
	_save_run_state()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/shelter_interior.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
		if key == KEY_I and key_event.pressed:
			_toggle_inventory()
			return
		if _is_inventory_open():
			return
		if key == KEY_E:
			if key_event.pressed and is_instance_valid(nearby_ammo_pickup):
				_collect_nearby_ammo()
				pickup_keyboard_held = false
			else:
				pickup_keyboard_held = key_event.pressed
		elif key == KEY_SPACE and key_event.pressed:
			_try_fire_ak47()
		elif key == KEY_R and key_event.pressed and has_ak:
			_reload_ak47()
		elif key == KEY_N and key_event.pressed:
			_save_run_state()
			GameState.randomize_map()
			get_tree().reload_current_scene()
	elif event is InputEventScreenTouch:
		if _is_inventory_open():
			return
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


func _unhandled_input(event: InputEvent) -> void:
	if DisplayServer.is_touchscreen_available() or _is_inventory_open():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_fire_held = mouse_event.pressed
			if mouse_event.pressed:
				_try_fire_ak47()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_try_melee_attack()
