extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const MOVE_SPEED := 5.2
const BASE_CAMERA_SIZE := 28.0
const CAMERA_DIAGONAL_OFFSET := 13.5
const OCCLUSION_LATERAL_LIMIT := 5.1
const OCCLUSION_DEPTH_LIMIT := 14.0
const SILHOUETTE_COLOR := Color("#26343b")
const STRUCTURE_REVEAL_RADIUS := 9.5
const STRUCTURE_REVEAL_HALF_ANGLE_DEG := 52.5
const STRUCTURE_REVEAL_BUILDING_ALPHA := 0.46
const STRUCTURE_REVEAL_VEHICLE_ALPHA := 0.58
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const CAT_ANIMATION_ROOT := "res://assets/characters/cat_8way"
const CAT_ROLL_ANIMATION_ROOT := "res://assets/characters/cat_roll"
const COWERING_RESIDENT_TEXTURE_PATHS := {
	"n": "res://assets/characters/cowering_resident/up_action-frame-0.png",
	"ne": "res://assets/characters/cowering_resident/up_right_action-frame-0.png",
	"e": "res://assets/characters/cowering_resident/right_action-frame-3.png",
	"se": "res://assets/characters/cowering_resident/down_right_action-frame-1.png",
	"s": "res://assets/characters/cowering_resident/down_action-frame-2.png",
	"sw": "res://assets/characters/cowering_resident/down_left_action-frame-2.png",
	"w": "res://assets/characters/cowering_resident/left_action-frame-3.png",
	"nw": "res://assets/characters/cowering_resident/up_left_action-frame-0.png",
}
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
const ROLL_STAMINA_MAX := 100.0
const ROLL_STAMINA_COST := 35.0
const ROLL_STAMINA_RECOVERY_PER_SECOND := 28.0
const ROLL_START_SPEED := 36.0
const ROLL_END_SPEED := 4.4
const ROLL_AFTERIMAGE_INTERVAL := 0.055
const WEAPON_FRAME_SIZE := Vector2(192, 192)
const WEAPON_VISUAL_PIXEL_SIZE := 0.0018
const WEAPON_FLOAT_DISTANCE := 0.72
const WEAPON_MUZZLE_FORWARD_DISTANCE := 0.64
const AK_DROP_TEXTURE := preload("res://assets/weapons/ak47_drop.png")
const AK_DIRECTIONAL_TEXTURE := preload("res://assets/weapons/ak47_directional.png")
const AMMO_762_TEXTURE := preload("res://assets/items/ammo_762.png")
const CHURU_TEXTURE := preload("res://assets/items/churu_rare.png")
const BASEBALL_BAT_TEXTURE := preload("res://assets/weapons/baseball_bat_temp.png")
const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const INVENTORY_UI_SCRIPT := preload("res://scripts/inventory_ui.gd")
const PERCEPTION_SYSTEM_SCRIPT := preload("res://scripts/perception_system.gd")
const OVERLAY_DEPTH_SORT := preload("res://scripts/overlay_depth_sort.gd")
const WEAPON_SYSTEM := preload("res://scripts/weapon_system.gd")
const WEAPON_VISUAL_CATALOG := preload("res://scripts/weapon_visual_catalog.gd")
const AIM_RETICLE_SCRIPT := preload("res://scripts/aim_reticle.gd")
const ROLL_COOLDOWN_INDICATOR_SCRIPT := preload("res://scripts/roll_cooldown_indicator.gd")
const TACTICAL_MAP_SCRIPT := preload("res://scripts/tactical_map.gd")
const RESCUED_CAT_FOLLOWER_SCRIPT := preload("res://scripts/rescued_cat_follower.gd")
const RUBBER_GASKET_TEXTURE := preload("res://assets/items/mod_components/rubber_gasket.png")
const SCOPE_LENS_TEXTURE := preload("res://assets/items/mod_components/scope_lens.png")
const MAGAZINE_SPRING_TEXTURE := preload("res://assets/items/mod_components/magazine_spring.png")
const BROKEN_SENTRY_TEXTURE := preload("res://assets/props/broken_sentry_salvage.png")
const START_WITH_COMPANION := false
const AK_PICKUP_POSITION := Vector3(1.15, 0.32, 0.7)
const PICKUP_DISTANCE := 1.75
const PICKUP_HOLD_DURATION := 0.9
const AIM_HOLD_DURATION := 0.55
const AMMO_PICKUP_AMOUNT := 30
const MAP_CONTENT_SCALE := ProceduralCityMap.WORLD_SCALE
const SECONDS_PER_GAME_HOUR := 36.0
const NIGHT_START_HOUR := 19.0
const DEEP_NIGHT_HOUR := 22.0
const BASE_ENEMY_COUNT := 17
const MAX_NIGHT_ENEMY_COUNT := 34
const BASE_FIELD_LOOT_COUNT := 16
const MELEE_ATTACK_COOLDOWN := 0.72
const MELEE_ATTACK_RANGE := 2.2
const MELEE_ATTACK_DAMAGE := 38
const REINFORCEMENT_CALL_TRIGGER_TIME := 7.0
const REINFORCEMENT_CALL_DURATION := 4.6
const REINFORCEMENT_CALL_COOLDOWN := 24.0
const FIELD_INTERACTION_DISTANCE := 2.8
const SALVAGE_HOLD_DURATION := 2.4
const RESCUE_HOLD_DURATION := 1.8
const FATIGUE_MAX := 100.0
const FATIGUE_MOVING_RATE := 0.055
const FATIGUE_IDLE_RATE := 0.0
const FATIGUE_SHOT_GAIN := 0.28
const FATIGUE_MELEE_GAIN := 1.1
const FATIGUE_RELOAD_GAIN := 0.8
const FATIGUE_LOOT_GAIN := 0.85
const FATIGUE_SALVAGE_GAIN := 3.5
const FATIGUE_RESCUE_GAIN := 2.2
const FATIGUE_ROLL_GAIN := 0.45
const FATIGUE_DAMAGE_PER_POINT := 0.045
const FATIGUE_SPEED_MIN := 0.58
const ESCORT_SPEED_PENALTY := 0.07
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
var roll_audio_player: AudioStreamPlayer3D
var bgm_player: AudioStreamPlayer
var building_canvas: CanvasLayer
var building_overlays := {}
var vehicle_overlays := {}
var survivor_overlay: Sprite2D
var companion_overlay: Sprite2D
var companion_active := START_WITH_COMPANION
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
var cowering_resident_texture_cache: Dictionary = {}
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
var reload_reticle_indicator: Control
var player_hit_flash_time := 0.0
var player_hit_stun_time := 0.0
var player_death_sequence_active := false
var roll_active := false
var roll_elapsed := 0.0
var roll_stamina := ROLL_STAMINA_MAX
var roll_afterimage_timer := 0.0
var roll_direction := Vector3.ZERO
var scope_camera_offset := Vector3.ZERO
var weapon_random := RandomNumberGenerator.new()
var tactical_map: Control
var extraction_site: Node3D
var extraction_position := Vector3.ZERO
var extraction_sites: Array[Node3D] = []
var extraction_prompt: Control
var extraction_transition_active := false
var extraction_fade: ColorRect
var extraction_success_label: Label
var lightning_overlay: ColorRect
var lightning_timer := 12.0
var field_interactions: Array[Node3D] = []
var nearby_field_interaction: Node3D
var field_interaction_panel: PanelContainer
var field_interaction_button: Button
var field_interaction_progress: ProgressBar
var field_interaction_keyboard_held := false
var field_interaction_touch_held := false
var field_interaction_hold_time := 0.0
var rescued_followers: Array[CharacterBody3D] = []
var fatigue := 0.0
var fatigue_panel: PanelContainer
var fatigue_bar: ProgressBar
var fatigue_label: Label
var run_started_msec := 0
var run_kills := 0
var run_damage_dealt := 0
var raid_start_snapshot := {}
var game_over_canvas: CanvasLayer
var game_over_fade: ColorRect
var game_over_label: Label
var raid_zone_data: Dictionary = {}


func _ready() -> void:
	run_started_msec = Time.get_ticks_msec()
	raid_zone_data = GameState.get_raid_zone()
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
	fatigue = clampf(GameState.fatigue, 0.0, FATIGUE_MAX)
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
	if not companion_active:
		_deactivate_companion()
	touch_stick.visible = DisplayServer.is_touchscreen_available()
	_build_sprite_frames()
	_setup_weapon_layer()
	_setup_melee_weapon()
	_setup_aim_feedback()
	_setup_player_combat_feedback()
	_setup_game_over_feedback()
	_setup_weather_effects()
	_spawn_ammo_pickups()
	_build_weapon_hud()
	_build_gunshot_audio()
	_build_roll_audio()
	_build_bgm_audio()
	_spawn_enemies()
	_setup_building_overlays()
	_build_day_night_tint()
	_build_visibility_fog()
	_install_perception_system()
	_update_day_night(0.0)
	_update_enemy_visibility()
	_set_facing("s")
	var world := $World as ProceduralCityMap
	if GameState.returning_from_shelter:
		player.position = world.get_shelter_exit_position()
		GameState.returning_from_shelter = false
	else:
		player.position = world.find_nearest_open_position(player.position)
	_setup_extraction_site(world)
	_setup_field_objectives(world)
	_setup_tactical_map(world)
	var health_bar := get_node_or_null("HUD/TopLeft/Margin/VBox/Health") as ProgressBar
	if health_bar:
		health_bar.value = player_health
	_capture_raid_start_snapshot()
	_equip_ak47()
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func activate_companion() -> void:
	companion_active = true
	if companion == null:
		return
	companion.visible = true
	companion.process_mode = Node.PROCESS_MODE_INHERIT
	companion.collision_layer = 16
	companion.collision_mask = 1
	companion.set_physics_process(true)
	if companion.has_method("set_active"):
		companion.call("set_active", true)
	if companion_overlay:
		companion_overlay.visible = true


