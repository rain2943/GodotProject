extends Node3D

const MOVE_SPEED := 5.2
const BASE_CAMERA_SIZE := 28.0
const CAMERA_DIAGONAL_OFFSET := 13.5
const OCCLUSION_LATERAL_LIMIT := 5.1
const OCCLUSION_DEPTH_LIMIT := 14.0
const SILHOUETTE_COLOR := Color("#26343b")
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const CAT_ANIMATION_ROOT := "res://assets/characters/cat_8way"
const CAT_ROLL_ANIMATION_ROOT := "res://assets/characters/cat_roll"
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
const ROLL_FRAME_COUNT := 4
const ROLL_DURATION := 0.48
const ROLL_COOLDOWN_DURATION := 1.5
const ROLL_START_SPEED := 36.0
const ROLL_END_SPEED := 4.4
const ROLL_AFTERIMAGE_INTERVAL := 0.055
const WEAPON_FRAME_SIZE := Vector2(192, 192)
const WEAPON_VISUAL_PIXEL_SIZE := 0.0094
const WEAPON_FLOAT_DISTANCE := 0.72
const WEAPON_MUZZLE_FORWARD_DISTANCE := 0.64
const AK_DROP_TEXTURE := preload("res://assets/weapons/ak47_drop.png")
const AK_DIRECTIONAL_TEXTURE := preload("res://assets/weapons/ak47_directional.png")
const AMMO_762_TEXTURE := preload("res://assets/items/ammo_762.png")
const BASEBALL_BAT_TEXTURE := preload("res://assets/weapons/baseball_bat_temp.png")
const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const INVENTORY_UI_SCRIPT := preload("res://scripts/inventory_ui.gd")
const PERCEPTION_SYSTEM_SCRIPT := preload("res://scripts/perception_system.gd")
const OVERLAY_DEPTH_SORT := preload("res://scripts/overlay_depth_sort.gd")
const WEAPON_SYSTEM := preload("res://scripts/weapon_system.gd")
const AIM_RETICLE_SCRIPT := preload("res://scripts/aim_reticle.gd")
const ROLL_COOLDOWN_INDICATOR_SCRIPT := preload("res://scripts/roll_cooldown_indicator.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/tactical_map.gd")
const SEWER_EXIT_TEXTURE := preload("res://assets/extraction/sewer_exit.png")
const AK_PICKUP_POSITION := Vector3(1.15, 0.32, 0.7)
const PICKUP_DISTANCE := 1.75
const PICKUP_HOLD_DURATION := 0.9
const AIM_HOLD_DURATION := 0.55
const AMMO_PICKUP_AMOUNT := 30
const MAP_CONTENT_SCALE := ProceduralCityMap.WORLD_SCALE
const SECONDS_PER_GAME_HOUR := 36.0
const NIGHT_START_HOUR := 19.0
const DEEP_NIGHT_HOUR := 22.0
const BASE_ENEMY_COUNT := 10
const MAX_NIGHT_ENEMY_COUNT := 24
const MELEE_ATTACK_COOLDOWN := 0.72
const MELEE_ATTACK_RANGE := 2.2
const MELEE_ATTACK_DAMAGE := 38
const REINFORCEMENT_CALL_TRIGGER_TIME := 7.0
const REINFORCEMENT_CALL_DURATION := 4.6
const REINFORCEMENT_CALL_COOLDOWN := 24.0
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
@onready var companion: CharacterBody3D = $FemaleCatCompanion
@onready var companion_sprite: AnimatedSprite3D = $FemaleCatCompanion/Sprite
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
var melee_button: Button
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
var companion_overlay: Sprite2D
var weapon_overlay: Sprite2D
var roll_afterimages: Array[Sprite2D] = []
var unarmed_sprite_frames: SpriteFrames
var ammo_pickups: Array[Node3D] = []
var ammo_notice: Label
var ammo_notice_time := 0.0
var ammo_pickup_chain_total := 0
var ammo_pickup_chain_time := 0.0
var ammo_prompt_panel: PanelContainer
var ammo_pickup_button: Button
var nearby_ammo_pickup: Node3D
var inventory_ui: Control
var visibility_material: ShaderMaterial
var perception_system: CanvasLayer
var aim_hold_time := 0.0
var locked_aim_direction := Vector3.ZERO
var smoke_particle_texture: ImageTexture
var loot_glow_texture: ImageTexture
var canned_food_texture: ImageTexture
var weapon_loot_texture_cache: Dictionary = {}
var player_health := 82
var enemies: Array[CharacterBody3D] = []
var world_time_hours := 9.0
var night_intensity := 0.0
var enemy_spawn_serial := 0
var enemy_ranged_spawn_serial := 0
var reinforcement_timer := 8.0
var player_activity_heat := 0.0
var sustained_combat_time := 0.0
var reinforcement_call_cooldown := 0.0
var active_reinforcement_caller: CharacterBody3D
var day_night_tint: ColorRect
var current_day_phase := ""
var spawn_random := RandomNumberGenerator.new()
var melee_bat_sprite: Sprite3D
var melee_bat_overlay: Sprite2D
var melee_attack_cooldown := 0.0
var melee_arc_texture: ImageTexture
var equipped_weapon_id := "ak47"
var equipped_weapon_mods: Array[String] = []
var weapon_stats: Dictionary = {}
var weapon_durability := 100.0
var weapon_spread_deg := 2.4
var recoil_velocity := Vector3.ZERO
var recoil_reticle_offset := Vector2.ZERO
var weapon_reloading := false
var reload_timer := 0.0
var laser_aim_held := false
var loafing := false
var aim_direction_indicator: MeshInstance3D
var laser_beam: MeshInstance3D
var laser_beam_mesh: BoxMesh
var laser_glow_layers: Array[MeshInstance3D] = []
var laser_glow_meshes: Array[BoxMesh] = []
var laser_glow_materials: Array[StandardMaterial3D] = []
var laser_endpoint: MeshInstance3D
var aim_reticle: Control
var aim_canvas: CanvasLayer
var damage_feedback_canvas: CanvasLayer
var damage_vignette: ColorRect
var damage_vignette_material: ShaderMaterial
var player_world_health_bar: Control
var player_world_health_fill: Panel
var player_health_fill_style: StyleBoxFlat
var roll_cooldown_indicator: Control
var player_hit_flash_time := 0.0
var player_hit_stun_time := 0.0
var roll_active := false
var roll_elapsed := 0.0
var roll_cooldown_remaining := 0.0
var roll_afterimage_timer := 0.0
var roll_direction := Vector3.ZERO
var scope_camera_offset := Vector3.ZERO
var weapon_random := RandomNumberGenerator.new()
var tactical_map: Control
var extraction_site: Node3D
var extraction_position := Vector3.ZERO
var extraction_prompt: Control
var extraction_transition_active := false
var extraction_fade: ColorRect
var extraction_success_label: Label
var lightning_overlay: ColorRect
var lightning_timer := 12.0


func _ready() -> void:
	world_time_hours = GameState.world_time_hours
	night_intensity = _get_night_intensity(world_time_hours)
	spawn_random.seed = GameState.map_seed + 9137
	weapon_random.seed = GameState.map_seed + 44123
	player_health = GameState.player_health
	magazine_ammo = GameState.magazine_ammo
	reserve_ammo = GameState.reserve_ammo
	equipped_weapon_id = GameState.equipped_weapon_id
	equipped_weapon_mods.assign(GameState.equipped_weapon_mods)
	weapon_durability = GameState.weapon_durability
	_refresh_weapon_stats()
	reserve_ammo = GameState.get_ammo_count(GameState.equipped_ammo_id)
	GameState.reserve_ammo = reserve_ammo
	has_ak = false
	camera.size = BASE_CAMERA_SIZE
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
	_setup_aim_feedback()
	_setup_player_combat_feedback()
	_setup_weather_effects()
	_spawn_ammo_pickups()
	_build_weapon_hud()
	_build_gunshot_audio()
	_spawn_enemies()
	_setup_building_overlays()
	_build_day_night_tint()
	_build_visibility_fog()
	_install_perception_system()
	_update_day_night(0.0)
	_update_enemy_visibility()
	_set_facing("s")
	var world := $World as ProceduralCityMap
	world.shelter_portal_entered.connect(_on_shelter_portal_entered)
	if GameState.returning_from_shelter:
		player.position = world.get_shelter_exit_position()
		GameState.returning_from_shelter = false
	else:
		player.position = world.find_nearest_open_position(player.position)
	_setup_extraction_site(world)
	_setup_tactical_map(world)
	var health_bar := get_node_or_null("HUD/TopLeft/Margin/VBox/Health") as ProgressBar
	if health_bar:
		health_bar.value = player_health
	_equip_ak47()
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _physics_process(delta: float) -> void:
	_update_day_night(delta)
	_update_player_activity_heat(delta)
	_update_lightning(delta)
	_update_enemy_pressure(delta)
	melee_attack_cooldown = maxf(0.0, melee_attack_cooldown - delta)
	aim_hold_time = maxf(0.0, aim_hold_time - delta)
	player_hit_stun_time = maxf(0.0, player_hit_stun_time - delta)
	if not roll_active:
		roll_cooldown_remaining = maxf(0.0, roll_cooldown_remaining - delta)
	if (laser_aim_held or mouse_fire_held) and has_ak and _uses_mouse_aim():
		_lock_aim_direction(_get_mouse_world_direction())
	_update_scope_camera(delta)
	var aim_is_locked := (has_ak and (fire_button_held or mouse_fire_held or laser_aim_held)) or aim_hold_time > 0.0
	if melee_button:
		melee_button.disabled = melee_attack_cooldown > 0.0
	_update_extraction_prompt()
	if _is_inventory_open() or _is_tactical_map_open() or extraction_transition_active:
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		_update_building_overlays()
		_update_visibility_fog()
		_update_enemy_visibility()
		return
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W): input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_vector.y += 1.0
	input_vector = input_vector.limit_length(1.0)
	if touch_vector.length_squared() > input_vector.length_squared():
		input_vector = touch_vector
	if player_hit_stun_time > 0.0:
		input_vector = Vector2.ZERO
	loafing = not DisplayServer.is_touchscreen_available() and Input.is_key_pressed(KEY_C)
	_update_weapon_ballistics(delta, input_vector.length_squared() > 0.01)

	var world_direction := Vector3(input_vector.x + input_vector.y, 0, -input_vector.x + input_vector.y)
	if roll_active:
		_update_roll(delta)
	elif world_direction.length_squared() > 0.01:
		world_direction = world_direction.normalized()
		var movement_speed := MOVE_SPEED * (0.38 if loafing else 1.0)
		if weapon_reloading:
			movement_speed *= 0.55
		player.velocity = world_direction * movement_speed + recoil_velocity
		if not aim_is_locked:
			_update_facing(input_vector)
		_set_motion_state("walk")
		state_label.text = "식빵 자세 이동" if loafing else "이동 중"
	else:
		player.velocity = recoil_velocity
		_set_motion_state("idle")
		state_label.text = "식빵 자세 · 반동 제어" if loafing else "경계 중"

	if not roll_active and aim_is_locked and locked_aim_direction.length_squared() > 0.01:
		_set_facing_from_world_direction(locked_aim_direction)
	_update_weapon_pose()

	player.move_and_slide()
	var map_limit := ($World as ProceduralCityMap).get_map_limit()
	player.position.x = clampf(player.position.x, -map_limit, map_limit)
	player.position.z = clampf(player.position.z, -map_limit, map_limit)
	_update_pickup(delta)
	_update_ammo_pickups(delta)
	_update_firing(delta)
	_update_aim_feedback(delta)
	_update_camera_occluders(delta)
	_update_player_combat_feedback(delta)
	var camera_target := Vector3(player.position.x, 0, player.position.z) + scope_camera_offset
	camera_rig.position = camera_rig.position.lerp(camera_target, 1.0 - exp(-7.0 * delta))
	_update_building_overlays()
	_update_visibility_fog()
	_update_enemy_visibility()
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
	if ((has_ak and (fire_button_held or mouse_fire_held or laser_aim_held)) or aim_hold_time > 0.0) and locked_aim_direction.length_squared() > 0.01:
		return locked_aim_direction
	return _get_current_facing_world_direction()