func _deactivate_companion() -> void:
	if companion == null:
		return
	companion.visible = false
	companion.process_mode = Node.PROCESS_MODE_DISABLED
	companion.collision_layer = 0
	companion.collision_mask = 0
	companion.velocity = Vector3.ZERO
	if companion.has_method("set_active"):
		companion.call("set_active", false)
	if companion_overlay:
		companion_overlay.visible = false


func _physics_process(delta: float) -> void:
	if player_death_sequence_active:
		_update_building_overlays()
		_update_visibility_fog()
		_update_enemy_visibility()
		return
	_update_day_night(delta)
	_update_player_activity_heat(delta)
	_update_lightning(delta)
	_update_enemy_pressure(delta)
	melee_attack_cooldown = maxf(0.0, melee_attack_cooldown - delta)
	aim_hold_time = maxf(0.0, aim_hold_time - delta)
	player_hit_stun_time = maxf(0.0, player_hit_stun_time - delta)
	if not roll_active:
		roll_stamina = minf(
			ROLL_STAMINA_MAX,
			roll_stamina + ROLL_STAMINA_RECOVERY_PER_SECOND * delta
		)
	if (laser_aim_held or mouse_fire_held) and has_ak and _uses_mouse_aim():
		_lock_aim_direction(_get_mouse_world_direction())
	_update_scope_camera(delta)
	var aim_is_locked := (has_ak and (fire_button_held or mouse_fire_held or laser_aim_held)) or aim_hold_time > 0.0
	if melee_button:
		melee_button.disabled = melee_attack_cooldown > 0.0
	_update_field_interactions(delta)
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
	_update_fatigue(delta, input_vector.length_squared() > 0.01)
	loafing = not DisplayServer.is_touchscreen_available() and Input.is_key_pressed(KEY_C)
	_update_weapon_ballistics(delta, input_vector.length_squared() > 0.01)

	var world_direction := Vector3(input_vector.x + input_vector.y, 0, -input_vector.x + input_vector.y)
	if roll_active:
		_update_roll(delta)
	elif world_direction.length_squared() > 0.01:
		world_direction = world_direction.normalized()
		var movement_speed := MOVE_SPEED * (0.38 if loafing else 1.0)
		movement_speed *= _get_fatigue_speed_multiplier()
		movement_speed *= _get_escort_speed_multiplier()
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
	player.set_meta("tactical_heading", _get_current_facing_world_direction())

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
		if perception_system.has_method("set_aim_expanded"):
			perception_system.call("set_aim_expanded", laser_aim_held)
	$CameraRig/Rain.position.y = 8.0
	var city_world := $World as ProceduralCityMap
	var sector_label := city_world.get_sector_label(player.global_position)
	var nearest_exit_distance := INF
	for extraction_site in extraction_sites:
		if is_instance_valid(extraction_site):
			nearest_exit_distance = minf(nearest_exit_distance, player.global_position.distance_to(extraction_site.global_position))
	location_label.text = "%s  ·  %s  ·  탈출 %.0fm" % [
		str(raid_zone_data.get("name", "종로 외곽")),
		sector_label,
		nearest_exit_distance if nearest_exit_distance < INF else 0.0,
	]


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
	if roll_active or roll_stamina < ROLL_STAMINA_COST or player_health <= 0:
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
	roll_stamina = maxf(0.0, roll_stamina - ROLL_STAMINA_COST)
	_add_fatigue(FATIGUE_ROLL_GAIN)
	player_activity_heat = minf(1.0, player_activity_heat + 0.12)
	roll_elapsed = 0.0
	roll_afterimage_timer = 0.0
	recoil_velocity = Vector3.ZERO
	_set_motion_state("roll")
	state_label.text = "회피 구르기"
	_play_roll_sound()
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
	weapon_sprite.name = "EquippedWeapon"
	weapon_sprite.position = Vector3(0, 0.32, 0)
	weapon_sprite.pixel_size = WEAPON_VISUAL_PIXEL_SIZE
	weapon_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	weapon_sprite.shaded = false
	weapon_sprite.transparent = true
	weapon_sprite.no_depth_test = true
	weapon_sprite.offset = Vector2(0, -28)
	weapon_sprite.visible = false
	player.add_child(weapon_sprite)

	_rebuild_player_weapon_frames()
	weapon_sprite.animation_finished.connect(_on_weapon_animation_finished)