func _try_start_roll() -> void:
	if roll_active or roll_cooldown_remaining > 0.001 or player_health <= 0:
		return
	var roll_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): roll_input.x -= 1.0
	if Input.is_key_pressed(KEY_D): roll_input.x += 1.0
	if Input.is_key_pressed(KEY_W): roll_input.y -= 1.0
	if Input.is_key_pressed(KEY_S): roll_input.y += 1.0
	roll_input = roll_input.limit_length(1.0)
	if touch_vector.length_squared() > roll_input.length_squared():
		roll_input = touch_vector
	if roll_input.length_squared() > 0.01:
		roll_direction = Vector3(
			roll_input.x + roll_input.y,
			0.0,
			-roll_input.x + roll_input.y
		).normalized()
	else:
		roll_direction = _get_current_facing_world_direction()
	_set_facing_from_world_direction(roll_direction)
	roll_active = true
	player_activity_heat = minf(1.0, player_activity_heat + 0.12)
	roll_elapsed = 0.0
	roll_afterimage_timer = 0.0
	recoil_velocity = Vector3.ZERO
	_set_motion_state("roll")
	state_label.text = "회피 구르기"
	_spawn_roll_afterimage()


func _update_roll(delta: float) -> void:
	roll_elapsed += delta
	var progress := clampf(roll_elapsed / ROLL_DURATION, 0.0, 1.0)
	var speed_weight := pow(1.0 - progress, 2.35)
	var roll_speed := lerpf(ROLL_END_SPEED, ROLL_START_SPEED, speed_weight)
	player.velocity = roll_direction * roll_speed
	roll_afterimage_timer -= delta
	if roll_afterimage_timer <= 0.0:
		roll_afterimage_timer += ROLL_AFTERIMAGE_INTERVAL
		_spawn_roll_afterimage()
	if roll_elapsed >= ROLL_DURATION:
		_finish_roll()


func _finish_roll() -> void:
	if not roll_active:
		return
	roll_active = false
	roll_elapsed = 0.0
	roll_cooldown_remaining = ROLL_COOLDOWN_DURATION
	player.velocity = roll_direction * ROLL_END_SPEED
	_set_motion_state("idle")
	state_label.text = "구르기 재정비"


func _spawn_roll_afterimage() -> void:
	if building_canvas == null or survivor_overlay == null or survivor.sprite_frames == null:
		return
	var ghost_texture := survivor.sprite_frames.get_frame_texture(survivor.animation, survivor.frame)
	if ghost_texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.name = "RollAfterimage"
	ghost.texture = ghost_texture
	ghost.centered = true
	ghost.offset = survivor_overlay.offset
	ghost.flip_h = survivor_overlay.flip_h
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.position = camera.unproject_position(survivor.global_position)
	ghost.scale = survivor_overlay.scale
	ghost.modulate = Color(0.72, 0.8, 0.82, 0.32)
	ghost.z_index = OVERLAY_DEPTH_SORT.world_depth(player.global_position) - 1
	ghost.set_meta("world_position", survivor.global_position)
	building_canvas.add_child(ghost)
	roll_afterimages.append(ghost)
	var target_scale := ghost.scale * 1.055
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate", Color(0.62, 0.68, 0.7, 0.0), 0.26)
	tween.tween_property(ghost, "scale", target_scale, 0.26)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


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
	if weapon_sprite and has_ak:
		var weapon_state := "fire" if weapon_sprite.animation.begins_with("fire_") else "idle"
		var previous_frame := weapon_sprite.frame
		_play_weapon_directional_animation(weapon_state)
		if weapon_state == "fire":
			weapon_sprite.frame = mini(previous_frame, weapon_sprite.sprite_frames.get_frame_count(weapon_sprite.animation) - 1)
	_update_weapon_pose()


func _get_weapon_source_facing() -> String:
	match facing:
		"w": return "e"
		"sw": return "se"
		"nw": return "ne"
	return facing


func _play_weapon_directional_animation(state: String) -> void:
	if weapon_sprite == null:
		return
	weapon_sprite.flip_h = facing in ["w", "sw", "nw"]
	weapon_sprite.play("%s_%s" % [state, _get_weapon_source_facing()])


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
		var roll_animation_name := "roll_%s" % direction_name
		frames.add_animation(roll_animation_name)
		frames.set_animation_loop(roll_animation_name, false)
		frames.set_animation_speed(roll_animation_name, 10.0)
		for frame_index in ROLL_FRAME_COUNT:
			var roll_texture_path := "%s/%s_action-frame-%d.png" % [
				CAT_ROLL_ANIMATION_ROOT,
				state_prefix,
				frame_index,
			]
			var roll_texture := load(roll_texture_path) as Texture2D
			if roll_texture == null:
				push_error("Missing cat roll animation frame: %s" % roll_texture_path)
				continue
			frames.add_frame(roll_animation_name, roll_texture)
	return frames


func _setup_weapon_layer() -> void:
	weapon_sprite = AnimatedSprite3D.new()
	weapon_sprite.name = "EquippedAK47"
	weapon_sprite.position = Vector3(0, 0.32, 0)
	weapon_sprite.pixel_size = WEAPON_VISUAL_PIXEL_SIZE
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
		_play_weapon_directional_animation("idle")