func _rebuild_player_weapon_frames() -> void:
	var catalog_texture := WEAPON_VISUAL_CATALOG.get_weapon_texture(equipped_weapon_id)
	weapon_sprite.pixel_size = WEAPON_VISUAL_CATALOG.get_world_pixel_size(
		equipped_weapon_id,
		WEAPON_VISUAL_PIXEL_SIZE
	)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_index in SCREEN_DIRECTION_NAMES.size():
		var direction_name: String = SCREEN_DIRECTION_NAMES[direction_index]
		var idle_name := "idle_%s" % direction_name
		var fire_name := "fire_%s" % direction_name
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.add_frame(
			idle_name,
			catalog_texture if catalog_texture != null else _weapon_atlas_frame(direction_index, 0)
		)
		frames.add_animation(fire_name)
		frames.set_animation_loop(fire_name, false)
		frames.set_animation_speed(fire_name, 18.0)
		frames.add_frame(
			fire_name,
			catalog_texture if catalog_texture != null else _weapon_atlas_frame(direction_index, 1),
			1.0
		)
		frames.add_frame(
			fire_name,
			catalog_texture if catalog_texture != null else _weapon_atlas_frame(direction_index, 0),
			1.0
		)
	weapon_sprite.sprite_frames = frames
	_play_weapon_directional_animation("idle")


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
	melee_bat_sprite.pixel_size = 0.00095
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
	_add_fatigue(FATIGUE_MELEE_GAIN)
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
	var target_screen := camera.unproject_position(
		player.global_position + direction * MELEE_ATTACK_RANGE
	)
	var screen_direction := (target_screen - player_screen).normalized()
	var screen_reach := player_screen.distance_to(target_screen)
	var screen_angle := atan2(screen_direction.y, screen_direction.x)
	var aligned_angle := screen_angle + PI * 0.25
	var bat_texture_size := Vector2(
		BASEBALL_BAT_TEXTURE.get_width(),
		BASEBALL_BAT_TEXTURE.get_height()
	)
	var bat_texture_length := maxf(1.0, bat_texture_size.length())
	var bat_visual_length := clampf(screen_reach * 0.72, 48.0, 68.0)
	var bat_overlay_scale := bat_visual_length / bat_texture_length
	var bat_world_length := bat_texture_length * melee_bat_sprite.pixel_size * 0.9
	var bat_world_center := maxf(0.3, MELEE_ATTACK_RANGE - bat_world_length * 0.5)
	var bat_screen_center := maxf(18.0, screen_reach - bat_visual_length * 0.5)
	melee_bat_sprite.visible = building_canvas == null
	melee_bat_sprite.flip_h = false
	melee_bat_sprite.flip_v = false
	melee_bat_sprite.modulate = Color(1.18, 1.08, 0.92, 1.0)
	melee_bat_sprite.position = direction * 0.28 + Vector3(0, 0.43, 0)
	melee_bat_sprite.rotation.z = aligned_angle - deg_to_rad(96.0)
	melee_bat_sprite.scale = Vector3.ONE * 0.78
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(melee_bat_sprite, "rotation:z", aligned_angle + deg_to_rad(58.0), 0.21).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(melee_bat_sprite, "position", direction * bat_world_center + Vector3(0, 0.45, 0), 0.21)
	tween.tween_property(melee_bat_sprite, "scale", Vector3.ONE * 0.9, 0.21)
	tween.chain().tween_property(melee_bat_sprite, "modulate", Color(1.0, 0.82, 0.55, 0.0), 0.13)
	tween.chain().tween_callback(func() -> void:
		melee_bat_sprite.visible = false
	)
	if is_instance_valid(melee_bat_overlay):
		melee_bat_overlay.visible = true
		melee_bat_overlay.modulate = Color(1.2, 1.08, 0.88, 1.0)
		melee_bat_overlay.position = player_screen + screen_direction * 18.0 + Vector2(0, -10)
		melee_bat_overlay.rotation = aligned_angle - deg_to_rad(98.0)
		melee_bat_overlay.scale = Vector2.ONE * (bat_overlay_scale * 0.82)
		melee_bat_overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(player.global_position) + 4
		var overlay_tween := create_tween()
		overlay_tween.set_parallel(true)
		overlay_tween.tween_property(melee_bat_overlay, "rotation", aligned_angle + deg_to_rad(62.0), 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		overlay_tween.tween_property(melee_bat_overlay, "position", player_screen + screen_direction * bat_screen_center + Vector2(0, -10), 0.22)
		overlay_tween.tween_property(melee_bat_overlay, "scale", Vector2.ONE * bat_overlay_scale, 0.22)
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
	weapon_stats = WEAPON_SYSTEM.build_stats(
		equipped_weapon_id,
		equipped_weapon_mods,
		GameState.get_weapon_enhancement_level(equipped_weapon_id),
		GameState.mod_enhancement_levels
	)
	var magazine_id: String = GameState.equipped_magazine_id
	if not WEAPON_SYSTEM.is_magazine_compatible(equipped_weapon_id, magazine_id):
		magazine_id = str(weapon_stats.get("magazine_id", ""))
		GameState.equipped_magazine_id = magazine_id
	var ammo_id: String = GameState.equipped_ammo_id
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
	if reload_reticle_indicator:
		var show_reload := weapon_reloading and _uses_mouse_aim() and not _is_inventory_open()
		var reload_progress := 0.0
		if show_reload:
			var reload_duration := maxf(0.01, float(weapon_stats.get("reload_time", 2.15)))
			reload_progress = 1.0 - clampf(reload_timer / reload_duration, 0.0, 1.0)
			reload_reticle_indicator.position = get_viewport().get_mouse_position() - reload_reticle_indicator.size * 0.5
		reload_reticle_indicator.call("set_cooldown_progress", reload_progress, show_reload)


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
	reload_reticle_indicator = ROLL_COOLDOWN_INDICATOR_SCRIPT.new() as Control
	reload_reticle_indicator.name = "ReloadReticleIndicator"
	reload_reticle_indicator.scale = Vector2.ONE * 1.25
	aim_canvas.add_child(reload_reticle_indicator)


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
			var stamina_ratio := clampf(roll_stamina / ROLL_STAMINA_MAX, 0.0, 1.0)
			var stamina_is_active := roll_active or stamina_ratio < 0.999
			roll_cooldown_indicator.position = head_position + Vector2(28.0, -8.5)
			roll_cooldown_indicator.call(
				"set_cooldown_progress",
				stamina_ratio,
				stamina_is_active
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


func _setup_game_over_feedback() -> void:
	game_over_canvas = CanvasLayer.new()
	game_over_canvas.name = "GameOverCanvas"
	game_over_canvas.layer = 180
	add_child(game_over_canvas)
	game_over_fade = ColorRect.new()
	game_over_fade.name = "GameOverFade"
	game_over_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_fade.color = Color(0, 0, 0, 0)
	game_over_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_canvas.add_child(game_over_fade)
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	game_over_label.offset_left = -320
	game_over_label.offset_top = -130
	game_over_label.offset_right = 320
	game_over_label.offset_bottom = 130
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_override("font", preload("res://assets/fonts/Pretendard-Regular.otf"))
	game_over_label.add_theme_font_size_override("font_size", 54)
	game_over_label.add_theme_color_override("font_color", Color("#f1e6c8"))
	game_over_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	game_over_label.add_theme_constant_override("outline_size", 8)
	game_over_label.modulate.a = 0.0
	game_over_canvas.add_child(game_over_label)


func _capture_raid_start_snapshot() -> void:
	raid_start_snapshot = {
		"magazine_ammo": GameState.magazine_ammo,
		"reserve_ammo": GameState.reserve_ammo,
		"ammo_inventory": GameState.ammo_inventory.duplicate(true),
		"canned_food": GameState.canned_food,
		"churu": GameState.churu,
		"mod_component_inventory": GameState.mod_component_inventory.duplicate(true),
		"weapon_inventory": GameState.weapon_inventory.duplicate(true),
		"weapon_durability": GameState.weapon_durability,
		"equipped_weapon_id": GameState.equipped_weapon_id,
		"equipped_weapon_mods": GameState.equipped_weapon_mods.duplicate(),
		"fatigue": GameState.fatigue,
	}


func _restore_raid_start_snapshot_after_death() -> void:
	if raid_start_snapshot.is_empty():
		return
	GameState.magazine_ammo = int(raid_start_snapshot.get("magazine_ammo", 30))
	GameState.reserve_ammo = int(raid_start_snapshot.get("reserve_ammo", 90))
	GameState.ammo_inventory = (raid_start_snapshot.get("ammo_inventory", {}) as Dictionary).duplicate(true)
	GameState.canned_food = int(raid_start_snapshot.get("canned_food", GameState.canned_food))
	GameState.churu = int(raid_start_snapshot.get("churu", GameState.churu))
	GameState.mod_component_inventory = (raid_start_snapshot.get("mod_component_inventory", {}) as Dictionary).duplicate(true)
	GameState.weapon_inventory = (raid_start_snapshot.get("weapon_inventory", {}) as Dictionary).duplicate(true)
	GameState.weapon_durability = float(raid_start_snapshot.get("weapon_durability", 100.0))
	GameState.equipped_weapon_id = str(raid_start_snapshot.get("equipped_weapon_id", "ak47"))
	GameState.equipped_weapon_mods.assign(raid_start_snapshot.get("equipped_weapon_mods", []) as Array)
	GameState.fatigue = minf(float(raid_start_snapshot.get("fatigue", 0.0)) + 18.0, FATIGUE_MAX)
	GameState.player_health = 82
	GameState.returning_from_shelter = false
	GameState.world_time_hours = 9.0


func _format_survival_time() -> String:
	var elapsed_seconds := maxi(0, int((Time.get_ticks_msec() - run_started_msec) / 1000))
	var minutes := elapsed_seconds / 60
	var seconds := elapsed_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _begin_player_death_sequence() -> void:
	if player_death_sequence_active:
		return
	player_death_sequence_active = true
	fire_button_held = false
	mouse_fire_held = false
	laser_aim_held = false
	player.velocity = Vector3.ZERO
	if reload_reticle_indicator:
		reload_reticle_indicator.visible = false
	var survival_time := _format_survival_time()
	game_over_label.text = "GAME OVER\n\n생존 시간  %s\n처치한 적  %d\n가한 피해  %d" % [
		survival_time,
		run_kills,
		run_damage_dealt,
	]
	Engine.time_scale = 0.18
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(camera, "size", maxf(8.5, camera.size * 0.46), 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(survivor, "modulate", Color(1, 1, 1, 0), 1.25).set_delay(0.45)
	tween.tween_property(game_over_label, "modulate:a", 1.0, 0.55).set_delay(0.65)
	tween.tween_property(game_over_fade, "color:a", 0.62, 0.85).set_delay(1.15)
	tween.set_parallel(false)
	tween.tween_interval(1.25)
	tween.tween_property(game_over_fade, "color:a", 1.0, 0.6)
	tween.tween_callback(func() -> void:
		Engine.time_scale = 1.0
		_restore_raid_start_snapshot_after_death()
		GameState.register_shelter_return()
		get_tree().change_scene_to_file("res://scenes/shelter_interior.tscn")
	)


func _spawn_ak_pickup() -> void:
	ak_pickup = Node3D.new()
	ak_pickup.name = "AK47Pickup"
	ak_pickup.position = _safe_map_position(_scale_map_position(AK_PICKUP_POSITION))
	add_child(ak_pickup)

	var sprite := Sprite3D.new()
	sprite.name = "DropSprite"
	sprite.texture = WEAPON_VISUAL_CATALOG.get_weapon_texture("ak47")
	sprite.pixel_size = WEAPON_VISUAL_CATALOG.get_world_pixel_size("ak47", 0.0034)
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
	var world := $World as ProceduralCityMap
	var occupied_positions: Array[Vector3] = []
	var component_ids := ["rubber_gasket", "scope_lens", "magazine_spring"]
	var component_names := {
		"rubber_gasket": "소음기용 고무 패킹",
		"scope_lens": "스코프 렌즈",
		"magazine_spring": "탄창 스프링",
	}
	for index in BASE_FIELD_LOOT_COUNT:
		var position := _find_stratified_map_position(
			world,
			index,
			BASE_FIELD_LOOT_COUNT,
			12.0,
			9.0,
			occupied_positions,
			0.34
		)
		occupied_positions.append(position)
		match index % 4:
			0, 2:
				_create_loot_pickup(
					"ammo",
					position,
					{
						"ammo_id": "762_fmj",
						"amount": AMMO_PICKUP_AMOUNT,
						"display_name": "7.62mm 탄약",
					}
				)
			1:
				_create_loot_pickup(
					"canned_food",
					position,
					{"amount": 1, "display_name": "통조림"}
				)
			_:
				var component_index := floori(float(index) / 4.0) % component_ids.size()
				var component_id: String = component_ids[component_index]
				_create_loot_pickup(
					"mod_component",
					position,
					{
						"component_id": component_id,
						"amount": 1,
						"display_name": component_names[component_id],
					}
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
		"churu":
			sprite.texture = CHURU_TEXTURE
			sprite.pixel_size = 0.0011
			highlight_color = Color("#f2bd55")
		"mod_component":
			var component_id := str(data.get("component_id", "rubber_gasket"))
			sprite.texture = _get_mod_component_texture(component_id)
			sprite.pixel_size = 0.00105
			highlight_color = _get_mod_component_color(component_id)
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
	if weapon_id == "baseball_bat":
		return BASEBALL_BAT_TEXTURE
	var catalog_texture := WEAPON_VISUAL_CATALOG.get_weapon_texture(weapon_id)
	if catalog_texture != null:
		return catalog_texture
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
		ammo_prompt_panel.visible = (
			is_instance_valid(nearby_ammo_pickup)
			and not is_instance_valid(nearby_field_interaction)
		)
	if ammo_pickup_button and is_instance_valid(nearby_ammo_pickup):
		ammo_pickup_button.text = "%s 획득  [E]" % str(nearby_ammo_pickup.get_meta("display_name", "전리품"))


func _collect_nearby_ammo() -> void:
	if not is_instance_valid(nearby_ammo_pickup):
		return
	_add_fatigue(FATIGUE_LOOT_GAIN)
	var loot_type := str(nearby_ammo_pickup.get_meta("loot_type", "ammo"))
	var amount := int(nearby_ammo_pickup.get_meta("amount", 1))
	match loot_type:
		"canned_food":
			GameState.canned_food += amount
			ammo_notice.text = "통조림 +%d   보유 %d" % [amount, GameState.canned_food]
		"churu":
			GameState.churu += amount
			ammo_notice.text = "희귀 츄르 +%d   보유 %d" % [amount, GameState.churu]
		"mod_component":
			var component_id := str(nearby_ammo_pickup.get_meta("component_id", "rubber_gasket"))
			GameState.add_mod_component(component_id, amount)
			ammo_notice.text = "%s +%d   보유 %d" % [
				str(nearby_ammo_pickup.get_meta("display_name", "총기 부품")),
				amount,
				GameState.get_mod_component_count(component_id),
			]
		"weapon":
			var weapon_id := str(nearby_ammo_pickup.get_meta("weapon_id", "ak47"))
			GameState.add_weapon(weapon_id, amount)
			ammo_notice.text = "%s 보관 +%d" % [
				str(nearby_ammo_pickup.get_meta("display_name", "무기")),
				amount,
			]
		_:
			var pickup_ammo_id := str(nearby_ammo_pickup.get_meta("ammo_id", "762_fmj"))
			var updated_ammo_count: int = GameState.get_ammo_count(pickup_ammo_id) + amount
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


func _get_mod_component_texture(component_id: String) -> Texture2D:
	match component_id:
		"scope_lens": return SCOPE_LENS_TEXTURE
		"magazine_spring": return MAGAZINE_SPRING_TEXTURE
		_: return RUBBER_GASKET_TEXTURE


func _get_mod_component_color(component_id: String) -> Color:
	match component_id:
		"scope_lens": return Color("#65c5d7")
		"magazine_spring": return Color("#b4b9ae")
		_: return Color("#d1aa64")


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

	field_interaction_panel = PanelContainer.new()
	field_interaction_panel.name = "FieldInteractionPrompt"
	field_interaction_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	field_interaction_panel.offset_left = -220
	field_interaction_panel.offset_top = -192
	field_interaction_panel.offset_right = 220
	field_interaction_panel.offset_bottom = -116
	field_interaction_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.018, 0.026, 0.027, 0.96), Color("#79a994"), 5)
	)
	field_interaction_panel.visible = false
	$HUD.add_child(field_interaction_panel)
	var field_box := VBoxContainer.new()
	field_box.add_theme_constant_override("separation", 5)
	field_interaction_panel.add_child(field_box)
	field_interaction_button = Button.new()
	field_interaction_button.custom_minimum_size = Vector2(430, 48)
	field_interaction_button.text = "E 홀드  상호작용"
	field_interaction_button.focus_mode = Control.FOCUS_NONE
	field_interaction_button.add_theme_font_override("font", font)
	field_interaction_button.add_theme_font_size_override("font_size", 16)
	field_interaction_button.button_down.connect(func() -> void:
		field_interaction_touch_held = true
		if is_instance_valid(nearby_field_interaction) and str(nearby_field_interaction.get_meta("interaction_type", "")) == "extraction":
			_begin_extraction()
	)
	field_interaction_button.button_up.connect(func() -> void: field_interaction_touch_held = false)
	field_box.add_child(field_interaction_button)
	field_interaction_progress = ProgressBar.new()
	field_interaction_progress.custom_minimum_size = Vector2(430, 8)
	field_interaction_progress.show_percentage = false
	field_interaction_progress.add_theme_stylebox_override(
		"fill",
		_make_panel_style(Color("#83c9a5"), Color("#bce9cc"), 4)
	)
	field_box.add_child(field_interaction_progress)

	fatigue_panel = PanelContainer.new()
	fatigue_panel.name = "FatiguePanel"
	fatigue_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fatigue_panel.offset_left = 24
	fatigue_panel.offset_top = -188
	fatigue_panel.offset_right = 340
	fatigue_panel.offset_bottom = -132
	fatigue_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.02, 0.026, 0.025, 0.92), Color("#68796e"), 5)
	)
	$HUD.add_child(fatigue_panel)
	var fatigue_box := VBoxContainer.new()
	fatigue_box.add_theme_constant_override("separation", 3)
	fatigue_panel.add_child(fatigue_box)
	fatigue_label = Label.new()
	fatigue_label.text = "피로  0%"
	fatigue_label.add_theme_font_override("font", font)
	fatigue_label.add_theme_font_size_override("font_size", 13)
	fatigue_label.add_theme_color_override("font_color", Color("#b9c4bb"))
	fatigue_box.add_child(fatigue_label)
	fatigue_bar = ProgressBar.new()
	fatigue_bar.custom_minimum_size = Vector2(300, 9)
	fatigue_bar.max_value = FATIGUE_MAX
	fatigue_bar.show_percentage = false
	fatigue_bar.add_theme_stylebox_override(
		"fill",
		_make_panel_style(Color("#b99d5f"), Color("#dbc98a"), 5)
	)
	fatigue_box.add_child(fatigue_bar)

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
	inventory_ui.call("setup", font, WEAPON_VISUAL_CATALOG.get_weapon_texture(equipped_weapon_id), AMMO_762_TEXTURE, {
		"rubber_gasket": RUBBER_GASKET_TEXTURE,
		"scope_lens": SCOPE_LENS_TEXTURE,
		"magazine_spring": MAGAZINE_SPRING_TEXTURE,
	}, WEAPON_VISUAL_CATALOG.get_inventory_textures())
	inventory_ui.connect("open_state_changed", _on_inventory_open_state_changed)
	inventory_ui.connect("weapon_mods_changed", _on_inventory_weapon_mods_changed)
	_update_equipment_ui()