func _setup_melee_weapon() -> void:
	melee_bat_sprite = Sprite3D.new()
	melee_bat_sprite.name = "TemporaryBaseballBat"
	melee_bat_sprite.texture = BASEBALL_BAT_TEXTURE
	melee_bat_sprite.pixel_size = 0.00135
	melee_bat_sprite.centered = true
	melee_bat_sprite.offset = Vector2.ZERO
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
	melee_bat_sprite.visible = building_canvas == null
	melee_bat_sprite.flip_h = false
	melee_bat_sprite.flip_v = false
	melee_bat_sprite.modulate = Color(1.18, 1.08, 0.92, 1.0)
	melee_bat_sprite.position = direction * 0.28 + Vector3(0, 0.43, 0)
	melee_bat_sprite.rotation.z = aligned_angle - deg_to_rad(96.0)
	melee_bat_sprite.scale = Vector3.ONE * 0.9
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(melee_bat_sprite, "rotation:z", aligned_angle + deg_to_rad(58.0), 0.21).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(melee_bat_sprite, "position", direction * 0.58 + Vector3(0, 0.45, 0), 0.21)
	tween.tween_property(melee_bat_sprite, "scale", Vector3.ONE * 1.04, 0.21)
	tween.chain().tween_property(melee_bat_sprite, "modulate", Color(1.0, 0.82, 0.55, 0.0), 0.13)
	tween.chain().tween_callback(func() -> void:
		melee_bat_sprite.visible = false
	)
	if is_instance_valid(melee_bat_overlay):
		melee_bat_overlay.visible = true
		melee_bat_overlay.modulate = Color(1.2, 1.08, 0.88, 1.0)
		melee_bat_overlay.position = player_screen + screen_direction * 25.0 + Vector2(0, -12)
		melee_bat_overlay.rotation = aligned_angle - deg_to_rad(98.0)
		melee_bat_overlay.scale = Vector2.ONE * 0.09
		melee_bat_overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(player.global_position) + 4
		var overlay_tween := create_tween()
		overlay_tween.set_parallel(true)
		overlay_tween.tween_property(melee_bat_overlay, "rotation", aligned_angle + deg_to_rad(62.0), 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		overlay_tween.tween_property(melee_bat_overlay, "position", player_screen + screen_direction * 66.0 + Vector2(0, -10), 0.22)
		overlay_tween.tween_property(melee_bat_overlay, "scale", Vector2.ONE * 0.115, 0.22)
		overlay_tween.chain().tween_property(melee_bat_overlay, "modulate:a", 0.0, 0.11)
		overlay_tween.chain().tween_callback(func() -> void:
			melee_bat_overlay.visible = false
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


func _refresh_weapon_stats() -> void:
	weapon_stats = WEAPON_SYSTEM.build_stats(equipped_weapon_id, equipped_weapon_mods)
	var magazine_id := GameState.equipped_magazine_id
	if not WEAPON_SYSTEM.is_magazine_compatible(equipped_weapon_id, magazine_id):
		magazine_id = str(weapon_stats.get("magazine_id", ""))
		GameState.equipped_magazine_id = magazine_id
	var ammo_id := GameState.equipped_ammo_id
	if not WEAPON_SYSTEM.is_ammo_compatible(magazine_id, ammo_id):
		ammo_id = str(weapon_stats.get("default_ammo_id", ""))
		GameState.equipped_ammo_id = ammo_id
	if not GameState.ammo_inventory.has(ammo_id):
		GameState.ammo_inventory[ammo_id] = reserve_ammo
	weapon_spread_deg = float(weapon_stats.get("base_spread_deg", 2.4))
	var magazine_size := int(weapon_stats.get("magazine_size", 30))
	magazine_ammo = mini(magazine_ammo, magazine_size)


func _update_scope_camera(delta: float) -> void:
	var scope_zoom := float(weapon_stats.get("scope_zoom", 1.0))
	var scope_active := (
		laser_aim_held
		and has_ak
		and _uses_mouse_aim()
		and scope_zoom > 1.0
		and not _is_inventory_open()
	)
	var target_offset := Vector3.ZERO
	var target_camera_size := BASE_CAMERA_SIZE
	if scope_active:
		var aim_direction := locked_aim_direction if locked_aim_direction.length_squared() > 0.01 else _get_mouse_world_direction()
		target_offset = aim_direction.normalized() * float(weapon_stats.get("scope_shift", 0.0))
		target_camera_size = BASE_CAMERA_SIZE - minf(4.5, (scope_zoom - 1.0) * 1.5)
	var blend_speed := 1.0 - exp(-8.5 * delta)
	scope_camera_offset = scope_camera_offset.lerp(target_offset, blend_speed)
	camera.size = lerpf(camera.size, target_camera_size, blend_speed)


func _setup_aim_feedback() -> void:
	aim_direction_indicator = MeshInstance3D.new()
	aim_direction_indicator.name = "AimDirectionIndicator"
	aim_direction_indicator.position = Vector3(0, -0.69, 0)
	aim_direction_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var arrow_mesh := _create_aim_ring_arrow_mesh()
	var arrow_material := StandardMaterial3D.new()
	arrow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_material.albedo_color = Color(0.92, 0.76, 0.34, 0.42)
	arrow_material.no_depth_test = false
	arrow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	arrow_mesh.surface_set_material(0, arrow_material)
	aim_direction_indicator.mesh = arrow_mesh
	player.add_child(aim_direction_indicator)

	var laser_widths := [0.072, 0.034, 0.010]
	var laser_colors := [
		Color(1.0, 0.02, 0.08, 0.10),
		Color(1.0, 0.04, 0.09, 0.32),
		Color(1.0, 0.72, 0.72, 0.96),
	]
	var laser_energies := [1.8, 3.8, 7.0]
	for layer_index in laser_widths.size():
		var mesh := BoxMesh.new()
		mesh.size = Vector3(laser_widths[layer_index], laser_widths[layer_index], 1.0)
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = laser_colors[layer_index]
		material.emission_enabled = true
		material.emission = Color(1.0, 0.015, 0.055)
		material.emission_energy_multiplier = laser_energies[layer_index]
		material.no_depth_test = true
		mesh.material = material
		var layer := MeshInstance3D.new()
		layer.name = "AimGuideLaserGlow%d" % layer_index
		layer.mesh = mesh
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.visible = false
		add_child(layer)
		laser_glow_layers.append(layer)
		laser_glow_meshes.append(mesh)
		laser_glow_materials.append(material)
	laser_beam = laser_glow_layers[2]
	laser_beam.name = "AimGuideLaserCore"
	laser_beam_mesh = laser_glow_meshes[2]

	var endpoint_mesh := SphereMesh.new()
	endpoint_mesh.radius = 0.065
	endpoint_mesh.height = 0.13
	endpoint_mesh.radial_segments = 12
	endpoint_mesh.rings = 6
	var endpoint_material := StandardMaterial3D.new()
	endpoint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	endpoint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	endpoint_material.albedo_color = Color(1.0, 0.18, 0.22, 0.82)
	endpoint_material.emission_enabled = true
	endpoint_material.emission = Color(1.0, 0.025, 0.06)
	endpoint_material.emission_energy_multiplier = 6.0
	endpoint_material.no_depth_test = true
	endpoint_mesh.material = endpoint_material
	laser_endpoint = MeshInstance3D.new()
	laser_endpoint.name = "AimGuideLaserEndpoint"
	laser_endpoint.mesh = endpoint_mesh
	laser_endpoint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser_endpoint.visible = false
	add_child(laser_endpoint)

	aim_canvas = CanvasLayer.new()
	aim_canvas.name = "AimFeedbackHUD"
	aim_canvas.layer = 130
	add_child(aim_canvas)
	aim_reticle = AIM_RETICLE_SCRIPT.new()
	aim_reticle.name = "AimReticle"
	aim_canvas.add_child(aim_reticle)
	aim_reticle.visible = not DisplayServer.is_touchscreen_available()


func _create_aim_ring_arrow_mesh() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var radius := 0.72
	var half_width := 0.045
	var start_angle := deg_to_rad(-150.0)
	var end_angle := deg_to_rad(150.0)
	var segment_count := 44
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment_index in segment_count:
		var ratio_a := float(segment_index) / float(segment_count)
		var ratio_b := float(segment_index + 1) / float(segment_count)
		var angle_a := lerpf(start_angle, end_angle, ratio_a)
		var angle_b := lerpf(start_angle, end_angle, ratio_b)
		var inner_a := Vector3(
			sin(angle_a) * (radius - half_width),
			0.0,
			-cos(angle_a) * (radius - half_width)
		)
		var outer_a := Vector3(
			sin(angle_a) * (radius + half_width),
			0.0,
			-cos(angle_a) * (radius + half_width)
		)
		var inner_b := Vector3(
			sin(angle_b) * (radius - half_width),
			0.0,
			-cos(angle_b) * (radius - half_width)
		)
		var outer_b := Vector3(
			sin(angle_b) * (radius + half_width),
			0.0,
			-cos(angle_b) * (radius + half_width)
		)
		for vertex in [inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]:
			mesh.surface_add_vertex(vertex)
	var arrow_tip := Vector3(0.0, 0.0, -1.03)
	var arrow_left := Vector3(-0.2, 0.0, -0.68)
	var arrow_right := Vector3(0.2, 0.0, -0.68)
	for vertex in [arrow_tip, arrow_left, arrow_right]:
		mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	return mesh


func _update_weapon_ballistics(delta: float, is_moving: bool) -> void:
	if weapon_stats.is_empty():
		return
	recoil_velocity = recoil_velocity.move_toward(Vector3.ZERO, 8.5 * delta)
	var target_spread := float(weapon_stats.get("base_spread_deg", 2.4))
	if is_moving:
		target_spread *= float(weapon_stats.get("moving_spread_multiplier", 1.0))
	if player_health <= 45:
		target_spread *= float(weapon_stats.get("injured_spread_multiplier", 1.0))
	if loafing:
		target_spread *= float(weapon_stats.get("loaf_spread_multiplier", 1.0))
	var durability_penalty := 1.0 + clampf((50.0 - weapon_durability) / 50.0, 0.0, 1.0) * 0.7
	target_spread *= durability_penalty
	var recovery := float(weapon_stats.get("spread_recovery_deg", 5.0))
	weapon_spread_deg = move_toward(weapon_spread_deg, target_spread, recovery * delta)
	weapon_spread_deg = clampf(weapon_spread_deg, 0.2, float(weapon_stats.get("max_spread_deg", 14.0)))
	if weapon_reloading:
		reload_timer = maxf(0.0, reload_timer - delta)
		if reload_timer <= 0.0:
			_finish_reload()


func _update_aim_feedback(delta: float) -> void:
	if aim_direction_indicator == null:
		return
	var aim_direction := _get_mouse_world_direction() if _uses_mouse_aim() else _get_current_facing_world_direction()
	aim_direction_indicator.look_at(aim_direction_indicator.global_position + aim_direction, Vector3.UP)
	recoil_reticle_offset = recoil_reticle_offset.lerp(Vector2.ZERO, 1.0 - exp(-10.0 * delta))
	_update_laser_beam(aim_direction)
	if aim_reticle:
		aim_reticle.visible = _uses_mouse_aim() and not _is_inventory_open()
		if aim_reticle.visible:
			aim_reticle.call(
				"update_feedback",
				get_viewport().get_mouse_position(),
				weapon_spread_deg,
				recoil_reticle_offset,
				laser_aim_held
			)


func _update_laser_beam(aim_direction: Vector3) -> void:
	if laser_beam == null:
		return
	var should_show := laser_aim_held and has_ak and _uses_mouse_aim()
	for layer in laser_glow_layers:
		layer.visible = should_show
	if laser_endpoint:
		laser_endpoint.visible = should_show
	if not should_show:
		return
	var start := _get_weapon_muzzle_position(aim_direction)
	var end := start + aim_direction * 48.0
	var query := PhysicsRayQueryParameters3D.create(start, end, 3)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit.get("position")
	var distance := start.distance_to(end)
	if distance <= 0.02:
		for layer in laser_glow_layers:
			layer.visible = false
		if laser_endpoint:
			laser_endpoint.visible = false
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	var base_widths := [0.072, 0.034, 0.010]
	for layer_index in laser_glow_layers.size():
		var width_scale := 1.0 + pulse * (0.18 if layer_index == 0 else 0.06)
		laser_glow_meshes[layer_index].size = Vector3(
			base_widths[layer_index] * width_scale,
			base_widths[layer_index] * width_scale,
			distance
		)
		var layer := laser_glow_layers[layer_index]
		layer.global_position = start.lerp(end, 0.5)
		layer.look_at(end, Vector3.UP)
	if laser_endpoint:
		laser_endpoint.global_position = end
		laser_endpoint.scale = Vector3.ONE * lerpf(0.82, 1.28, pulse)


func _setup_player_combat_feedback() -> void:
	damage_feedback_canvas = CanvasLayer.new()
	damage_feedback_canvas.name = "PlayerDamageFeedback"
	damage_feedback_canvas.layer = 129
	add_child(damage_feedback_canvas)

	damage_vignette = ColorRect.new()
	damage_vignette.name = "DamageVignette"
	damage_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_shader := Shader.new()
	vignette_shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float radial = smoothstep(0.28, 1.12, length(centered));
	float edge = max(radial, smoothstep(0.72, 1.0, max(abs(centered.x), abs(centered.y))));
	float pulse = edge * intensity;
	COLOR = vec4(0.72, 0.015, 0.01, pulse * 0.68);
}
"""
	damage_vignette_material = ShaderMaterial.new()
	damage_vignette_material.shader = vignette_shader
	damage_vignette_material.set_shader_parameter("intensity", 0.0)
	damage_vignette.material = damage_vignette_material
	damage_feedback_canvas.add_child(damage_vignette)

	player_world_health_bar = Control.new()
	player_world_health_bar.name = "PlayerWorldHealthBar"
	player_world_health_bar.custom_minimum_size = Vector2(48, 7)
	player_world_health_bar.size = Vector2(48, 7)
	player_world_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var health_background_panel := Panel.new()
	health_background_panel.name = "Background"
	health_background_panel.position = Vector2.ZERO
	health_background_panel.size = Vector2(48, 7)
	health_background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color(0.018, 0.022, 0.024, 0.84)
	health_background.border_width_left = 1
	health_background.border_width_top = 1
	health_background.border_width_right = 1
	health_background.border_width_bottom = 1
	health_background.border_color = Color(0.82, 0.86, 0.8, 0.38)
	health_background.corner_radius_top_left = 4
	health_background.corner_radius_top_right = 4
	health_background.corner_radius_bottom_left = 4
	health_background.corner_radius_bottom_right = 4
	health_background.anti_aliasing = true
	health_background_panel.add_theme_stylebox_override("panel", health_background)
	player_world_health_bar.add_child(health_background_panel)
	player_world_health_fill = Panel.new()
	player_world_health_fill.name = "Fill"
	player_world_health_fill.position = Vector2(1, 1)
	player_world_health_fill.size = Vector2(46, 5)
	player_world_health_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_health_fill_style = StyleBoxFlat.new()
	player_health_fill_style.bg_color = Color(0.28, 0.86, 0.48, 0.96)
	player_health_fill_style.corner_radius_top_left = 3
	player_health_fill_style.corner_radius_top_right = 3
	player_health_fill_style.corner_radius_bottom_left = 3
	player_health_fill_style.corner_radius_bottom_right = 3
	player_health_fill_style.anti_aliasing = true
	player_world_health_fill.add_theme_stylebox_override("panel", player_health_fill_style)
	player_world_health_bar.add_child(player_world_health_fill)
	aim_canvas.add_child(player_world_health_bar)
	roll_cooldown_indicator = ROLL_COOLDOWN_INDICATOR_SCRIPT.new() as Control
	roll_cooldown_indicator.name = "RollCooldownIndicator"
	aim_canvas.add_child(roll_cooldown_indicator)


func _update_player_combat_feedback(delta: float) -> void:
	if player_world_health_bar:
		var health_ratio := clampf(player_health / 100.0, 0.0, 1.0)
		player_world_health_fill.size.x = 46.0 * health_ratio
		player_health_fill_style.bg_color = (
			Color(0.88, 0.18, 0.12, 0.98) if health_ratio <= 0.3
			else Color(0.94, 0.66, 0.16, 0.98) if health_ratio <= 0.6
			else Color(0.28, 0.86, 0.48, 0.96)
		)
		var head_position := camera.unproject_position(player.global_position + Vector3(0, 2.15, 0))
		player_world_health_bar.position = head_position - Vector2(player_world_health_bar.size.x * 0.5, 3.0)
		player_world_health_bar.visible = not camera.is_position_behind(player.global_position)
		if roll_cooldown_indicator:
			var cooldown_is_active := roll_active or roll_cooldown_remaining > 0.0
			var cooldown_progress := 0.0 if roll_active else 1.0 - roll_cooldown_remaining / ROLL_COOLDOWN_DURATION
			roll_cooldown_indicator.position = head_position + Vector2(28.0, -8.5)
			roll_cooldown_indicator.call(
				"set_cooldown_progress",
				cooldown_progress,
				cooldown_is_active
			)

	player_hit_flash_time = maxf(0.0, player_hit_flash_time - delta)
	var hit_strength := clampf(player_hit_flash_time / 0.32, 0.0, 1.0)
	if damage_vignette_material:
		damage_vignette_material.set_shader_parameter("intensity", hit_strength * hit_strength)
	if hit_strength <= 0.0:
		return
	var strobe := 0.55 + 0.45 * absf(sin(player_hit_flash_time * 58.0))
	var survivor_alpha := survivor.modulate.a
	var flash_color := Color(1.8, 0.34, 0.18, survivor_alpha)
	survivor.modulate = survivor.modulate.lerp(flash_color, hit_strength * strobe)
	if weapon_sprite:
		var weapon_alpha := weapon_sprite.modulate.a
		weapon_sprite.modulate = weapon_sprite.modulate.lerp(
			Color(1.7, 0.3, 0.15, weapon_alpha),
			hit_strength * strobe
		)


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
		_create_loot_pickup(
			"ammo",
			_safe_map_position(_scale_map_position(AMMO_PICKUP_POSITIONS[index])),
			{"ammo_id": "762_fmj", "amount": AMMO_PICKUP_AMOUNT, "display_name": "7.62mm 탄약"}
		)


func _create_loot_pickup(loot_type: String, world_position: Vector3, data: Dictionary = {}) -> Node3D:
	var pickup := Node3D.new()
	pickup.name = "Loot_%s_%d" % [loot_type, Time.get_ticks_usec()]
	add_child(pickup)
	pickup.global_position = Vector3(world_position.x, 0.34, world_position.z)
	pickup.set_meta("base_y", pickup.position.y)
	pickup.set_meta("loot_type", loot_type)
	for key in data:
		pickup.set_meta(str(key), data[key])

	var sprite := Sprite3D.new()
	sprite.name = "LootSprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.no_depth_test = true
	sprite.render_priority = 88
	var highlight_color := Color("#f2d27a")
	match loot_type:
		"canned_food":
			sprite.texture = _get_canned_food_texture()
			sprite.pixel_size = 0.0062
			highlight_color = Color("#83c99a")
		"weapon":
			var weapon_id := str(data.get("weapon_id", "ak47"))
			sprite.texture = _get_loot_weapon_texture(weapon_id)
			sprite.pixel_size = 0.0034 if weapon_id == "ak47" else 0.006
			highlight_color = Color("#df8f55")
		_:
			sprite.texture = AMMO_762_TEXTURE
			sprite.pixel_size = 0.0032
	pickup.add_child(sprite)
	_add_loot_highlight(pickup, highlight_color, 0.92)
	ammo_pickups.append(pickup)
	return pickup


func _get_canned_food_texture() -> ImageTexture:
	if canned_food_texture != null:
		return canned_food_texture
	var image := Image.create(72, 88, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(18, 12, 36, 64), Color("#26302d"))
	image.fill_rect(Rect2i(21, 15, 30, 58), Color("#71806d"))
	image.fill_rect(Rect2i(17, 12, 38, 8), Color("#b8b8aa"))
	image.fill_rect(Rect2i(17, 68, 38, 8), Color("#8b8d84"))
	image.fill_rect(Rect2i(23, 31, 26, 28), Color("#8e3f32"))
	image.fill_rect(Rect2i(27, 36, 18, 5), Color("#e0c77c"))
	image.fill_rect(Rect2i(27, 46, 18, 8), Color("#d5a953"))
	image.fill_rect(Rect2i(24, 18, 4, 47), Color(1.0, 1.0, 0.9, 0.2))
	canned_food_texture = ImageTexture.create_from_image(image)
	return canned_food_texture


func _get_loot_weapon_texture(weapon_id: String) -> Texture2D:
	if weapon_id == "ak47":
		return AK_DROP_TEXTURE
	if weapon_id == "baseball_bat":
		return BASEBALL_BAT_TEXTURE
	if weapon_loot_texture_cache.has(weapon_id):
		return weapon_loot_texture_cache[weapon_id]
	var image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var outline := Color("#171b1c")
	match weapon_id:
		"m1911":
			image.fill_rect(Rect2i(26, 20, 77, 19), outline)
			image.fill_rect(Rect2i(31, 24, 68, 11), Color("#8f9895"))
			image.fill_rect(Rect2i(65, 35, 23, 25), outline)
			image.fill_rect(Rect2i(69, 37, 15, 19), Color("#76503d"))
		"mp5":
			image.fill_rect(Rect2i(16, 24, 101, 17), outline)
			image.fill_rect(Rect2i(22, 28, 88, 9), Color("#4d5654"))
			image.fill_rect(Rect2i(62, 38, 18, 24), outline)
			image.fill_rect(Rect2i(84, 38, 14, 17), outline)
		"double_barrel":
			image.fill_rect(Rect2i(47, 19, 75, 7), outline)
			image.fill_rect(Rect2i(47, 29, 75, 7), outline)
			image.fill_rect(Rect2i(51, 21, 68, 3), Color("#a3aaa4"))
			image.fill_rect(Rect2i(51, 31, 68, 3), Color("#7d8580"))
			image.fill_rect(Rect2i(10, 27, 43, 18), outline)
			image.fill_rect(Rect2i(15, 30, 34, 11), Color("#7d4e35"))
		_:
			return AK_DROP_TEXTURE
	var texture := ImageTexture.create_from_image(image)
	weapon_loot_texture_cache[weapon_id] = texture
	return texture


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
	if ammo_pickup_button and is_instance_valid(nearby_ammo_pickup):
		ammo_pickup_button.text = "%s 획득  [E]" % str(nearby_ammo_pickup.get_meta("display_name", "전리품"))


func _collect_nearby_ammo() -> void:
	if not is_instance_valid(nearby_ammo_pickup):
		return
	var loot_type := str(nearby_ammo_pickup.get_meta("loot_type", "ammo"))
	var amount := int(nearby_ammo_pickup.get_meta("amount", 1))
	match loot_type:
		"canned_food":
			GameState.canned_food += amount
			ammo_notice.text = "통조림 +%d   보유 %d" % [amount, GameState.canned_food]
		"weapon":
			var weapon_id := str(nearby_ammo_pickup.get_meta("weapon_id", "ak47"))
			GameState.add_weapon(weapon_id, amount)
			ammo_notice.text = "%s 보관 +%d" % [
				str(nearby_ammo_pickup.get_meta("display_name", "무기")),
				amount,
			]
		_:
			var pickup_ammo_id := str(nearby_ammo_pickup.get_meta("ammo_id", "762_fmj"))
			var updated_ammo_count := GameState.get_ammo_count(pickup_ammo_id) + amount
			GameState.set_ammo_count(pickup_ammo_id, updated_ammo_count)
			if GameState.equipped_ammo_id == pickup_ammo_id:
				reserve_ammo = updated_ammo_count
			GameState.reserve_ammo = reserve_ammo
			if ammo_pickup_chain_time <= 0.0:
				ammo_pickup_chain_total = 0
			ammo_pickup_chain_total += amount
			ammo_pickup_chain_time = 2.4
			ammo_notice.text = "+%d %s   보유 %d" % [
				amount,
				str(nearby_ammo_pickup.get_meta("display_name", "탄약")),
				updated_ammo_count,
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
	ammo_pickup_button = Button.new()
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
	equipment_panel.offset_left = -274
	equipment_panel.offset_top = -256
	equipment_panel.offset_right = -22
	equipment_panel.offset_bottom = -112
	equipment_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.025, 0.028, 0.94), Color("#83a68f")))
	equipment_panel.visible = false
	$HUD.add_child(equipment_panel)
	equipment_label = Label.new()
	equipment_label.custom_minimum_size = Vector2(250, 138)
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

	melee_button = Button.new()
	melee_button.name = "MeleeButton"
	melee_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	melee_button.offset_left = -198
	melee_button.offset_top = -104
	melee_button.offset_right = -118
	melee_button.offset_bottom = -24
	melee_button.text = "타격"
	melee_button.tooltip_text = "야구 방망이 휘두르기"
	melee_button.focus_mode = Control.FOCUS_NONE
	melee_button.add_theme_font_override("font", font)
	melee_button.add_theme_font_size_override("font_size", 16)
	melee_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.055, 0.075, 0.07, 0.92), Color("#9eb6a5"), 40))
	melee_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.075, 0.11, 0.095, 0.94), Color("#c4d6c8"), 40))
	melee_button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.12, 0.19, 0.15, 0.96), Color("#e5f0e7"), 40))
	melee_button.pressed.connect(_on_melee_button_pressed)
	melee_button.visible = DisplayServer.is_touchscreen_available()
	$HUD.add_child(melee_button)

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
	equipped_weapon_id = "ak47"
	if equipped_weapon_mods.is_empty():
		equipped_weapon_mods.append("scope_2x")
	GameState.equipped_weapon_mods.assign(equipped_weapon_mods)
	_refresh_weapon_stats()
	has_ak = true
	GameState.has_ak = true
	GameState.equipped_weapon_id = equipped_weapon_id
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
	fire_button.tooltip_text = "%s 발사" % str(weapon_stats.get("display_name", "AK-47"))
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "AK-47\n30"
	_update_equipment_ui()


func _update_firing(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if roll_active:
		return
	var firing_held := fire_button_held or mouse_fire_held
	if firing_held and has_ak and bool(weapon_stats.get("automatic", true)) and fire_cooldown <= 0.0:
		_fire_ak47()


func _on_fire_button_down() -> void:
	fire_button_held = true
	_try_fire_ak47()
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(18)


func _on_fire_button_up() -> void:
	fire_button_held = false


func _on_melee_button_pressed() -> void:
	_try_melee_attack()
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(35)


func _try_fire_ak47() -> void:
	if has_ak and not roll_active and not weapon_reloading and fire_cooldown <= 0.0:
		_fire_ak47()


func _fire_ak47() -> void:
	if weapon_reloading:
		return
	if magazine_ammo <= 0:
		return
	if _weapon_jammed():
		return
	magazine_ammo -= 1
	GameState.magazine_ammo = magazine_ammo
	fire_cooldown = float(weapon_stats.get("fire_interval", 0.12))
	var aim_direction := _get_current_fire_direction()
	_lock_aim_direction(aim_direction)
	_set_facing_from_world_direction(aim_direction)
	_update_weapon_pose()
	if weapon_sprite:
		_play_weapon_directional_animation("fire")
	var pellet_count := int(weapon_stats.get("pellet_count", 1))
	for pellet_index in pellet_count:
		var spread_angle := weapon_random.randf_range(-weapon_spread_deg, weapon_spread_deg)
		var shot_direction := aim_direction.rotated(Vector3.UP, deg_to_rad(spread_angle)).normalized()
		_spawn_weapon_projectile(shot_direction, pellet_index)
	weapon_durability = maxf(0.0, weapon_durability - float(weapon_stats.get("durability_loss", 0.06)))
	GameState.weapon_durability = weapon_durability
	weapon_spread_deg = minf(
		weapon_spread_deg + float(weapon_stats.get("spread_per_shot_deg", 1.0)),
		float(weapon_stats.get("max_spread_deg", 14.0))
	)
	_apply_weapon_recoil(aim_direction)
	player_activity_heat = minf(1.0, player_activity_heat + 0.18)
	_play_gunshot()
	if perception_system:
		var gunshot_hearing_radius := maxf(
			92.0,
			float(weapon_stats.get("sound_radius", 52.0)) * 2.8
		)
		perception_system.call(
			"emit_player_gunshot",
			player.global_position,
			gunshot_hearing_radius
		)
	_spawn_muzzle_light(aim_direction)
	_spawn_launch_fx(aim_direction)
	_update_equipment_ui()


func _spawn_weapon_projectile(direction: Vector3, pellet_index: int) -> void:
	var ammo_definition: Dictionary = WEAPON_SYSTEM.get_ammo(GameState.equipped_ammo_id)
	var damage_multiplier := float(ammo_definition.get("damage_multiplier", 1.0))
	var projectile_damage := roundi(
		(int(weapon_stats.get("damage", 24)) + (GameState.weapon_level - 1) * 6) * damage_multiplier
	)
	var penetration := maxi(
		int(weapon_stats.get("penetration_count", 0)),
		int(ammo_definition.get("penetration", 0))
	)
	var projectile := Area3D.new()
	projectile.name = "%sBullet_%d" % [equipped_weapon_id, pellet_index]
	projectile.set_script(BULLET_PROJECTILE)
	projectile.set("direction", direction)
	projectile.set("source_body", player)
	projectile.set("damage", projectile_damage)
	projectile.set("critical_chance", _get_weapon_critical_chance())
	projectile.set("critical_multiplier", 1.65)
	projectile.set("penetrations_remaining", penetration)
	projectile.position = _get_weapon_muzzle_position(direction)
	add_child(projectile)


func _get_weapon_critical_chance() -> float:
	match equipped_weapon_id:
		"m1911": return 0.16
		"mp5": return 0.08
		"double_barrel": return 0.11
		_: return 0.12


func _apply_weapon_recoil(aim_direction: Vector3) -> void:
	var recoil_kick := float(weapon_stats.get("recoil_kick", 0.7))
	if loafing:
		recoil_kick *= float(weapon_stats.get("loaf_recoil_multiplier", 1.0))
	var knockback := float(weapon_stats.get("player_knockback", 0.15)) * recoil_kick
	recoil_velocity -= aim_direction * knockback
	recoil_reticle_offset += Vector2(weapon_random.randf_range(-5.0, 5.0), -11.0) * recoil_kick


func _weapon_jammed() -> bool:
	if weapon_durability >= 35.0:
		return false
	var jam_chance := clampf((35.0 - weapon_durability) / 500.0, 0.0, 0.07)
	if weapon_random.randf() >= jam_chance:
		return false
	fire_cooldown = 0.7
	if ammo_notice:
		ammo_notice.text = "급탄 불량 · 내구도 %.1f%%" % weapon_durability
		ammo_notice.visible = true
		ammo_notice_time = 1.2
	return true


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
	# The west atlas columns have the muzzle and stock reversed. Mirror the verified
	# east-side art so all west-facing poses preserve the same weapon construction.
	weapon_sprite.flip_h = facing in ["w", "sw", "nw"]
	weapon_sprite.rotation = Vector3.ZERO
	weapon_sprite.render_priority = 0 if _weapon_renders_behind_player() else 2
	var direction := _get_current_facing_world_direction()
	weapon_sprite.position = direction * WEAPON_FLOAT_DISTANCE + Vector3(0, 0.36, 0)
	weapon_sprite.offset = _get_weapon_screen_offset()
	if not weapon_sprite.animation.begins_with("fire_"):
		_play_weapon_directional_animation("idle")


func _weapon_renders_behind_player() -> bool:
	return facing == "n" or facing == "ne" or facing == "nw"


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
	return weapon_origin + world_direction * WEAPON_MUZZLE_FORWARD_DISTANCE + Vector3(0, 0.02, 0)


func _get_mouse_world_direction() -> Vector3:
	# The same recoil offset drives both the drawn reticle and the actual ray,
	# so sustained fire cannot visually lie about the bullet center.
	var mouse_position := get_viewport().get_mouse_position() + recoil_reticle_offset
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
	var magazine_size := int(weapon_stats.get("magazine_size", 30))
	if weapon_reloading:
		return
	if reserve_ammo <= 0 or magazine_ammo >= magazine_size:
		fire_cooldown = 0.35
		return
	weapon_reloading = true
	reload_timer = float(weapon_stats.get("reload_time", 2.15))
	fire_cooldown = reload_timer
	ammo_notice.text = "%s 재장전 중 · %.1f초\n장전 중 이동·사격 제한" % [str(weapon_stats.get("display_name", "무기")), reload_timer]
	ammo_notice.visible = true
	ammo_notice_time = reload_timer
	_update_equipment_ui()


func _finish_reload() -> void:
	weapon_reloading = false
	var magazine_size := int(weapon_stats.get("magazine_size", 30))
	var needed := magazine_size - magazine_ammo
	var loaded := mini(needed, reserve_ammo)
	magazine_ammo += loaded
	reserve_ammo -= loaded
	GameState.magazine_ammo = magazine_ammo
	GameState.set_ammo_count(GameState.equipped_ammo_id, reserve_ammo)
	ammo_notice.text = "%s 재장전 완료  +%d\n탄창 %d / %d   예비 %d   총 %d" % [
		str(weapon_stats.get("display_name", "무기")),
		loaded,
		magazine_ammo,
		magazine_size,
		reserve_ammo,
		magazine_ammo + reserve_ammo,
	]
	ammo_notice.visible = true
	ammo_notice_time = 1.4
	_update_equipment_ui()


func _update_equipment_ui() -> void:
	var weapon_name := str(weapon_stats.get("display_name", "AK-47"))
	var magazine_size := int(weapon_stats.get("magazine_size", 30))
	var mod_names: Array[String] = WEAPON_SYSTEM.get_mod_names(equipped_weapon_mods)
	var ammo_name := str(WEAPON_SYSTEM.get_ammo(GameState.equipped_ammo_id).get("display_name", GameState.equipped_ammo_id))
	mod_names.push_front(ammo_name)
	var mod_text := ", ".join(mod_names) if not mod_names.is_empty() else "개조 없음"
	if equipment_label:
		equipment_label.text = "%s\n탄창 %02d / %02d · 예비 %03d\n내구도 %05.1f%% · 탄퍼짐 %.1f°\n%s%s" % [
			weapon_name,
			magazine_ammo,
			magazine_size,
			reserve_ammo,
			weapon_durability,
			weapon_spread_deg,
			mod_text,
			"\n재장전 중 %.1f초" % reload_timer if weapon_reloading else "",
		]
	var slot_label := get_node_or_null("HUD/QuickSlots/Slot1/Label") as Label
	if slot_label:
		slot_label.text = "%s\n%d | %d" % [str(weapon_stats.get("category", "소총")), magazine_ammo, reserve_ammo] if has_ak else "빈 손\n-"
	if inventory_ui:
		inventory_ui.call(
			"update_state",
			has_ak,
			magazine_ammo,
			reserve_ammo,
			weapon_name,
			magazine_size,
			weapon_durability,
			mod_names,
			GameState.canned_food,
			_get_stored_weapon_count()
		)


func _get_stored_weapon_count() -> int:
	var total := 0
	for count in GameState.weapon_inventory.values():
		total += int(count)
	return maxi(0, total - (1 if has_ak else 0))


func _is_inventory_open() -> bool:
	return inventory_ui != null and bool(inventory_ui.call("is_open"))


func _toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.call("toggle")


func _on_inventory_open_state_changed(is_open: bool) -> void:
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_HIDDEN)
	if is_open:
		fire_button_held = false
		mouse_fire_held = false
		laser_aim_held = false
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
	var world := $World as ProceduralCityMap
	for index in BASE_ENEMY_COUNT:
		var kind := "melee" if index < 2 else "pistol"
		var spawn_position := _find_distributed_enemy_position(world, index, BASE_ENEMY_COUNT)
		_spawn_enemy(kind, spawn_position, night_intensity)


func _find_distributed_enemy_position(
	world: ProceduralCityMap,
	index: int,
	total_count: int
) -> Vector3:
	var map_limit := world.get_map_limit() - 5.0
	var radius_factors := [0.1, 0.28, 0.52, 0.78]
	var base_angle := TAU * float(index) / float(maxi(1, total_count))
	for attempt in 10:
		var ring_index := (index + attempt) % radius_factors.size()
		var angle := base_angle + float(attempt) * 0.41
		var radius := map_limit * float(radius_factors[ring_index])
		var requested := Vector3(cos(angle) * radius, 0.78, sin(angle) * radius)
		var candidate := world.find_nearest_open_position(requested)
		candidate.y = 0.78
		if candidate.distance_to(player.global_position) < 14.0:
			continue
		if world.is_position_in_safe_zone(candidate):
			continue
		var overlaps_enemy := false
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(candidate) < 3.0:
				overlaps_enemy = true
				break
		if not overlaps_enemy:
			return candidate
	return _safe_map_position(Vector3(
		cos(base_angle) * map_limit * 0.55,
		0.78,
		sin(base_angle) * map_limit * 0.55
	))


func _spawn_enemy(kind: String, spawn_position: Vector3, threat: float) -> CharacterBody3D:
	var enemy_weapon_id := "baseball_bat"
	if kind != "melee":
		var ranged_loadout_cycle := ["m1911", "mp5", "ak47", "double_barrel"]
		enemy_weapon_id = ranged_loadout_cycle[enemy_ranged_spawn_serial % ranged_loadout_cycle.size()]
		enemy_ranged_spawn_serial += 1
	var enemy := CharacterBody3D.new()
	enemy.name = "%s_%s_Enemy%d" % [kind.capitalize(), enemy_weapon_id, enemy_spawn_serial]
	enemy_spawn_serial += 1
	enemy.set_script(ENEMY_SCRIPT)
	enemy.add_to_group("sound_source")
	enemy.position = spawn_position
	enemy.call("configure", kind, player, {}, threat, enemy_weapon_id)
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	if enemy.has_signal("reinforcement_called"):
		enemy.connect("reinforcement_called", _on_enemy_reinforcement_called)
	enemies.append(enemy)
	return enemy


func _on_enemy_died(enemy: CharacterBody3D) -> void:
	if enemy == active_reinforcement_caller:
		active_reinforcement_caller = null
		sustained_combat_time = REINFORCEMENT_CALL_TRIGGER_TIME * 0.45
	_spawn_enemy_loot(enemy)
	enemies.erase(enemy)
	reinforcement_timer = minf(reinforcement_timer, 2.5)


func _spawn_enemy_loot(enemy: CharacterBody3D) -> Node3D:
	var drop_position := enemy.global_position
	var enemy_weapon_id := str(enemy.get("weapon_id"))
	var roll := spawn_random.randf()
	if roll < 0.5:
		return _create_loot_pickup(
			"ammo",
			drop_position,
			_get_enemy_ammo_drop(enemy_weapon_id)
		)
	if roll < 0.85:
		return _create_loot_pickup(
			"canned_food",
			drop_position,
			{"amount": 2 if spawn_random.randf() < 0.12 else 1, "display_name": "통조림"}
		)
	return _create_loot_pickup(
		"weapon",
		drop_position,
		{
			"amount": 1,
			"weapon_id": enemy_weapon_id,
			"display_name": _get_loot_weapon_name(enemy_weapon_id),
		}
	)


func _get_enemy_ammo_drop(enemy_weapon_id: String) -> Dictionary:
	match enemy_weapon_id:
		"m1911":
			return {"ammo_id": "45_fmj", "amount": spawn_random.randi_range(7, 14), "display_name": ".45 ACP 탄약"}
		"mp5":
			return {"ammo_id": "9mm_fmj", "amount": spawn_random.randi_range(15, 30), "display_name": "9mm 탄약"}
		"double_barrel":
			return {"ammo_id": "12g_buckshot", "amount": spawn_random.randi_range(4, 8), "display_name": "12게이지 탄약"}
		_:
			return {"ammo_id": "762_fmj", "amount": spawn_random.randi_range(12, 24), "display_name": "7.62mm 탄약"}


func _get_loot_weapon_name(weapon_id: String) -> String:
	match weapon_id:
		"m1911": return "M1911"
		"mp5": return "MP5"
		"double_barrel": return "더블배럴 산탄총"
		"baseball_bat": return "야구방망이"
		_: return "AK-47"


func _update_player_activity_heat(delta: float) -> void:
	var moving_fast := player.velocity.length_squared() > MOVE_SPEED * MOVE_SPEED * 0.62
	var making_noise := mouse_fire_held or fire_button_held or roll_active
	if moving_fast or making_noise:
		player_activity_heat = minf(1.0, player_activity_heat + delta * 0.07)
	else:
		player_activity_heat = maxf(0.0, player_activity_heat - delta * 0.1)


func _update_reinforcement_call(delta: float, effective_threat: float) -> void:
	reinforcement_call_cooldown = maxf(0.0, reinforcement_call_cooldown - delta)
	if active_reinforcement_caller != null and not is_instance_valid(active_reinforcement_caller):
		active_reinforcement_caller = null
	elif active_reinforcement_caller != null and not bool(active_reinforcement_caller.get("reinforcement_call_active")):
		active_reinforcement_caller = null
		sustained_combat_time = REINFORCEMENT_CALL_TRIGGER_TIME * 0.45
	var combat_active := false
	for enemy in enemies:
		if not is_instance_valid(enemy) or bool(enemy.get("dying")):
			continue
		if bool(enemy.get("visual_contact_confirmed")) or (
			bool(enemy.get("alerted")) and enemy.global_position.distance_to(player.global_position) < 22.0
		):
			combat_active = true
			break
	if combat_active:
		sustained_combat_time += delta
	else:
		sustained_combat_time = maxf(0.0, sustained_combat_time - delta * 2.0)
	if active_reinforcement_caller != null or reinforcement_call_cooldown > 0.0:
		return
	if sustained_combat_time < REINFORCEMENT_CALL_TRIGGER_TIME:
		return
	var caller: CharacterBody3D
	var best_score := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or bool(enemy.get("dying")) or not bool(enemy.get("alerted")):
			continue
		if not enemy.has_method("start_reinforcement_call"):
			continue
		var score := enemy.global_position.distance_to(player.global_position)
		if str(enemy.get("enemy_kind")) != "melee":
			score -= 6.0
		if score < best_score:
			best_score = score
			caller = enemy
	if caller != null and bool(caller.call("start_reinforcement_call", REINFORCEMENT_CALL_DURATION)):
		active_reinforcement_caller = caller
		sustained_combat_time = 0.0


func _on_enemy_reinforcement_called(caller: CharacterBody3D) -> void:
	if caller != active_reinforcement_caller:
		return
	active_reinforcement_caller = null
	reinforcement_call_cooldown = REINFORCEMENT_CALL_COOLDOWN
	_spawn_called_reinforcements()


func _spawn_called_reinforcements() -> void:
	var effective_threat := clampf(maxf(0.58, night_intensity + player_activity_heat * 0.42), 0.0, 1.0)
	var reinforcement_count := 6 + roundi(night_intensity * 4.0)
	for index in reinforcement_count:
		var spawn_position := _find_reinforcement_position()
		if spawn_position == Vector3.INF:
			continue
		var kind := "pistol" if index < reinforcement_count - 2 or spawn_random.randf() < 0.82 else "melee"
		var enemy := _spawn_enemy(kind, spawn_position, effective_threat)
		enemy.call("hear_sound", player.global_position, 1.0)
	player_activity_heat = 1.0


func _update_enemy_pressure(delta: float) -> void:
	var effective_threat := clampf(night_intensity + player_activity_heat * 0.42, 0.0, 1.0)
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			enemies.remove_at(index)
			continue
		enemy.call("set_threat_level", effective_threat)
	_update_reinforcement_call(delta, effective_threat)
	var target_count := (
		BASE_ENEMY_COUNT
		+ roundi(night_intensity * float(MAX_NIGHT_ENEMY_COUNT - BASE_ENEMY_COUNT))
		+ roundi(player_activity_heat * 6.0)
	)
	if enemies.size() >= target_count:
		reinforcement_timer = minf(reinforcement_timer, 3.0)
		return

	reinforcement_timer -= delta
	if reinforcement_timer > 0.0:
		return
	var spawn_position := _find_reinforcement_position()
	if spawn_position != Vector3.INF:
		var pistol_chance := lerpf(0.72, 0.88, effective_threat)
		var kind := "pistol" if spawn_random.randf() < pistol_chance else "melee"
		_spawn_enemy(kind, spawn_position, effective_threat)
	reinforcement_timer = lerpf(15.0, 2.8, effective_threat)


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
	float boundary = smoothstep(inner_radius - 5.0, inner_radius + 8.0, distance_from_player)
		* (1.0 - smoothstep(inner_radius + 8.0, inner_radius + 24.0, distance_from_player));
	fog_alpha = max(fog_alpha, boundary * 0.27);
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
	var outer_radius := lerpf(410.0, 195.0, night_intensity)
	var edge_darkness := lerpf(0.82, 0.97, night_intensity)
	visibility_material.set_shader_parameter("viewport_size", viewport_size)
	visibility_material.set_shader_parameter("player_screen", camera.unproject_position(player.global_position))
	visibility_material.set_shader_parameter("inner_radius", inner_radius)
	visibility_material.set_shader_parameter("outer_radius", outer_radius)
	visibility_material.set_shader_parameter("darkness", edge_darkness)


func _update_enemy_visibility() -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var fully_visible_radius := lerpf(330.0, 125.0, night_intensity)
	var reveal_radius := fully_visible_radius + lerpf(52.0, 34.0, night_intensity)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var visibility_factor := _enemy_player_visibility_factor(
			enemy,
			fully_visible_radius,
			reveal_radius
		)
		enemy.visible = visibility_factor > 0.01
		if enemy.has_method("set_player_visibility_factor"):
			enemy.call("set_player_visibility_factor", visibility_factor)


func _enemy_player_visibility_factor(
	enemy: Node3D,
	fully_visible_radius: float,
	reveal_radius: float
) -> float:
	if not is_instance_valid(enemy) or camera.is_position_behind(enemy.global_position):
		return 0.0
	var viewport_rect := get_viewport().get_visible_rect()
	var enemy_screen := camera.unproject_position(enemy.global_position + Vector3(0, 0.45, 0))
	if not viewport_rect.grow(24.0).has_point(enemy_screen):
		return 0.0
	var player_screen := camera.unproject_position(player.global_position + Vector3(0, 0.22, 0))
	var screen_distance := player_screen.distance_to(enemy_screen)
	if screen_distance > reveal_radius:
		return 0.0
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3(0, 0.42, 0),
		enemy.global_position + Vector3(0, 0.42, 0),
		1
	)
	query.exclude = [player.get_rid()]
	if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return 0.0
	if screen_distance <= fully_visible_radius:
		return 1.0
	return 1.0 - smoothstep(fully_visible_radius, reveal_radius, screen_distance)


func _enemy_is_in_player_vision(enemy: Node3D, visible_radius: float) -> bool:
	if not is_instance_valid(enemy) or camera.is_position_behind(enemy.global_position):
		return false
	var viewport_rect := get_viewport().get_visible_rect()
	var enemy_screen := camera.unproject_position(enemy.global_position + Vector3(0, 0.45, 0))
	if not viewport_rect.grow(24.0).has_point(enemy_screen):
		return false
	var player_screen := camera.unproject_position(player.global_position + Vector3(0, 0.22, 0))
	if player_screen.distance_to(enemy_screen) > visible_radius:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3(0, 0.42, 0),
		enemy.global_position + Vector3(0, 0.42, 0),
		1
	)
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _install_perception_system() -> void:
	perception_system = PERCEPTION_SYSTEM_SCRIPT.new() as CanvasLayer
	perception_system.call("setup", player, camera)
	add_child(perception_system)


func take_damage(amount: int) -> void:
	if amount <= 0 or player_health <= 0:
		return
	player_health = maxi(0, player_health - amount)
	GameState.player_health = player_health
	player_hit_flash_time = 0.32
	player_hit_stun_time = maxf(player_hit_stun_time, 0.18)
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


func take_hit(amount: int, hit_direction: Vector3) -> void:
	take_damage(amount)
	hit_direction.y = 0.0
	if player_health > 0 and hit_direction.length_squared() > 0.01:
		recoil_velocity += hit_direction.normalized() * 1.35
		player_hit_stun_time = maxf(player_hit_stun_time, 0.24)


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
		overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(building.global_position)
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
	companion_overlay = Sprite2D.new()
	companion_overlay.name = "CompanionOverlay"
	companion_overlay.centered = true
	companion_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	building_canvas.add_child(companion_overlay)
	weapon_overlay = Sprite2D.new()
	weapon_overlay.name = "WeaponOverlay"
	weapon_overlay.centered = true
	weapon_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	building_canvas.add_child(weapon_overlay)
	melee_bat_overlay = Sprite2D.new()
	melee_bat_overlay.name = "MeleeBatOverlay"
	melee_bat_overlay.texture = BASEBALL_BAT_TEXTURE
	melee_bat_overlay.centered = true
	melee_bat_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	melee_bat_overlay.visible = false
	building_canvas.add_child(melee_bat_overlay)
	survivor.visible = false
	companion_sprite.visible = false
	weapon_sprite.visible = false
	_update_building_overlays()


func _update_building_overlays() -> void:
	if building_canvas == null:
		return
	var viewport_height := get_viewport().get_visible_rect().size.y
	var screen_scale := viewport_height / camera.size
	var player_depth := OVERLAY_DEPTH_SORT.world_depth(player.global_position)
	for index in range(roll_afterimages.size() - 1, -1, -1):
		var ghost := roll_afterimages[index]
		if not is_instance_valid(ghost):
			roll_afterimages.remove_at(index)
			continue
		var ghost_world_position: Vector3 = ghost.get_meta("world_position", player.global_position)
		ghost.position = camera.unproject_position(ghost_world_position)
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
		var overlay_color := source.modulate
		if building.has_meta("overlay_focus_local"):
			var focus_local: Vector3 = building.get_meta("overlay_focus_local")
			var focus_screen := camera.unproject_position(building.to_global(focus_local))
			var fade_pixels: Vector2 = building.get_meta(
				"overlay_focus_fade_pixels",
				Vector2(32.0, 150.0)
			)
			var focus_alpha := OVERLAY_DEPTH_SORT.focused_overlay_alpha(
				focus_screen,
				get_viewport().get_visible_rect().size,
				fade_pixels.x,
				fade_pixels.y
			)
			overlay_color.a *= focus_alpha
			overlay.visible = focus_alpha > 0.005
		else:
			overlay.visible = true
		overlay.modulate = overlay_color
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
		overlay.flip_h = source.flip_h
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
	var companion_texture := companion_sprite.sprite_frames.get_frame_texture(
		companion_sprite.animation,
		companion_sprite.frame
	)
	if companion_texture:
		companion_overlay.texture = companion_texture
	companion_overlay.position = camera.unproject_position(companion_sprite.global_position)
	companion_overlay.scale = Vector2.ONE * companion_sprite.pixel_size * screen_scale
	companion_overlay.offset = companion_sprite.offset
	companion_overlay.flip_h = companion_sprite.flip_h
	companion_overlay.modulate = companion_sprite.modulate
	companion_overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(companion.global_position)
	if has_ak and not roll_active and weapon_sprite and weapon_sprite.sprite_frames:
		var weapon_texture := weapon_sprite.sprite_frames.get_frame_texture(weapon_sprite.animation, weapon_sprite.frame)
		if weapon_texture:
			weapon_overlay.texture = weapon_texture
		weapon_overlay.visible = true
		weapon_overlay.position = camera.unproject_position(weapon_sprite.global_position)
		weapon_overlay.scale = Vector2.ONE * weapon_sprite.pixel_size * screen_scale
		weapon_overlay.offset = weapon_sprite.offset
		weapon_overlay.flip_h = weapon_sprite.flip_h
		weapon_overlay.rotation = weapon_sprite.rotation.z
		weapon_overlay.modulate = weapon_sprite.modulate
		weapon_overlay.z_index = player_depth - 1 if _weapon_renders_behind_player() else player_depth + 1
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


func _setup_tactical_map(world: ProceduralCityMap) -> void:
	var map_layer := CanvasLayer.new()
	map_layer.name = "TacticalMapLayer"
	map_layer.layer = 30
	add_child(map_layer)
	tactical_map = TACTICAL_MAP_SCRIPT.new() as Control
	map_layer.add_child(tactical_map)
	tactical_map.call("setup", world, player, extraction_position)


func _is_tactical_map_open() -> bool:
	return is_instance_valid(tactical_map) and bool(tactical_map.call("is_open"))


func _setup_extraction_site(world: ProceduralCityMap) -> void:
	extraction_position = world.get_extraction_position()
	extraction_site = Node3D.new()
	extraction_site.name = "SewerExtraction"
	extraction_site.position = extraction_position
	add_child(extraction_site)

	var sprite := Sprite3D.new()
	sprite.name = "SewerEntrance"
	sprite.texture = SEWER_EXIT_TEXTURE
	sprite.position.y = 0.16
	sprite.pixel_size = 0.0009
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extraction_site.add_child(sprite)

	var ring_material := StandardMaterial3D.new()
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(0.95, 0.72, 0.18, 0.42)
	ring_material.emission_enabled = true
	ring_material.emission = Color("#d9a928")
	ring_material.emission_energy_multiplier = 2.5
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.35
	ring_mesh.outer_radius = 1.48
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 32
	ring_mesh.material = ring_material
	var ring := MeshInstance3D.new()
	ring.name = "ExtractionRing"
	ring.position.y = 0.06
	ring.mesh = ring_mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extraction_site.add_child(ring)

	var prompt_panel := PanelContainer.new()
	prompt_panel.name = "ExtractionPrompt"
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.position = Vector2(-150, -112)
	prompt_panel.size = Vector2(300, 52)
	prompt_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.026, 0.026, 0.94), Color("#d7b253"), 5))
	var prompt_label := Label.new()
	prompt_label.text = "E  하수구로 탈출"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_override("font", preload("res://assets/fonts/Pretendard-Regular.otf"))
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color("#f0df9e"))
	prompt_panel.add_child(prompt_label)
	$HUD.add_child(prompt_panel)
	extraction_prompt = prompt_panel
	extraction_prompt.visible = false

	extraction_fade = ColorRect.new()
	extraction_fade.name = "ExtractionFade"
	extraction_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	extraction_fade.color = Color(0, 0, 0, 0)
	extraction_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extraction_fade.z_index = 500
	$HUD.add_child(extraction_fade)
	extraction_success_label = Label.new()
	extraction_success_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	extraction_success_label.text = "탈출 성공"
	extraction_success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	extraction_success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	extraction_success_label.add_theme_font_override("font", preload("res://assets/fonts/Pretendard-Regular.otf"))
	extraction_success_label.add_theme_font_size_override("font_size", 44)
	extraction_success_label.add_theme_color_override("font_color", Color("#e6dfc4"))
	extraction_success_label.modulate.a = 0.0
	extraction_success_label.z_index = 501
	$HUD.add_child(extraction_success_label)


func _update_extraction_prompt() -> void:
	if not is_instance_valid(extraction_prompt):
		return
	var close_enough := player.global_position.distance_to(extraction_position) <= 2.8
	extraction_prompt.visible = close_enough and not extraction_transition_active and not _is_tactical_map_open()


func _begin_extraction() -> void:
	if extraction_transition_active:
		return
	extraction_transition_active = true
	extraction_prompt.visible = false
	_save_run_state()
	var tween := create_tween()
	tween.tween_property(extraction_fade, "color:a", 1.0, 0.65)
	tween.tween_property(extraction_success_label, "modulate:a", 1.0, 0.32)
	tween.tween_interval(0.9)
	tween.tween_callback(func() -> void:
		GameState.returning_from_shelter = false
		get_tree().change_scene_to_file("res://scenes/shelter_interior.tscn")
	)


func _setup_weather_effects() -> void:
	var weather_layer := CanvasLayer.new()
	weather_layer.name = "WeatherFlashLayer"
	weather_layer.layer = 20
	add_child(weather_layer)
	lightning_overlay = ColorRect.new()
	lightning_overlay.name = "LightningFlash"
	lightning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_overlay.color = Color(0.72, 0.84, 1.0, 0.0)
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_layer.add_child(lightning_overlay)
	lightning_timer = spawn_random.randf_range(35.0, 75.0)


func _update_lightning(delta: float) -> void:
	lightning_timer -= delta
	if lightning_timer > 0.0:
		return
	lightning_timer = spawn_random.randf_range(45.0, 100.0)
	var tween := create_tween()
	tween.tween_property(lightning_overlay, "color:a", 0.14, 0.055)
	tween.tween_property(lightning_overlay, "color:a", 0.018, 0.12)
	tween.tween_interval(0.08)
	tween.tween_property(lightning_overlay, "color:a", 0.075, 0.04)
	tween.tween_property(lightning_overlay, "color:a", 0.0, 0.32)


func _save_run_state() -> void:
	GameState.player_health = player_health
	GameState.magazine_ammo = magazine_ammo
	GameState.reserve_ammo = reserve_ammo
	GameState.has_ak = has_ak
	GameState.equipped_weapon_id = equipped_weapon_id
	GameState.weapon_durability = weapon_durability
	GameState.equipped_weapon_mods.assign(equipped_weapon_mods)


func _on_shelter_portal_entered() -> void:
	_save_run_state()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/shelter_interior.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
		if key == KEY_TAB and key_event.pressed:
			if _is_inventory_open():
				_toggle_inventory()
			if is_instance_valid(tactical_map):
				tactical_map.call("toggle")
			get_viewport().set_input_as_handled()
			return
		if key == KEY_I and key_event.pressed:
			if _is_tactical_map_open():
				tactical_map.call("close")
			_toggle_inventory()
			return
		if _is_inventory_open() or _is_tactical_map_open() or extraction_transition_active:
			return
		if key == KEY_E:
			if key_event.pressed and player.global_position.distance_to(extraction_position) <= 2.8:
				_begin_extraction()
				pickup_keyboard_held = false
			elif key_event.pressed and is_instance_valid(nearby_ammo_pickup):
				_collect_nearby_ammo()
				pickup_keyboard_held = false
			else:
				pickup_keyboard_held = key_event.pressed
		elif key == KEY_SPACE and key_event.pressed:
			_try_start_roll()
		elif key == KEY_R and key_event.pressed and has_ak:
			_reload_ak47()
		elif key == KEY_N and key_event.pressed:
			_save_run_state()
			GameState.randomize_map()
			get_tree().reload_current_scene()
	elif event is InputEventMouseButton:
		if _is_inventory_open() or _is_tactical_map_open() or extraction_transition_active:
			return
		var mouse_event := event as InputEventMouseButton
		if fire_button and fire_button.visible and fire_button.get_global_rect().has_point(mouse_event.position):
			return
		_handle_combat_mouse_button(mouse_event)
		get_viewport().set_input_as_handled()
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


func _handle_combat_mouse_button(mouse_event: InputEventMouseButton) -> void:
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_event.pressed:
			if magazine_ammo <= 0:
				mouse_fire_held = false
				_try_melee_attack()
			elif laser_aim_held:
				mouse_fire_held = true
				_try_fire_ak47()
			else:
				mouse_fire_held = false
				_try_melee_attack()
		else:
			mouse_fire_held = false
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		laser_aim_held = mouse_event.pressed
		if not mouse_event.pressed:
			mouse_fire_held = false
		if mouse_event.pressed and has_ak:
			_lock_aim_direction(_get_mouse_world_direction())


func _unhandled_input(_event: InputEvent) -> void:
	pass


func _exit_tree() -> void:
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