func _on_inventory_weapon_mods_changed() -> void:
	equipped_weapon_mods.assign(GameState.equipped_weapon_mods)
	_refresh_weapon_stats()
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
		if reserve_ammo > 0:
			_reload_ak47()
		else:
			_show_no_ammo_notice()
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
	_add_fatigue(FATIGUE_SHOT_GAIN)
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
		float(weapon_stats.get("damage", 24)) * damage_multiplier
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
	if WEAPON_VISUAL_CATALOG.has_weapon_texture(equipped_weapon_id):
		var screen_direction: Vector2 = DIRECTION_VECTORS[facing]
		weapon_sprite.flip_h = screen_direction.x < -0.01
		var source_angle := PI if weapon_sprite.flip_h else 0.0
		weapon_sprite.rotation = Vector3(
			0,
			0,
			wrapf(screen_direction.angle() - source_angle, -PI, PI)
		)
	else:
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
		if reserve_ammo <= 0:
			_show_no_ammo_notice()
		return
	weapon_reloading = true
	reload_timer = float(weapon_stats.get("reload_time", 2.15))
	fire_cooldown = reload_timer
	_add_fatigue(FATIGUE_RELOAD_GAIN)
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


func _show_no_ammo_notice() -> void:
	fire_cooldown = maxf(fire_cooldown, 0.35)
	if ammo_notice:
		ammo_notice.text = "탄약 없음\n예비탄을 확보해야 합니다."
		ammo_notice.visible = true
		ammo_notice_time = 1.1
	_update_equipment_ui()


func _update_equipment_ui() -> void:
	var weapon_name := str(weapon_stats.get("display_name", "AK-47"))
	var magazine_size := int(weapon_stats.get("magazine_size", 30))
	var mod_names: Array[String] = WEAPON_SYSTEM.get_mod_names(equipped_weapon_mods)
	var ammo_name := str(WEAPON_SYSTEM.get_ammo(GameState.equipped_ammo_id).get("display_name", GameState.equipped_ammo_id))
	var enhancement_level := GameState.get_weapon_enhancement_level(equipped_weapon_id)
	mod_names.push_front(ammo_name)
	var mod_text := ", ".join(mod_names) if not mod_names.is_empty() else "개조 없음"
	if equipment_label:
		equipment_label.text = "%s  +%d\n탄창 %02d / %02d · 예비 %03d\n내구도 %05.1f%% · 탄퍼짐 %.1f°\n%s%s" % [
			weapon_name, enhancement_level,
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
			"set_weapon_texture",
			WEAPON_VISUAL_CATALOG.get_weapon_texture(equipped_weapon_id)
		)
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
			_get_stored_weapon_count(),
			GameState.mod_component_inventory,
			GameState.rescued_workers,
			fatigue
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
		_update_equipment_ui()
		inventory_ui.call("toggle")


func _is_inventory_button_at(screen_position: Vector2) -> bool:
	if inventory_ui == null or _is_inventory_open():
		return false
	var button := inventory_ui.get_node_or_null("InventoryButton") as Button
	return button != null and button.visible and button.get_global_rect().has_point(screen_position)


func _on_inventory_open_state_changed(is_open: bool) -> void:
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_HIDDEN)
	if is_open:
		fire_button_held = false
		mouse_fire_held = false
		laser_aim_held = false
		pickup_touch_held = false
		pickup_keyboard_held = false
		field_interaction_touch_held = false
		field_interaction_keyboard_held = false
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
		audio.unit_size = 9.0
		audio.max_distance = 72.0
		audio.volume_db = -1.0
		player.add_child(audio)
		gunshot_players.append(audio)


func _create_gunshot_stream() -> AudioStreamWAV:
	var mix_rate := 44100
	var sample_count := int(mix_rate * 0.34)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 47047
	for index in sample_count:
		var time := float(index) / mix_rate
		var muzzle_blast := random.randf_range(-1.0, 1.0) * exp(-time * 35.0)
		var metallic_crack := sin(TAU * 720.0 * time + random.randf_range(-0.18, 0.18)) * exp(-time * 23.0)
		var low_thump := sin(TAU * 86.0 * time) * exp(-time * 11.0)
		var tail_noise := random.randf_range(-1.0, 1.0) * exp(-maxf(0.0, time - 0.045) * 9.0) * 0.34
		var slapback := 0.0
		if time > 0.055:
			slapback += random.randf_range(-1.0, 1.0) * exp(-(time - 0.055) * 19.0) * 0.18
		if time > 0.115:
			slapback += random.randf_range(-1.0, 1.0) * exp(-(time - 0.115) * 14.0) * 0.11
		var sample := muzzle_blast * 0.82 + metallic_crack * 0.26 + low_thump * 0.58 + tail_noise + slapback
		_write_wav_sample(data, index, tanh(sample * 1.35) * 0.92)
	return _make_wav_stream(data, mix_rate)


func _build_roll_audio() -> void:
	roll_audio_player = AudioStreamPlayer3D.new()
	roll_audio_player.name = "RollWhoosh"
	roll_audio_player.stream = _create_roll_stream()
	roll_audio_player.unit_size = 4.0
	roll_audio_player.max_distance = 24.0
	roll_audio_player.volume_db = -5.0
	player.add_child(roll_audio_player)


func _create_roll_stream() -> AudioStreamWAV:
	var mix_rate := 32000
	var sample_count := int(mix_rate * 0.28)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 82119
	for index in sample_count:
		var time := float(index) / mix_rate
		var progress := time / 0.28
		var envelope := sin(clampf(progress, 0.0, 1.0) * PI)
		var air := random.randf_range(-1.0, 1.0) * envelope
		var cloth := sin(TAU * (170.0 + 180.0 * progress) * time) * envelope * 0.22
		var low := sin(TAU * 58.0 * time) * exp(-time * 9.0) * 0.2
		_write_wav_sample(data, index, clampf(air * 0.34 + cloth + low, -1.0, 1.0))
	return _make_wav_stream(data, mix_rate)


func _play_roll_sound() -> void:
	if not is_instance_valid(roll_audio_player):
		return
	roll_audio_player.stop()
	roll_audio_player.pitch_scale = randf_range(0.94, 1.08)
	roll_audio_player.play()


func _build_bgm_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "ApocalypseSeoulBGM"
	bgm_player.stream = _create_apocalypse_bgm_stream()
	bgm_player.volume_db = -21.0
	bgm_player.bus = "Master"
	add_child(bgm_player)
	bgm_player.play()


func _create_apocalypse_bgm_stream() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 18.0
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 130713
	var noise_hold := 0.0
	for index in sample_count:
		var time := float(index) / mix_rate
		if index % 300 == 0:
			noise_hold = random.randf_range(-1.0, 1.0)
		var fade_in := clampf(time / 2.0, 0.0, 1.0)
		var fade_out := clampf((duration - time) / 2.0, 0.0, 1.0)
		var loop_fade := minf(fade_in, fade_out)
		var drone := sin(TAU * 43.65 * time) * 0.26
		drone += sin(TAU * 65.41 * time + 1.7) * 0.12
		drone += sin(TAU * 98.0 * time + 0.4) * 0.06
		var distant_alarm := sin(TAU * 0.075 * time) * sin(TAU * 392.0 * time) * 0.045
		var rain_static := noise_hold * 0.04
		var pulse := 0.0
		var pulse_phase := fmod(time, 6.0)
		if pulse_phase < 0.55:
			pulse = sin(TAU * 72.0 * time) * exp(-pulse_phase * 7.0) * 0.16
		_write_wav_sample(data, index, clampf((drone + distant_alarm + rain_static + pulse) * loop_fade, -1.0, 1.0))
	var stream := _make_wav_stream(data, mix_rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _make_wav_stream(data: PackedByteArray, mix_rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _write_wav_sample(data: PackedByteArray, index: int, sample: float) -> void:
	var encoded := int(clampf(sample, -1.0, 1.0) * 32767.0)
	data[index * 2] = encoded & 0xff
	data[index * 2 + 1] = (encoded >> 8) & 0xff


func _play_gunshot() -> void:
	if gunshot_players.is_empty():
		return
	var audio := gunshot_players[gunshot_index]
	gunshot_index = (gunshot_index + 1) % gunshot_players.size()
	audio.play()


func _spawn_enemies() -> void:
	var world := $World as ProceduralCityMap
	var enemy_multiplier := float(raid_zone_data.get("enemy_multiplier", 1.0))
	var total_enemies := maxi(BASE_ENEMY_COUNT, roundi(float(BASE_ENEMY_COUNT) * enemy_multiplier))
	var zone_threat := float(raid_zone_data.get("threat", 0.0))
	for index in total_enemies:
		var kind := "melee" if index < 2 else "pistol"
		var spawn_position := _find_distributed_enemy_position(world, index, total_enemies)
		_spawn_enemy(kind, spawn_position, maxf(night_intensity, zone_threat))
	if bool(raid_zone_data.get("boss", false)):
		_spawn_zone_boss(world, total_enemies, zone_threat)


func _spawn_zone_boss(world: ProceduralCityMap, spawn_index: int, zone_threat: float) -> void:
	var boss_position := _find_distributed_enemy_position(world, spawn_index, spawn_index + 1)
	var boss := _spawn_enemy("pistol", boss_position, maxf(0.5, zone_threat))
	boss.name = "RaidBoss_%s" % GameState.selected_raid_zone
	boss.set_meta("raid_boss", true)
	boss.set_meta("zone_id", GameState.selected_raid_zone)
	var boss_health := roundi(220.0 + zone_threat * 260.0)
	boss.set("health", boss_health)
	boss.set("max_health", boss_health)
	boss.set("health_ratio", 1.0)
	boss.set("damage_trail_ratio", 1.0)
	boss.set("threat_level", 1.0)
	boss.set("alerted", true)
	boss.set("pursuit_time", 45.0)
	var marker := Label3D.new()
	marker.name = "BossMarker"
	marker.text = "정예"
	marker.position = Vector3(0.0, 2.68, 0.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.render_priority = 127
	marker.font = FONT
	marker.font_size = 42
	marker.pixel_size = 0.005
	marker.modulate = Color("#f1c45d")
	marker.outline_modulate = Color(0.08, 0.02, 0.01, 0.95)
	marker.outline_size = 10
	boss.add_child(marker)


func _find_distributed_enemy_position(
	world: ProceduralCityMap,
	index: int,
	total_count: int
) -> Vector3:
	var occupied_positions: Array[Vector3] = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			occupied_positions.append(enemy.global_position)
	if index == 0:
		var map_limit := world.get_map_limit() - 8.0
		for attempt in 16:
			var angle := TAU * float(attempt) / 16.0 + spawn_random.randf_range(-0.12, 0.12)
			var requested := player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 28.0
			requested.x = clampf(requested.x, -map_limit, map_limit)
			requested.z = clampf(requested.z, -map_limit, map_limit)
			requested.y = 0.78
			var nearby_candidate := world.find_nearest_open_position(requested)
			nearby_candidate.y = 0.78
			if nearby_candidate.distance_to(player.global_position) >= 16.0:
				return nearby_candidate
	return _find_stratified_map_position(
		world,
		index - 1,
		total_count - 1,
		16.0,
		7.0,
		occupied_positions,
		0.78
	)


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
	if enemy.has_signal("damaged"):
		enemy.connect("damaged", _on_enemy_damaged)
	if enemy.has_signal("reinforcement_called"):
		enemy.connect("reinforcement_called", _on_enemy_reinforcement_called)
	enemies.append(enemy)
	return enemy


func _on_enemy_died(enemy: CharacterBody3D) -> void:
	run_kills += 1
	if enemy == active_reinforcement_caller:
		active_reinforcement_caller = null
		sustained_combat_time = REINFORCEMENT_CALL_TRIGGER_TIME * 0.45
	_spawn_enemy_loot(enemy)
	enemies.erase(enemy)
	reinforcement_timer = minf(reinforcement_timer, 2.5)


func _on_enemy_damaged(_enemy: CharacterBody3D, amount: int) -> void:
	run_damage_dealt += maxi(0, amount)


func _spawn_enemy_loot(enemy: CharacterBody3D) -> Node3D:
	var drop_position := enemy.global_position
	var enemy_weapon_id := str(enemy.get("weapon_id"))
	if bool(enemy.get_meta("raid_boss", false)):
		var guaranteed_churu := maxi(1, int(raid_zone_data.get("required_tier", 2)) - 1)
		var boss_drop := _create_loot_pickup(
			"churu",
			drop_position,
			{"amount": guaranteed_churu, "display_name": "정예 보상 츄르"}
		)
		_create_loot_pickup(
			"weapon",
			drop_position + Vector3(1.0, 0.0, 0.7),
			{"amount": 1, "weapon_id": enemy_weapon_id, "display_name": _get_loot_weapon_name(enemy_weapon_id)}
		)
		return boss_drop
	var roll := spawn_random.randf()
	var churu_chance := 0.01 + night_intensity * 0.015 + float(raid_zone_data.get("threat", 0.0)) * 0.018
	if roll < churu_chance:
		return _create_loot_pickup(
			"churu",
			drop_position,
			{"amount": 1, "display_name": "희귀 츄르"}
		)
	if roll < 0.5 + churu_chance:
		return _create_loot_pickup(
			"ammo",
			drop_position,
			_get_enemy_ammo_drop(enemy_weapon_id)
		)
	if roll < 0.85 + churu_chance:
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
uniform vec2 facing_screen_direction = vec2(0.0, -1.0);
uniform float inner_radius = 245.0;
uniform float outer_radius = 430.0;
uniform float near_radius = 96.0;
uniform float fan_cos = 0.34;
uniform float darkness = 0.86;
uniform float aim_expanded = 0.0;
uniform float circle_radius = 245.0;

void fragment() {
	vec2 pixel_position = UV * viewport_size;
	vec2 to_pixel = pixel_position - player_screen;
	float distance_from_player = length(to_pixel);
	vec2 pixel_direction = distance_from_player > 0.001 ? normalize(to_pixel) : facing_screen_direction;
	float alignment = dot(pixel_direction, normalize(facing_screen_direction));
	float near_visibility = 1.0 - smoothstep(near_radius * 0.72, near_radius, distance_from_player);
	float circle_visibility = 1.0 - smoothstep(circle_radius * 0.78, circle_radius, distance_from_player);
	float fan_visibility = smoothstep(fan_cos - 0.11, fan_cos + 0.08, alignment);
	float range_visibility = 1.0 - smoothstep(inner_radius, outer_radius, distance_from_player);
	float relaxed_visibility = max(near_visibility, circle_visibility);
	float aimed_visibility = max(relaxed_visibility, fan_visibility * range_visibility);
	float visibility = mix(relaxed_visibility, aimed_visibility, aim_expanded);
	float fog_alpha = mix(darkness, 0.035, visibility);
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
	var circle_radius := lerpf(178.0, 104.0, night_intensity)
	var inner_radius := lerpf(430.0, 185.0, night_intensity)
	var outer_radius := lerpf(560.0, 285.0, night_intensity)
	var edge_darkness := lerpf(0.82, 0.97, night_intensity)
	var player_screen := camera.unproject_position(player.global_position)
	var facing_screen := camera.unproject_position(player.global_position + _get_perception_aim_direction() * 5.0)
	var facing_screen_direction := (facing_screen - player_screen).normalized()
	if facing_screen_direction.length_squared() <= 0.001:
		facing_screen_direction = Vector2(0.0, -1.0)
	visibility_material.set_shader_parameter("viewport_size", viewport_size)
	visibility_material.set_shader_parameter("player_screen", player_screen)
	visibility_material.set_shader_parameter("facing_screen_direction", facing_screen_direction)
	visibility_material.set_shader_parameter("inner_radius", inner_radius)
	visibility_material.set_shader_parameter("outer_radius", outer_radius)
	visibility_material.set_shader_parameter("near_radius", lerpf(112.0, 64.0, night_intensity))
	visibility_material.set_shader_parameter("fan_cos", lerpf(0.06, 0.34, night_intensity))
	visibility_material.set_shader_parameter("darkness", edge_darkness)
	visibility_material.set_shader_parameter("aim_expanded", 1.0 if laser_aim_held else 0.0)
	visibility_material.set_shader_parameter("circle_radius", circle_radius)


func _update_enemy_visibility() -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var fully_visible_radius := lerpf(178.0, 104.0, night_intensity)
	var reveal_radius := fully_visible_radius + lerpf(46.0, 30.0, night_intensity)
	if laser_aim_held:
		fully_visible_radius = lerpf(430.0, 185.0, night_intensity)
		reveal_radius = lerpf(560.0, 285.0, night_intensity)
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
	var facing_screen := camera.unproject_position(player.global_position + _get_perception_aim_direction() * 5.0)
	var facing_screen_direction := (facing_screen - player_screen).normalized()
	var enemy_screen_direction := (enemy_screen - player_screen).normalized()
	var near_radius := lerpf(112.0, 64.0, night_intensity)
	var fan_cos := lerpf(0.06, 0.34, night_intensity)
	if laser_aim_held and screen_distance > near_radius and enemy_screen_direction.dot(facing_screen_direction) < fan_cos:
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
	var facing_screen := camera.unproject_position(player.global_position + _get_perception_aim_direction() * 5.0)
	var facing_screen_direction := (facing_screen - player_screen).normalized()
	var enemy_screen_direction := (enemy_screen - player_screen).normalized()
	var near_radius := lerpf(112.0, 64.0, night_intensity)
	var fan_cos := lerpf(0.06, 0.34, night_intensity)
	if laser_aim_held and player_screen.distance_to(enemy_screen) > near_radius and enemy_screen_direction.dot(facing_screen_direction) < fan_cos:
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
	_add_fatigue(minf(1.8, float(amount) * FATIGUE_DAMAGE_PER_POINT))
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
		_begin_player_death_sequence()
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
	companion_overlay.visible = companion_active
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
	if companion_active:
		var companion_texture := companion_sprite.sprite_frames.get_frame_texture(
			companion_sprite.animation,
			companion_sprite.frame
		)
		if companion_texture:
			companion_overlay.texture = companion_texture
		companion_overlay.visible = true
		companion_overlay.position = camera.unproject_position(companion_sprite.global_position)
		companion_overlay.scale = Vector2.ONE * companion_sprite.pixel_size * screen_scale
		companion_overlay.offset = companion_sprite.offset
		companion_overlay.flip_h = companion_sprite.flip_h
		companion_overlay.modulate = companion_sprite.modulate
		companion_overlay.z_index = OVERLAY_DEPTH_SORT.world_depth(companion.global_position)
	else:
		companion_overlay.visible = false
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
		var touches_facing_sector := _structure_touches_visibility_sector(building)
		building.set_meta("overlay_overlaps_player", overlaps_player)
		building.set_meta("overlay_occludes_player", is_occluding)
		building.set_meta("overlay_in_facing_sector", touches_facing_sector)
		player_is_occluded = player_is_occluded or is_occluding
		if sprite:
			var color := sprite.modulate
			var target_alpha := STRUCTURE_REVEAL_BUILDING_ALPHA if (is_occluding or touches_facing_sector) else 1.0
			color.a = move_toward(color.a, target_alpha, delta * 4.2)
			sprite.modulate = color
	for node in get_tree().get_nodes_in_group("vehicle_obstacle"):
		var vehicle := node as Node3D
		var vehicle_sprite := vehicle.get_node_or_null("VehicleSprite") as Sprite3D
		if vehicle_sprite == null:
			continue
		var touches_facing_sector := _structure_touches_visibility_sector(vehicle)
		vehicle.set_meta("overlay_in_facing_sector", touches_facing_sector)
		var vehicle_color := vehicle_sprite.modulate
		var vehicle_target_alpha := STRUCTURE_REVEAL_VEHICLE_ALPHA if touches_facing_sector else 1.0
		vehicle_color.a = move_toward(vehicle_color.a, vehicle_target_alpha, delta * 4.8)
		vehicle_sprite.modulate = vehicle_color
	var target_player_color := SILHOUETTE_COLOR if player_is_occluded else Color.WHITE
	survivor.modulate = survivor.modulate.lerp(target_player_color, 1.0 - exp(-10.0 * delta))
	if weapon_sprite:
		weapon_sprite.modulate = weapon_sprite.modulate.lerp(target_player_color, 1.0 - exp(-10.0 * delta))


func _structure_touches_visibility_sector(structure: Node3D) -> bool:
	if not is_instance_valid(structure):
		return false
	var player_ground := Vector2(player.global_position.x, player.global_position.z)
	var structure_ground := Vector2(structure.global_position.x, structure.global_position.z)
	var center_offset := structure_ground - player_ground
	var center_distance := center_offset.length()
	var footprint_radius := _get_structure_footprint_radius(structure)
	if center_distance - footprint_radius > STRUCTURE_REVEAL_RADIUS:
		return false
	if center_distance <= footprint_radius + 0.2:
		return true
	var facing_world := _get_current_facing_world_direction()
	var facing_ground := Vector2(facing_world.x, facing_world.z).normalized()
	if facing_ground.length_squared() <= 0.01:
		return false
	var center_direction := center_offset / center_distance
	var center_angle := acos(clampf(facing_ground.dot(center_direction), -1.0, 1.0))
	var angular_padding := asin(clampf(footprint_radius / center_distance, 0.0, 0.98))
	return center_angle <= deg_to_rad(STRUCTURE_REVEAL_HALF_ANGLE_DEG) + angular_padding


func _get_structure_footprint_radius(structure: Node3D) -> float:
	if structure.has_meta("collision_world_size"):
		var collision_world_size: Variant = structure.get_meta("collision_world_size")
		if collision_world_size is Vector3:
			var vehicle_size: Vector3 = collision_world_size
			return Vector2(vehicle_size.x, vehicle_size.z).length() * 0.5
	for child in structure.get_children():
		var collision := child as CollisionShape3D
		if collision == null or not (collision.shape is BoxShape3D):
			continue
		var box_size := (collision.shape as BoxShape3D).size
		return Vector2(box_size.x, box_size.z).length() * 0.5
	return float(structure.get_meta("occlusion_lateral_limit")) if structure.has_meta("occlusion_lateral_limit") else 1.6


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
	var positions: Array[Vector3] = []
	for site in extraction_sites:
		positions.append(site.global_position)
	tactical_map.call("setup", world, player, positions)


func _is_tactical_map_open() -> bool:
	return is_instance_valid(tactical_map) and bool(tactical_map.call("is_open"))


func _setup_extraction_site(world: ProceduralCityMap) -> void:
	extraction_sites.clear()
	var positions: Array[Vector3] = [world.get_extraction_position()]
	var extraction_attempts := 0
	while positions.size() < 3 and extraction_attempts < 48:
		extraction_attempts += 1
		var candidate := _find_random_field_position(world, 34.0)
		var separated := true
		for existing_position in positions:
			if candidate.distance_to(existing_position) < 34.0:
				separated = false
				break
		if separated:
			positions.append(candidate)
	while positions.size() < 3:
		var fallback_angle := TAU * float(positions.size()) / 3.0
		var fallback := world.find_nearest_open_position(
			player.global_position + Vector3(cos(fallback_angle), 0, sin(fallback_angle)) * 54.0
		)
		positions.append(fallback)
	for index in positions.size():
		var site := _create_extraction_beacon(positions[index], index)
		extraction_sites.append(site)
		field_interactions.append(site)
	extraction_site = extraction_sites[0]
	extraction_position = extraction_site.global_position
	extraction_prompt = field_interaction_panel

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


func _create_extraction_beacon(world_position: Vector3, index: int) -> Node3D:
	var site := Node3D.new()
	site.name = "SewerExtraction_%02d" % (index + 1)
	add_child(site)
	site.global_position = Vector3(world_position.x, 0.08, world_position.z)
	site.set_meta("interaction_type", "extraction")
	site.set_meta("display_name", "하수구 탈출 지점")
	site.set_meta("hold_duration", 0.0)
	site.set_meta("interaction_distance", FIELD_INTERACTION_DISTANCE)
	site.add_to_group("field_extraction")

	_add_interaction_marker(site, Color("#d9b44a"), 1.55, true)
	var beam_material := StandardMaterial3D.new()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.albedo_color = Color(0.91, 0.76, 0.29, 0.12)
	beam_material.emission_enabled = true
	beam_material.emission = Color("#e8c761")
	beam_material.emission_energy_multiplier = 1.8
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.28
	beam_mesh.bottom_radius = 1.25
	beam_mesh.height = 5.5
	beam_mesh.radial_segments = 24
	beam_mesh.material = beam_material
	var beam := MeshInstance3D.new()
	beam.name = "ExtractionBeacon"
	beam.position.y = 2.75
	beam.mesh = beam_mesh
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	site.add_child(beam)

	var light := OmniLight3D.new()
	light.name = "ExtractionLight"
	light.position.y = 1.15
	light.light_color = Color("#f1d070")
	light.light_energy = 3.2
	light.omni_range = 7.5
	light.shadow_enabled = false
	site.add_child(light)
	return site


func _find_random_field_position(world: ProceduralCityMap, minimum_player_distance: float = 18.0) -> Vector3:
	var map_limit := world.get_map_limit() * 0.82
	var fallback := world.find_nearest_open_position(Vector3.ZERO)
	for attempt in 48:
		var requested := Vector3(
			spawn_random.randf_range(-map_limit, map_limit),
			0.08,
			spawn_random.randf_range(-map_limit, map_limit)
		)
		var candidate := world.find_nearest_open_position(requested)
		candidate.y = 0.08
		fallback = candidate
		if candidate.distance_to(player.global_position) >= minimum_player_distance:
			return candidate
	return fallback


func _find_stratified_map_position(
	world: ProceduralCityMap,
	index: int,
	total_count: int,
	minimum_player_distance: float,
	minimum_separation: float,
	occupied_positions: Array[Vector3],
	world_y: float
) -> Vector3:
	var grid_side := maxi(1, ceili(sqrt(float(maxi(1, total_count)))))
	var sector_x := index % grid_side
	var sector_z := floori(float(index) / float(grid_side))
	var map_limit := world.get_map_limit() - 8.0
	var sector_size := map_limit * 2.0 / float(grid_side)
	var sector_center := Vector3(
		-map_limit + (float(sector_x) + 0.5) * sector_size,
		world_y,
		-map_limit + (float(sector_z) + 0.5) * sector_size
	)
	var fallback := world.find_nearest_open_position(sector_center)
	fallback.y = world_y
	for attempt in 24:
		var jitter_scale := sector_size * (0.12 + 0.015 * float(attempt % 8))
		var angle := spawn_random.randf_range(0.0, TAU)
		var requested := sector_center + Vector3(cos(angle), 0.0, sin(angle)) * jitter_scale
		requested.x = clampf(requested.x, -map_limit, map_limit)
		requested.z = clampf(requested.z, -map_limit, map_limit)
		var candidate := world.find_nearest_open_position(requested)
		candidate.y = world_y
		fallback = candidate
		if candidate.distance_to(player.global_position) < minimum_player_distance:
			continue
		if world.is_position_in_safe_zone(candidate):
			continue
		var separated := true
		for occupied_position in occupied_positions:
			if occupied_position.distance_to(candidate) < minimum_separation:
				separated = false
				break
		if separated:
			return candidate
	return fallback


func _setup_field_objectives(world: ProceduralCityMap) -> void:
	_setup_salvage_points(world)
	_setup_rescue_points(world)


func _setup_salvage_points(world: ProceduralCityMap) -> void:
	var vehicles := get_tree().get_nodes_in_group("vehicle_obstacle")
	vehicles.sort_custom(func(a: Node, b: Node) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	var vehicle_count := mini(5, vehicles.size())
	for index in vehicle_count:
		var vehicle := vehicles[(index * 2 + GameState.map_seed) % vehicles.size()] as Node3D
		if not is_instance_valid(vehicle):
			continue
		var collision_size: Vector3 = vehicle.get_meta("collision_world_size", Vector3(3.0, 1.0, 1.8))
		var access_offset := (
			Vector3(0, 0, collision_size.z * 0.5 + 0.9)
			if collision_size.x >= collision_size.z
			else Vector3(collision_size.x * 0.5 + 0.9, 0, 0)
		)
		var point := _create_field_interaction(
			"salvage",
			vehicle.global_position + access_offset,
			"파손 차량 부품 분해",
			SALVAGE_HOLD_DURATION
		)
		point.set_meta("source_kind", str(vehicle.get_meta("vehicle_type", "wrecked_vehicle")))
		_add_interaction_marker(point, Color("#67b8bd"), 1.05, false)

	for index in 2:
		var position := _find_random_field_position(world, 22.0)
		var is_sentry := index == 0
		var point := _create_field_interaction(
			"salvage",
			position,
			"망가진 센트리 건 분해" if is_sentry else "폐가전 부품 분해",
			SALVAGE_HOLD_DURATION
		)
		point.set_meta("source_kind", "broken_sentry" if is_sentry else "broken_electronics")
		if is_sentry:
			_build_sentry_prop(point)
		else:
			_build_electronics_prop(point)
		_add_interaction_marker(point, Color("#67b8bd"), 0.9, false)


func _setup_rescue_points(world: ProceduralCityMap) -> void:
	for index in 3:
		var point := _create_field_interaction(
			"rescue",
			_find_random_field_position(world, 26.0),
			"갇힌 피난민 고양이 구조",
			RESCUE_HOLD_DURATION
		)
		_build_rescue_locker(point)
		_add_interaction_marker(point, Color("#74d39f"), 0.95, false)


func _create_field_interaction(
	interaction_type: String,
	world_position: Vector3,
	display_name: String,
	hold_duration: float
) -> Node3D:
	var point := Node3D.new()
	point.name = "Field_%s_%d" % [interaction_type, field_interactions.size()]
	add_child(point)
	point.global_position = Vector3(world_position.x, 0.08, world_position.z)
	point.set_meta("interaction_type", interaction_type)
	point.set_meta("display_name", display_name)
	point.set_meta("hold_duration", hold_duration)
	point.set_meta("interaction_distance", FIELD_INTERACTION_DISTANCE)
	point.set_meta("completed", false)
	point.add_to_group("field_interaction")
	field_interactions.append(point)
	return point


func _add_interaction_marker(point: Node3D, color: Color, radius: float, strong_light: bool) -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.4)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.84
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 12
	torus.material = material
	var ring := MeshInstance3D.new()
	ring.name = "InteractionRing"
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point.add_child(ring)
	if strong_light:
		return
	var light := OmniLight3D.new()
	light.name = "InteractionLight"
	light.position.y = 0.75
	light.light_color = color
	light.light_energy = 0.7
	light.omni_range = 2.8
	light.shadow_enabled = false
	point.add_child(light)


func _build_electronics_prop(point: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#374246")
	material.metallic = 0.65
	material.roughness = 0.78
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.25, 0.7, 0.85)
	mesh.material = material
	var prop := MeshInstance3D.new()
	prop.name = "BrokenElectronics"
	prop.position.y = 0.36
	prop.rotation.y = deg_to_rad(spawn_random.randf_range(-35.0, 35.0))
	prop.mesh = mesh
	point.add_child(prop)


func _build_sentry_prop(point: Node3D) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "BrokenSentry"
	sprite.texture = BROKEN_SENTRY_TEXTURE
	sprite.position = Vector3(0, 0.7, 0)
	sprite.pixel_size = 0.00215
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.render_priority = 8
	point.add_child(sprite)


func _build_rescue_locker(point: Node3D) -> void:
	var cabinet_material := StandardMaterial3D.new()
	cabinet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabinet_material.albedo_color = Color(0.20, 0.25, 0.24, 0.42)
	cabinet_material.metallic = 0.55
	cabinet_material.roughness = 0.82
	var cabinet_mesh := BoxMesh.new()
	cabinet_mesh.size = Vector3(1.1, 1.65, 0.72)
	cabinet_mesh.material = cabinet_material
	var cabinet := MeshInstance3D.new()
	cabinet.name = "RescueLocker"
	cabinet.position.y = 0.82
	cabinet.mesh = cabinet_mesh
	point.add_child(cabinet)
	var resident := Sprite3D.new()
	resident.name = "CoweringResident"
	resident.texture = _get_cowering_resident_texture("s")
	resident.position = Vector3(0, 0.72, -0.4)
	resident.pixel_size = 0.0078
	resident.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	resident.shaded = false
	resident.transparent = true
	resident.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	resident.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	resident.no_depth_test = true
	resident.render_priority = 108
	point.add_child(resident)
	point.set_meta("resident_facing", "s")
	var sign := Label3D.new()
	sign.name = "RescueSign"
	sign.text = "SOS"
	sign.position = Vector3(0, 1.24, -0.38)
	sign.font_size = 28
	sign.modulate = Color("#8de0b2")
	sign.outline_size = 6
	sign.no_depth_test = true
	point.add_child(sign)


func _update_cowering_resident_facing(point: Node3D) -> void:
	var resident := point.get_node_or_null("CoweringResident") as Sprite3D
	if resident == null:
		return
	var world_direction := player.global_position - point.global_position
	world_direction.y = 0.0
	if world_direction.length_squared() <= 0.01:
		return
	var screen_direction := Vector2(
		world_direction.x - world_direction.z,
		world_direction.x + world_direction.z
	).normalized()
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var direction_index := int(round(angle / 45.0)) % SCREEN_DIRECTION_NAMES.size()
	var direction_name: String = SCREEN_DIRECTION_NAMES[direction_index]
	if str(point.get_meta("resident_facing", "")) == direction_name:
		return
	point.set_meta("resident_facing", direction_name)
	resident.texture = _get_cowering_resident_texture(direction_name)


func _get_cowering_resident_texture(direction_name: String) -> Texture2D:
	if cowering_resident_texture_cache.has(direction_name):
		return cowering_resident_texture_cache[direction_name] as Texture2D
	var texture_path := str(COWERING_RESIDENT_TEXTURE_PATHS.get(
		direction_name,
		COWERING_RESIDENT_TEXTURE_PATHS["s"]
	))
	var texture := load(texture_path) as Texture2D
	cowering_resident_texture_cache[direction_name] = texture
	return texture


func _update_extraction_prompt() -> void:
	_update_field_interactions(0.0)


func _update_field_interactions(delta: float) -> void:
	var previous_interaction := nearby_field_interaction
	nearby_field_interaction = null
	var nearest_distance := INF
	for point in field_interactions.duplicate():
		if not is_instance_valid(point):
			field_interactions.erase(point)
			continue
		if str(point.get_meta("interaction_type", "")) == "rescue":
			_update_cowering_resident_facing(point)
		var ring := point.get_node_or_null("InteractionRing") as MeshInstance3D
		if ring:
			var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.0035 + point.global_position.x)
			ring.scale = Vector3(pulse, pulse, pulse)
		var distance := player.global_position.distance_to(point.global_position)
		var interaction_distance := float(point.get_meta("interaction_distance", FIELD_INTERACTION_DISTANCE))
		if distance <= interaction_distance and distance < nearest_distance:
			nearest_distance = distance
			nearby_field_interaction = point

	if previous_interaction != nearby_field_interaction:
		field_interaction_hold_time = 0.0
		field_interaction_keyboard_held = false
		field_interaction_touch_held = false

	var can_show := (
		is_instance_valid(nearby_field_interaction)
		and not extraction_transition_active
		and not _is_inventory_open()
		and not _is_tactical_map_open()
	)
	if field_interaction_panel:
		field_interaction_panel.visible = can_show
	if not can_show:
		field_interaction_hold_time = 0.0
		if field_interaction_progress:
			field_interaction_progress.value = 0.0
		return
	if ammo_prompt_panel:
		ammo_prompt_panel.visible = false

	var interaction_type := str(nearby_field_interaction.get_meta("interaction_type", ""))
	var display_name := str(nearby_field_interaction.get_meta("display_name", "상호작용"))
	var hold_duration := float(nearby_field_interaction.get_meta("hold_duration", 1.0))
	if field_interaction_button:
		if interaction_type == "extraction":
			field_interaction_button.text = "E  %s  ·  주민 %d명 후송" % [display_name, rescued_followers.size()]
		else:
			field_interaction_button.text = "E 홀드  %s" % display_name
	if field_interaction_progress:
		field_interaction_progress.max_value = maxf(hold_duration, 1.0)
		field_interaction_progress.value = field_interaction_hold_time
		field_interaction_progress.visible = interaction_type != "extraction"
	if interaction_type == "extraction":
		return

	if field_interaction_keyboard_held or field_interaction_touch_held:
		field_interaction_hold_time = minf(field_interaction_hold_time + delta, hold_duration)
	else:
		field_interaction_hold_time = maxf(0.0, field_interaction_hold_time - delta * 2.8)
	if field_interaction_progress:
		field_interaction_progress.value = field_interaction_hold_time
	if field_interaction_hold_time >= hold_duration:
		_complete_field_interaction(nearby_field_interaction)


func _complete_field_interaction(point: Node3D) -> void:
	if not is_instance_valid(point) or bool(point.get_meta("completed", false)):
		return
	var interaction_type := str(point.get_meta("interaction_type", ""))
	if interaction_type == "rescue":
		var occupied_after_escort: int = GameState.rescued_workers + rescued_followers.size()
		if occupied_after_escort >= GameState.get_resident_capacity():
			_show_field_notice("쉘터 수용량 부족 · 침대를 확장해야 구조할 수 있습니다")
			field_interaction_hold_time = 0.0
			return
	point.set_meta("completed", true)
	match interaction_type:
		"salvage":
			_add_fatigue(FATIGUE_SALVAGE_GAIN)
			_spawn_salvage_rewards(point.global_position)
			_show_field_notice("분해 완료 · 총기 개조 부품이 떨어졌습니다")
		"rescue":
			_add_fatigue(FATIGUE_RESCUE_GAIN)
			_add_rescued_follower(point.global_position)
			_show_field_notice("피난민 구조 · 호송 중 이동 속도 감소")
	field_interactions.erase(point)
	nearby_field_interaction = null
	field_interaction_hold_time = 0.0
	field_interaction_keyboard_held = false
	field_interaction_touch_held = false
	if field_interaction_panel:
		field_interaction_panel.visible = false
	point.queue_free()
	_update_equipment_ui()


func _spawn_salvage_rewards(origin: Vector3) -> void:
	var component_ids := ["rubber_gasket", "scope_lens", "magazine_spring"]
	var component_names := {
		"rubber_gasket": "소음기용 고무 패킹",
		"scope_lens": "스코프 렌즈",
		"magazine_spring": "탄창 스프링",
	}
	var reward_count := spawn_random.randi_range(1, 2)
	for reward_index in reward_count:
		var component_id: String = component_ids[spawn_random.randi_range(0, component_ids.size() - 1)]
		var angle := TAU * float(reward_index) / float(maxi(reward_count, 1)) + spawn_random.randf_range(-0.5, 0.5)
		var offset := Vector3(cos(angle), 0, sin(angle)) * (0.75 + reward_index * 0.2)
		_create_loot_pickup("mod_component", origin + offset, {
			"component_id": component_id,
			"amount": 1,
			"display_name": component_names[component_id],
		})


func _add_rescued_follower(world_position: Vector3) -> void:
	var follower := RESCUED_CAT_FOLLOWER_SCRIPT.new() as CharacterBody3D
	follower.name = "RescuedCat_%02d" % (rescued_followers.size() + 1)
	add_child(follower)
	follower.global_position = Vector3(world_position.x, 0.05, world_position.z)
	follower.call("setup", player, rescued_followers.size())
	rescued_followers.append(follower)


func _show_field_notice(message: String) -> void:
	if not ammo_notice:
		return
	ammo_notice.text = message
	ammo_notice.visible = true
	ammo_notice_time = 2.4


func _update_fatigue(delta: float, is_moving: bool) -> void:
	var rate := FATIGUE_MOVING_RATE if is_moving else FATIGUE_IDLE_RATE
	if rescued_followers.size() > 0 and is_moving:
		rate *= 1.0 + minf(0.6, rescued_followers.size() * 0.12)
	_add_fatigue(rate * delta)
	GameState.fatigue = fatigue
	if fatigue_bar:
		fatigue_bar.value = fatigue
	if fatigue_label:
		var penalty_text := " · 탈진: 이동 저하" if fatigue >= 99.9 else ""
		fatigue_label.text = "피로  %d%%%s" % [roundi(fatigue), penalty_text]


func _add_fatigue(amount: float) -> void:
	if amount <= 0.0:
		return
	fatigue = clampf(fatigue + amount, 0.0, FATIGUE_MAX)
	GameState.fatigue = fatigue
	if fatigue_bar:
		fatigue_bar.value = fatigue
	if fatigue_label:
		var penalty_text := " · 탈진: 이동 저하" if fatigue >= 99.9 else ""
		fatigue_label.text = "피로  %d%%%s" % [roundi(fatigue), penalty_text]


func _get_fatigue_speed_multiplier() -> float:
	if fatigue < 70.0:
		return 1.0
	var exhaustion := inverse_lerp(70.0, FATIGUE_MAX, fatigue)
	return lerpf(1.0, FATIGUE_SPEED_MIN, exhaustion)


func _get_escort_speed_multiplier() -> float:
	return maxf(0.65, 1.0 - rescued_followers.size() * ESCORT_SPEED_PENALTY)


func _commit_rescued_followers() -> int:
	var rescued_count := rescued_followers.size()
	if rescued_count <= 0:
		return 0
	var accepted: int = GameState.try_add_rescued_workers(rescued_count)
	rescued_followers.clear()
	return accepted


func _begin_extraction() -> void:
	if extraction_transition_active:
		return
	extraction_transition_active = true
	extraction_prompt.visible = false
	var rescued_count := _commit_rescued_followers()
	extraction_success_label.text = (
		"탈출 성공\n주민 %d명 후송 완료" % rescued_count
		if rescued_count > 0
		else "탈출 성공"
	)
	_save_run_state()
	var tween := create_tween()
	tween.tween_property(extraction_fade, "color:a", 1.0, 0.65)
	tween.tween_property(extraction_success_label, "modulate:a", 1.0, 0.32)
	tween.tween_interval(0.9)
	tween.tween_callback(func() -> void:
		GameState.returning_from_shelter = false
		GameState.register_shelter_return()
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
	GameState.fatigue = fatigue
	GameState.save_persistent_state()


func _input(event: InputEvent) -> void:
	if player_death_sequence_active:
		return
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
		if key in [KEY_I, KEY_B] and key_event.pressed:
			if _is_tactical_map_open():
				tactical_map.call("close")
			_toggle_inventory()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_ESCAPE and key_event.pressed and _is_inventory_open():
			_toggle_inventory()
			get_viewport().set_input_as_handled()
			return
		if _is_inventory_open() or _is_tactical_map_open() or extraction_transition_active:
			return
		if key == KEY_E:
			if is_instance_valid(nearby_field_interaction):
				var interaction_type := str(nearby_field_interaction.get_meta("interaction_type", ""))
				if interaction_type == "extraction" and key_event.pressed:
					_begin_extraction()
					field_interaction_keyboard_held = false
				else:
					field_interaction_keyboard_held = key_event.pressed
				pickup_keyboard_held = false
			elif key_event.pressed and is_instance_valid(nearby_ammo_pickup):
				_collect_nearby_ammo()
				pickup_keyboard_held = false
			else:
				field_interaction_keyboard_held = false
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
		if _is_inventory_button_at(mouse_event.position):
			return
		if fire_button and fire_button.visible and fire_button.get_global_rect().has_point(mouse_event.position):
			return
		_handle_combat_mouse_button(mouse_event)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if _is_inventory_open():
			return
		var touch := event as InputEventScreenTouch
		if _is_inventory_button_at(touch.position):
			return
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
			if laser_aim_held:
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
	Engine.time_scale = 1.0
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
