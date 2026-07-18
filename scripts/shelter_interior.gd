extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const FLOOR_TEXTURE_PATH := "res://assets/interiors/shelter_floor_topdown_v3.png"
const WALL_TEXTURE_PATH := "res://assets/interiors/shelter_wall_panel_v3.png"
const ESCAPE_PIPE_TEXTURE_PATH := "res://assets/interiors/shelter_escape_pipe_v1.png"
const BED_MODULE_SCENE := preload("res://scenes/modules/shelter_bed_module.tscn")
const WORKBENCH_MODULE_SCENE := preload("res://scenes/modules/shelter_workbench_module.tscn")
const SCRATCHER_BANK_MODULE_SCENE := preload("res://scenes/modules/scratcher_bank_module.tscn")
const CATNIP_SCRAPER_MODULE_SCENE := preload("res://scenes/modules/catnip_scraper_module.tscn")
const DORMITORY_RACK_TEXTURE := preload("res://assets/interiors/modules/dormitory_rack_v1.png")
const SHELTER_RESIDENT_SCRIPT := preload("res://scripts/shelter_resident_cat.gd")
const SHELTER_MERCHANT_SCRIPT := preload("res://scripts/shelter_merchant.gd")
const MERCHANT_TEXTURE := preload("res://assets/characters/merchant_cat/merchant_down_left_idle.png")
const MOVE_SPEED := 4.6
const CAT_ANIMATION_ROOT := "res://assets/characters/cat_8way"
const CAT_ROLL_ANIMATION_ROOT := "res://assets/characters/cat_roll"
const ROLL_COOLDOWN_INDICATOR_SCRIPT := preload("res://scripts/roll_cooldown_indicator.gd")
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
const ROLL_DURATION := 0.46
const ROLL_STAMINA_MAX := 100.0
const ROLL_STAMINA_COST := 35.0
const ROLL_STAMINA_RECOVERY_PER_SECOND := 30.0
const ROLL_START_SPEED := 18.0
const ROLL_END_SPEED := 4.2
const ROLL_AFTERIMAGE_INTERVAL := 0.06
const ROOM_ART_SIZE := Vector2(44.0, 25.0)
const PLAYER_BOUNDS := Vector2(21.2, 11.7)
const BED_MODULE_PLATE_SIZE := Vector2(2.65, 3.45)
const STAGE_ONE_BED_POSITIONS := [
	Vector3(-20.05, 0, -8.0),
	Vector3(-20.05, 0, -4.35),
	Vector3(-20.05, 0, -0.7),
	Vector3(-20.05, 0, 2.95),
	Vector3(-20.05, 0, 6.6),
]
const WORKBENCH_POSITION := Vector3(6.0, 0.0, -11.72)
const SCRATCHER_BANK_POSITION := Vector3(13.1, 0.0, -11.74)
const CATNIP_SCRAPER_POSITION := Vector3(-6.0, 0.0, -11.74)
const DORMITORY_RACK_POSITIONS := [
	Vector3(-18.0, 0.0, 10.85),
	Vector3(-13.5, 0.0, 10.85),
	Vector3(-9.0, 0.0, 10.85),
	Vector3(-4.5, 0.0, 10.85),
	Vector3(0.0, 0.0, 10.85),
	Vector3(4.5, 0.0, 10.85),
	Vector3(9.0, 0.0, 10.85),
	Vector3(13.5, 0.0, 10.85),
	Vector3(18.0, 0.0, 10.85),
]
const MERCHANT_POSITION := Vector3(14.35, 0.78, -8.85)
const MERCHANT_WAIT_POSITION := Vector3(15.55, 0.0, -11.7)
const RESIDENT_WAIT_POSITIONS := [
	Vector3(-17.0, 0.78, -8.0),
	Vector3(-17.0, 0.78, -4.35),
	Vector3(-17.0, 0.78, -0.7),
	Vector3(-17.0, 0.78, 2.95),
	Vector3(-17.0, 0.78, 6.6),
	Vector3(-14.9, 0.78, -5.9),
	Vector3(-14.9, 0.78, -1.3),
	Vector3(-14.9, 0.78, 3.3),
]
const SCRATCHER_WORK_POSITIONS := [
	Vector3(10.55, 0.78, -9.55),
	Vector3(11.8, 0.78, -9.55),
	Vector3(13.05, 0.78, -9.55),
	Vector3(14.3, 0.78, -9.55),
	Vector3(10.9, 0.78, -8.2),
	Vector3(12.15, 0.78, -8.2),
	Vector3(13.4, 0.78, -8.2),
	Vector3(14.65, 0.78, -8.2),
]
const CATNIP_WORK_POSITIONS := [
	Vector3(-8.2, 0.78, -9.5),
	Vector3(-6.9, 0.78, -9.5),
	Vector3(-5.6, 0.78, -9.5),
	Vector3(-4.3, 0.78, -9.5),
	Vector3(-3.0, 0.78, -9.5),
]
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const STATIONS := {
	"pipe_exit": {"position": Vector2(16.0, -10.55), "label": "파이프를 타고 도시로 올라가기", "radius": 2.2},
}
const MERCHANT_GOODS := [
	{
		"id": "762_fmj", "type": "ammo", "title": "7.62mm 보통탄 상자", "amount": 30,
		"buy_price": 42, "sell_price": 16, "icon": "res://assets/items/ammo_762.png",
		"description": "AK 계열 총기에 사용하는 보통탄 30발입니다.",
	},
	{
		"id": "canned_food", "type": "food", "title": "밀봉 통조림", "amount": 1,
		"buy_price": 64, "sell_price": 28, "icon": "",
		"description": "주민 노동과 쉘터 시설 운영에 필요한 기본 재화입니다.",
	},
	{
		"id": "scope_lens", "type": "component", "title": "스코프 렌즈", "amount": 1,
		"buy_price": 90, "sell_price": 38, "icon": "res://assets/items/mod_components/scope_lens.png",
		"description": "조준경과 정밀 모듈 제작에 사용하는 온전한 렌즈입니다.",
	},
	{
		"id": "rubber_gasket", "type": "component", "title": "고무 패킹", "amount": 1,
		"buy_price": 58, "sell_price": 24, "icon": "res://assets/items/mod_components/rubber_gasket.png",
		"description": "소음기와 반동 완충 부품 제작에 사용하는 패킹입니다.",
	},
	{
		"id": "magazine_spring", "type": "component", "title": "탄창 스프링", "amount": 1,
		"buy_price": 72, "sell_price": 30, "icon": "res://assets/items/mod_components/magazine_spring.png",
		"description": "탄창과 전술 부품 제작에 사용하는 복원력 높은 스프링입니다.",
	},
]

var player: CharacterBody3D
var survivor: AnimatedSprite3D
var shelter_camera: Camera3D
var camera_focus := Vector3.ZERO
var facing := "s"
var motion_state := "idle"
var current_station := ""
var current_module: Node3D
var prompt_label: Label
var status_label: Label
var stats_label: Label
var scrap_gain_label: Label
var shelter_upgrade_button: Button
var interact_button: Button
var roll_cooldown_indicator: Control
var touch_stick: Control
var touch_knob: Control
var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO
var roll_active := false
var roll_elapsed := 0.0
var roll_stamina := ROLL_STAMINA_MAX
var roll_afterimage_timer := 0.0
var roll_direction := Vector3.ZERO
var roll_afterimages: Array[Sprite3D] = []
var roll_audio_player: AudioStreamPlayer3D
var shelter_residents: Array[CharacterBody3D] = []
var merchant: Node3D
var merchant_waiting_marker: Node3D
var merchant_ui_layer: CanvasLayer
var merchant_shop_list: VBoxContainer
var merchant_shop_scrap_label: Label
var merchant_shop_message_label: Label
var merchant_buy_tab: Button
var merchant_sell_tab: Button
var merchant_shop_mode := "buy"
var merchant_ui_open := false
var shelter_stats_refresh_time := 0.0
var shelter_save_time := 0.0
var raid_zone_ui_layer: CanvasLayer
var raid_zone_ui_open := false


func _ready() -> void:
	add_to_group("shelter_resident_host")
	var offline_notice: Dictionary = GameState.process_shelter_progress()
	_build_room()
	_build_stage_one_modules()
	_build_player()
	_build_shelter_residents()
	_build_roll_audio()
	_build_interface()
	_setup_merchant_visit()
	_update_stats()
	_show_status(_build_offline_status_text(offline_notice))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not roll_active:
		roll_stamina = minf(
			ROLL_STAMINA_MAX,
			roll_stamina + ROLL_STAMINA_RECOVERY_PER_SECOND * delta
		)
	var input_vector := Vector2.ZERO
	if not merchant_ui_open and not raid_zone_ui_open:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if Input.is_key_pressed(KEY_A): input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D): input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W): input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S): input_vector.y += 1.0
	input_vector = input_vector.limit_length(1.0)
	if not merchant_ui_open and not raid_zone_ui_open and touch_vector.length_squared() > input_vector.length_squared():
		input_vector = touch_vector
	var world_direction := Vector3(input_vector.x + input_vector.y, 0, -input_vector.x + input_vector.y)
	if roll_active:
		_update_roll(delta)
	elif world_direction.length_squared() > 0.01:
		world_direction = world_direction.normalized()
		player.velocity = world_direction * MOVE_SPEED
		_update_facing(input_vector)
		_set_motion_state("walk")
	else:
		player.velocity = Vector3.ZERO
		_set_motion_state("idle")
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -PLAYER_BOUNDS.x, PLAYER_BOUNDS.x)
	player.position.z = clampf(player.position.z, -PLAYER_BOUNDS.y, PLAYER_BOUNDS.y)
	_update_camera(delta)
	_update_nearby_station()
	_update_roll_feedback()
	_update_live_shelter_income(delta)
	status_label.modulate.a = move_toward(status_label.modulate.a, 0.0, delta * 0.08)
	if scrap_gain_label:
		scrap_gain_label.modulate.a = move_toward(scrap_gain_label.modulate.a, 0.0, delta * 1.8)


func _build_room() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color.BLACK
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("#53645d")
	environment_resource.ambient_light_energy = 0.72
	environment.environment = environment_resource
	add_child(environment)
	var outside_material := _material(Color.BLACK)
	outside_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_plane("BlackOutside", Vector3(0, -0.12, 0), Vector2(240, 240), outside_material, self)
	var floor_material: StandardMaterial3D
	if ResourceLoader.exists(FLOOR_TEXTURE_PATH):
		floor_material = _texture_material(load(FLOOR_TEXTURE_PATH) as Texture2D)
		floor_material.texture_repeat = true
		floor_material.uv1_scale = Vector3(ROOM_ART_SIZE.x / 8.0, ROOM_ART_SIZE.y / 8.0, 1.0)
	else:
		floor_material = _material(Color("#242c2a"))
	_add_plane("ShelterInteriorArt", Vector3(0, 0, 0), ROOM_ART_SIZE, floor_material, self)
	var wall_material := _material(Color("#202a31"))
	if ResourceLoader.exists(WALL_TEXTURE_PATH):
		wall_material = _texture_material(load(WALL_TEXTURE_PATH) as Texture2D)
	_build_visible_walls(wall_material)
	_build_escape_pipe()
	_add_obstacle("NorthWallCollision", Vector3(0, 1.5, -12.5), Vector3(44.0, 3.0, 0.55))
	_add_obstacle("SouthWallCollision", Vector3(0, 1.5, 12.5), Vector3(44.0, 3.0, 0.55))
	_add_obstacle("WestWallCollision", Vector3(-22.0, 1.5, 0), Vector3(0.55, 3.0, 25.0))
	_add_obstacle("EastWallCollision", Vector3(22.0, 1.5, 0), Vector3(0.55, 3.0, 25.0))
	shelter_camera = Camera3D.new()
	shelter_camera.name = "ShelterCamera"
	add_child(shelter_camera)
	shelter_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	shelter_camera.size = 27.0
	shelter_camera.position = Vector3(18.0, 18.0, 18.0)
	shelter_camera.look_at(Vector3.ZERO)
	shelter_camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -38, 0)
	light.light_energy = 0.95
	add_child(light)


func _build_visible_walls(wall_material: Material) -> void:
	_add_segmented_wall("NorthWall", Vector3(0, 1.5, -12.5), Vector3(44.0, 3.0, 0.55), true, wall_material)
	_add_segmented_wall("WestWall", Vector3(-22.0, 1.5, 0), Vector3(0.55, 3.0, 25.0), false, wall_material)
	var light_material := _emissive_material(Color("#55dce9"), 2.5)
	for x in [-18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0]:
		_add_visual_box("NorthLight", Vector3(x, 1.35, -12.18), Vector3(1.45, 0.12, 0.08), light_material, self)
	for z in [-9.0, -3.0, 3.0, 9.0]:
		_add_visual_box("WestLight", Vector3(-21.68, 1.35, z), Vector3(0.08, 0.12, 1.45), light_material, self)


func _add_segmented_wall(prefix: String, position: Vector3, size: Vector3, along_x: bool, material: Material) -> void:
	var total := size.x if along_x else size.z
	var segment_count := ceili(total / 3.3)
	var segment_length := total / float(segment_count)
	for index in segment_count:
		var offset := -total * 0.5 + segment_length * (float(index) + 0.5)
		var segment_position := position
		var segment_size := size
		if along_x:
			segment_position.x += offset
			segment_size.x = segment_length - 0.035
		else:
			segment_position.z += offset
			segment_size.z = segment_length - 0.035
		_add_visual_box("%s%02d" % [prefix, index + 1], segment_position, segment_size, material, self)


func _build_escape_pipe() -> void:
	if not ResourceLoader.exists(ESCAPE_PIPE_TEXTURE_PATH):
		return
	var pipe := Sprite3D.new()
	pipe.name = "EscapePipe"
	pipe.position = Vector3(16.0, 2.15, -12.12)
	pipe.texture = load(ESCAPE_PIPE_TEXTURE_PATH) as Texture2D
	pipe.pixel_size = 0.0043
	pipe.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pipe.shaded = false
	pipe.transparent = true
	pipe.no_depth_test = true
	pipe.render_priority = 30
	pipe.add_to_group("shelter_exit_pipe")
	add_child(pipe)
	_add_obstacle("EscapePipeCollision", Vector3(16.0, 1.0, -11.75), Vector3(1.65, 2.0, 1.05))


func _build_stage_one_modules() -> void:
	var module_root := Node3D.new()
	module_root.name = "StageOneModules"
	module_root.set_meta("stage", 1)
	module_root.set_meta("cat_capacity", GameState.get_resident_capacity())
	module_root.set_meta("module_grid_size", BED_MODULE_PLATE_SIZE)
	add_child(module_root)
	for index in STAGE_ONE_BED_POSITIONS.size():
		_build_module_plate(module_root, STAGE_ONE_BED_POSITIONS[index], index + 1, 90.0)
		var bed := BED_MODULE_SCENE.instantiate() as Node3D
		bed.name = "BedModule%02d" % (index + 1)
		bed.position = STAGE_ONE_BED_POSITIONS[index]
		bed.rotation_degrees.y = 90.0
		bed.set("bed_index", index + 1)
		module_root.add_child(bed)
	var workbench := WORKBENCH_MODULE_SCENE.instantiate() as Node3D
	workbench.name = "WeaponWorkbench"
	workbench.position = WORKBENCH_POSITION
	module_root.add_child(workbench)
	var bank := SCRATCHER_BANK_MODULE_SCENE.instantiate() as Node3D
	bank.name = "ScratcherBank"
	bank.position = SCRATCHER_BANK_POSITION
	module_root.add_child(bank)
	var catnip_scraper := CATNIP_SCRAPER_MODULE_SCENE.instantiate() as Node3D
	catnip_scraper.name = "CatnipScraper"
	catnip_scraper.position = CATNIP_SCRAPER_POSITION
	module_root.add_child(catnip_scraper)
	_build_tier_dormitory_racks(module_root)


func _build_tier_dormitory_racks(module_root: Node3D) -> void:
	var rack_count_by_tier := {1: 0, 2: 1, 3: 3, 4: 6, 5: 9}
	var rack_count := int(rack_count_by_tier.get(GameState.shelter_tier, 0))
	for index in rack_count:
		if module_root.get_node_or_null("DormitoryRack%02d" % (index + 1)) != null:
			continue
		var rack := Sprite3D.new()
		rack.name = "DormitoryRack%02d" % (index + 1)
		rack.texture = DORMITORY_RACK_TEXTURE
		rack.position = DORMITORY_RACK_POSITIONS[index] + Vector3(0.0, 2.05, 0.0)
		rack.pixel_size = 0.00305
		rack.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rack.shaded = false
		rack.transparent = true
		rack.no_depth_test = true
		rack.render_priority = 26
		rack.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		rack.set_meta("resident_capacity", 5)
		module_root.add_child(rack)
		_add_obstacle(
			"DormitoryRackCollision%02d" % (index + 1),
			DORMITORY_RACK_POSITIONS[index] + Vector3(0.0, 0.75, 0.0),
			Vector3(4.1, 1.5, 1.0)
		)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "ShelterPlayer"
	player.position = Vector3(0.0, 0.78, 1.5)
	camera_focus = Vector3(player.position.x, 0.0, player.position.z)
	if is_instance_valid(shelter_camera):
		shelter_camera.position = camera_focus + Vector3(18.0, 18.0, 18.0)
		shelter_camera.look_at(camera_focus)
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.3
	collision.shape = shape
	player.add_child(collision)
	survivor = AnimatedSprite3D.new()
	survivor.name = "Survivor"
	survivor.position = Vector3(0, 0.3, 0)
	survivor.pixel_size = 0.0098
	survivor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	survivor.shaded = false
	survivor.transparent = true
	survivor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	survivor.no_depth_test = true
	survivor.render_priority = 127
	survivor.sprite_frames = _create_cat_frames()
	player.add_child(survivor)
	_play_directional_animation()


func _build_shelter_residents() -> void:
	GameState._ensure_resident_records()
	for resident_id in GameState.resident_cat_ids:
		var resident := SHELTER_RESIDENT_SCRIPT.new() as CharacterBody3D
		var waiting_index := shelter_residents.size()
		resident.name = "ShelterResident_%s" % resident_id
		resident.call("configure", resident_id, _resident_wait_position(waiting_index))
		add_child(resident)
		shelter_residents.append(resident)
	refresh_shelter_residents(true)


func _setup_merchant_visit() -> void:
	GameState.roll_merchant_visit()
	match GameState.merchant_status:
		"waiting":
			_build_merchant_waiting_marker()
		"inside":
			_spawn_merchant()


func _build_merchant_waiting_marker() -> void:
	if is_instance_valid(merchant_waiting_marker):
		return
	merchant_waiting_marker = Node3D.new()
	merchant_waiting_marker.name = "MerchantWaitingBubble"
	merchant_waiting_marker.position = MERCHANT_WAIT_POSITION
	add_child(merchant_waiting_marker)

	var portrait := Sprite3D.new()
	portrait.name = "MerchantFace"
	portrait.texture = _merchant_face_texture()
	portrait.position = Vector3(0.0, 3.05, 0.0)
	portrait.pixel_size = 0.0074
	portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	portrait.shaded = false
	portrait.transparent = true
	portrait.no_depth_test = true
	portrait.render_priority = 127
	portrait.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	merchant_waiting_marker.add_child(portrait)

	var dialogue := Label3D.new()
	dialogue.name = "MerchantKnockLine"
	dialogue.text = "문 좀 열어주실 수 있겠냥?"
	dialogue.position = Vector3(-1.95, 3.08, 0.0)
	dialogue.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dialogue.no_depth_test = true
	dialogue.render_priority = 127
	dialogue.font = FONT
	dialogue.font_size = 42
	dialogue.pixel_size = 0.0052
	dialogue.modulate = Color("#f5e6bd")
	dialogue.outline_modulate = Color(0.015, 0.02, 0.018, 0.96)
	dialogue.outline_size = 12
	merchant_waiting_marker.add_child(dialogue)

func _spawn_merchant() -> void:
	if is_instance_valid(merchant):
		return
	merchant = SHELTER_MERCHANT_SCRIPT.new() as Node3D
	merchant.position = MERCHANT_POSITION
	add_child(merchant)


func _merchant_face_texture() -> AtlasTexture:
	var frame_width := float(MERCHANT_TEXTURE.get_width()) / 4.0
	var texture := AtlasTexture.new()
	texture.atlas = MERCHANT_TEXTURE
	texture.region = Rect2(frame_width * 0.20, 12.0, frame_width * 0.56, 112.0)
	return texture


func refresh_shelter_residents(snap := false) -> void:
	GameState._ensure_resident_records()
	var waiting_ids: Array[String] = []
	for resident_id in GameState.resident_cat_ids:
		if not GameState.assigned_worker_ids.has(resident_id) and not GameState.assigned_catnip_worker_ids.has(resident_id):
			waiting_ids.append(resident_id)
	for resident in shelter_residents:
		if not is_instance_valid(resident):
			continue
		var resident_id := str(resident.get_meta("resident_id", ""))
		var kneading_index := GameState.assigned_worker_ids.find(resident_id)
		var catnip_index := GameState.assigned_catnip_worker_ids.find(resident_id)
		var assignment_kind := "waiting"
		var target := _resident_wait_position(waiting_ids.find(resident_id))
		var focus := target
		if kneading_index >= 0:
			assignment_kind = "kneading"
			target = _scratcher_work_position(kneading_index)
			focus = SCRATCHER_BANK_POSITION
		elif catnip_index >= 0:
			assignment_kind = "catnip"
			target = _catnip_work_position(catnip_index)
			focus = CATNIP_SCRAPER_POSITION
		resident.call("set_work_assignment", assignment_kind, target, focus, snap)


func _resident_wait_position(index: int) -> Vector3:
	if index >= 0 and index < RESIDENT_WAIT_POSITIONS.size():
		return RESIDENT_WAIT_POSITIONS[index]
	var overflow := maxi(0, index - RESIDENT_WAIT_POSITIONS.size())
	return Vector3(-14.6 + float(overflow % 7) * 1.55, 0.78, 8.0 - float(overflow / 7) * 1.45)


func _scratcher_work_position(index: int) -> Vector3:
	if index >= 0 and index < SCRATCHER_WORK_POSITIONS.size():
		return SCRATCHER_WORK_POSITIONS[index]
	var overflow := maxi(0, index - SCRATCHER_WORK_POSITIONS.size())
	return Vector3(10.55 + float(overflow % 4) * 1.25, 0.78, -6.9 + float(overflow / 4) * 1.25)


func _catnip_work_position(index: int) -> Vector3:
	if index >= 0 and index < CATNIP_WORK_POSITIONS.size():
		return CATNIP_WORK_POSITIONS[index]
	return CATNIP_WORK_POSITIONS[CATNIP_WORK_POSITIONS.size() - 1]


func _update_camera(delta: float) -> void:
	if not is_instance_valid(shelter_camera) or not is_instance_valid(player):
		return
	var desired_focus := Vector3(player.position.x, 0.0, player.position.z)
	var follow_weight := 1.0 - exp(-delta * 5.5)
	camera_focus = camera_focus.lerp(desired_focus, follow_weight)
	shelter_camera.position = camera_focus + Vector3(18.0, 18.0, 18.0)
	shelter_camera.look_at(camera_focus)


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var theme := Theme.new()
	theme.default_font = FONT
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 22)
	panel.size = Vector2(370, 194)
	panel.theme = theme
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.023, 0.92), Color("#577a69")))
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 3)
	margin.add_child(stats_box)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_box.add_child(stats_label)
	shelter_upgrade_button = Button.new()
	shelter_upgrade_button.add_theme_font_override("font", FONT)
	shelter_upgrade_button.add_theme_font_size_override("font_size", 13)
	shelter_upgrade_button.pressed.connect(_upgrade_shelter_tier)
	stats_box.add_child(shelter_upgrade_button)
	scrap_gain_label = Label.new()
	scrap_gain_label.add_theme_font_override("font", FONT)
	scrap_gain_label.add_theme_font_size_override("font_size", 14)
	scrap_gain_label.add_theme_color_override("font_color", Color("#f0d16f"))
	scrap_gain_label.modulate.a = 0.0
	stats_box.add_child(scrap_gain_label)
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-220, -112)
	prompt_label.size = Vector2(440, 52)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_override("font", FONT)
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 6)
	canvas.add_child(prompt_label)
	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-270, 24)
	status_label.size = Vector2(540, 58)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", FONT)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color("#b7f0d4"))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 6)
	canvas.add_child(status_label)
	interact_button = Button.new()
	interact_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact_button.position = Vector2(-154, -142)
	interact_button.size = Vector2(118, 72)
	interact_button.text = "상호작용"
	interact_button.add_theme_font_override("font", FONT)
	interact_button.add_theme_font_size_override("font_size", 17)
	interact_button.pressed.connect(_interact)
	canvas.add_child(interact_button)
	roll_cooldown_indicator = ROLL_COOLDOWN_INDICATOR_SCRIPT.new() as Control
	roll_cooldown_indicator.name = "ShelterRollCooldownIndicator"
	canvas.add_child(roll_cooldown_indicator)
	_build_touch_stick(canvas)


func _open_merchant_arrival_dialog() -> void:
	if merchant_ui_open:
		return
	merchant_ui_open = true
	touch_vector = Vector2.ZERO
	roll_active = false
	_set_motion_state("idle")
	merchant_ui_layer = CanvasLayer.new()
	merchant_ui_layer.name = "MerchantArrivalLayer"
	merchant_ui_layer.layer = 60
	add_child(merchant_ui_layer)

	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	merchant_ui_layer.add_child(root_control)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.008, 0.01, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 310)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.034, 0.031, 0.98), Color("#9a8153")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for margin_name in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(margin_name, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var title := Label.new()
	title.text = "하수구 밖에서 들려오는 목소리"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#ead69c"))
	box.add_child(title)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(142, 142)
	portrait.texture = _merchant_face_texture()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(portrait)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dialogue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(dialogue_box)
	var line := Label.new()
	line.text = "문 좀 열어주실 수 있겠냥?\n필요한 물건이라면 제법 챙겨 왔다냥."
	line.add_theme_font_override("font", FONT)
	line.add_theme_font_size_override("font_size", 19)
	line.add_theme_color_override("font_color", Color("#ebe5d4"))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_box.add_child(line)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_END
	choices.add_theme_constant_override("separation", 10)
	box.add_child(choices)
	var decline := _merchant_button("돌려보낸다", false)
	decline.pressed.connect(_decline_merchant)
	choices.add_child(decline)
	var accept := _merchant_button("들어오게 한다", true)
	accept.pressed.connect(_accept_merchant)
	choices.add_child(accept)


func _accept_merchant() -> void:
	GameState.accept_merchant_visit()
	if is_instance_valid(merchant_waiting_marker):
		merchant_waiting_marker.queue_free()
	merchant_waiting_marker = null
	_spawn_merchant()
	_close_merchant_ui()
	_show_status("행상인이 쉘터에 들어왔습니다. 말을 걸어 거래할 수 있습니다.")


func _decline_merchant() -> void:
	GameState.decline_merchant_visit()
	if is_instance_valid(merchant_waiting_marker):
		merchant_waiting_marker.queue_free()
	merchant_waiting_marker = null
	_close_merchant_ui()
	_show_status("행상인을 돌려보냈습니다. 다음 복귀 때 다시 찾아올 수도 있습니다.")


func _open_merchant_shop() -> void:
	if merchant_ui_open:
		return
	merchant_ui_open = true
	touch_vector = Vector2.ZERO
	roll_active = false
	_set_motion_state("idle")
	merchant_shop_mode = "buy"
	merchant_ui_layer = CanvasLayer.new()
	merchant_ui_layer.name = "MerchantShopLayer"
	merchant_ui_layer.layer = 60
	add_child(merchant_ui_layer)

	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	merchant_ui_layer.add_child(root_control)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.004, 0.007, 0.009, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 580)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.033, 0.031, 0.99), Color("#8f7950")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(74, 74)
	portrait.texture = _merchant_face_texture()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(portrait)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)
	var title := Label.new()
	title.text = "떠돌이 행상인의 교환 가방"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("#ead69c"))
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "고철과 물자를 교환합니다. 가격은 한 묶음 기준입니다."
	subtitle.add_theme_font_override("font", FONT)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#9baaa3"))
	title_box.add_child(subtitle)
	merchant_shop_scrap_label = Label.new()
	merchant_shop_scrap_label.add_theme_font_override("font", FONT)
	merchant_shop_scrap_label.add_theme_font_size_override("font_size", 17)
	merchant_shop_scrap_label.add_theme_color_override("font_color", Color("#e8cb72"))
	merchant_shop_scrap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(merchant_shop_scrap_label)
	var close := _merchant_button("닫기", false)
	close.pressed.connect(_close_merchant_ui)
	header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	merchant_buy_tab = _merchant_button("구매", true)
	merchant_buy_tab.pressed.connect(func() -> void: _set_merchant_shop_mode("buy"))
	tabs.add_child(merchant_buy_tab)
	merchant_sell_tab = _merchant_button("판매", false)
	merchant_sell_tab.pressed.connect(func() -> void: _set_merchant_shop_mode("sell"))
	tabs.add_child(merchant_sell_tab)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	merchant_shop_list = VBoxContainer.new()
	merchant_shop_list.add_theme_constant_override("separation", 8)
	scroll.add_child(merchant_shop_list)
	merchant_shop_message_label = Label.new()
	merchant_shop_message_label.custom_minimum_size.y = 30
	merchant_shop_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	merchant_shop_message_label.add_theme_font_override("font", FONT)
	merchant_shop_message_label.add_theme_font_size_override("font_size", 14)
	merchant_shop_message_label.add_theme_color_override("font_color", Color("#b8d9c9"))
	box.add_child(merchant_shop_message_label)
	_refresh_merchant_shop()


func _set_merchant_shop_mode(mode: String) -> void:
	merchant_shop_mode = mode
	merchant_shop_message_label.text = ""
	_refresh_merchant_shop()


func _refresh_merchant_shop() -> void:
	if merchant_shop_list == null:
		return
	for child in merchant_shop_list.get_children():
		merchant_shop_list.remove_child(child)
		child.queue_free()
	merchant_shop_scrap_label.text = "고철  %d" % GameState.scrap
	merchant_buy_tab.disabled = merchant_shop_mode == "buy"
	merchant_sell_tab.disabled = merchant_shop_mode == "sell"
	for good_variant in MERCHANT_GOODS:
		var good: Dictionary = good_variant
		merchant_shop_list.add_child(_merchant_trade_row(good))


func _merchant_trade_row(good: Dictionary) -> Button:
	var buying := merchant_shop_mode == "buy"
	var price := int(good["buy_price"] if buying else good["sell_price"])
	var owned := _merchant_item_count(good)
	var action := "구매" if buying else "판매"
	var button := _merchant_button(
		"%s  x%d\n%s    ·    보유 %d    ·    고철 %d" % [
			str(good["title"]), int(good["amount"]), str(good["description"]), owned, price,
		],
		buying
	)
	button.name = "MerchantGood_%s" % str(good["id"])
	button.custom_minimum_size = Vector2(720, 72)
	button.text = "%s    %s" % [button.text, action]
	var icon_path := str(good.get("icon", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		button.icon = load(icon_path) as Texture2D
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = GameState.scrap < price if buying else owned < int(good["amount"])
	button.pressed.connect(func() -> void: _trade_merchant_good(good, buying))
	return button


func _trade_merchant_good(good: Dictionary, buying: bool) -> void:
	var price := int(good["buy_price"] if buying else good["sell_price"])
	var amount := int(good["amount"])
	if buying:
		if GameState.scrap < price:
			merchant_shop_message_label.text = "고철이 부족합니다."
			return
		GameState.scrap -= price
		_add_merchant_item(good, amount)
		merchant_shop_message_label.text = "%s을(를) 구매했습니다." % str(good["title"])
	else:
		if _merchant_item_count(good) < amount:
			merchant_shop_message_label.text = "판매할 물건이 부족합니다."
			return
		_add_merchant_item(good, -amount)
		GameState.scrap += price
		merchant_shop_message_label.text = "%s을(를) 판매했습니다." % str(good["title"])
	_update_stats()
	_refresh_merchant_shop()


func _merchant_item_count(good: Dictionary) -> int:
	match str(good["type"]):
		"ammo":
			return GameState.get_ammo_count(str(good["id"]))
		"food":
			return GameState.canned_food
		"component":
			return GameState.get_mod_component_count(str(good["id"]))
	return 0


func _add_merchant_item(good: Dictionary, amount: int) -> void:
	match str(good["type"]):
		"ammo":
			var ammo_id := str(good["id"])
			GameState.set_ammo_count(ammo_id, GameState.get_ammo_count(ammo_id) + amount)
		"food":
			GameState.canned_food = maxi(0, GameState.canned_food + amount)
		"component":
			GameState.add_mod_component(str(good["id"]), amount)


func _close_merchant_ui() -> void:
	merchant_ui_open = false
	if is_instance_valid(merchant_ui_layer):
		merchant_ui_layer.queue_free()
	merchant_ui_layer = null
	merchant_shop_list = null
	merchant_shop_scrap_label = null
	merchant_shop_message_label = null
	merchant_buy_tab = null
	merchant_sell_tab = null


func _merchant_button(text: String, accent: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#f0eadb"))
	var background := Color(0.12, 0.1, 0.055, 0.98) if accent else Color(0.055, 0.064, 0.062, 0.96)
	var border := Color("#d2ad5e") if accent else Color("#71857b")
	button.add_theme_stylebox_override("normal", _rounded_panel_style(background, border, 6))
	button.add_theme_stylebox_override("hover", _rounded_panel_style(Color(0.16, 0.13, 0.07, 1.0), Color("#f0cc77"), 6))
	button.add_theme_stylebox_override("disabled", _rounded_panel_style(Color(0.03, 0.035, 0.034, 0.72), Color(0.35, 0.4, 0.38, 0.3), 6))
	return button


func _rounded_panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := _panel_style(background, border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_top = 9
	style.content_margin_right = 12
	style.content_margin_bottom = 9
	return style


func _build_touch_stick(canvas: CanvasLayer) -> void:
	touch_stick = Control.new()
	touch_stick.position = Vector2(48, 500)
	touch_stick.size = Vector2(128, 128)
	touch_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(touch_stick)
	var ring := ColorRect.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.color = Color(0.35, 0.45, 0.42, 0.28)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_stick.add_child(ring)
	touch_knob = ColorRect.new()
	touch_knob.position = Vector2(40, 40)
	touch_knob.size = Vector2(48, 48)
	touch_knob.color = Color(0.65, 0.85, 0.75, 0.58)
	touch_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_stick.add_child(touch_knob)
	touch_stick.visible = DisplayServer.is_touchscreen_available()


func _update_nearby_station() -> void:
	if merchant_ui_open:
		interact_button.visible = false
		prompt_label.visible = false
		return
	var player_ground := Vector2(player.position.x, player.position.z)
	var nearest := ""
	var nearest_distance := INF
	var nearest_module: Node3D
	if GameState.merchant_status == "waiting":
		var waiting_distance := player_ground.distance_to(Vector2(MERCHANT_WAIT_POSITION.x, MERCHANT_WAIT_POSITION.z))
		if waiting_distance <= 2.8:
			nearest = "merchant_waiting"
			nearest_distance = waiting_distance
	if GameState.merchant_status == "inside" and is_instance_valid(merchant):
		var merchant_distance := player.global_position.distance_to(merchant.global_position)
		if merchant_distance <= 2.15 and merchant_distance < nearest_distance:
			nearest = "merchant_shop"
			nearest_distance = merchant_distance
	for station_name in STATIONS:
		var station: Dictionary = STATIONS[station_name]
		var distance := player_ground.distance_to(station["position"])
		if distance <= float(station["radius"]) and distance < nearest_distance:
			nearest = station_name
			nearest_distance = distance
	for node in get_tree().get_nodes_in_group("shelter_module"):
		if not (node is Node3D):
			continue
		var module := node as Node3D
		var module_radius := float(module.call("get_interaction_radius")) if module.has_method("get_interaction_radius") else 1.5
		var module_distance := player.global_position.distance_to(module.global_position)
		if module_distance <= module_radius and module_distance < nearest_distance:
			nearest = "module"
			nearest_distance = module_distance
			nearest_module = module
	if current_module != nearest_module:
		if is_instance_valid(current_module) and current_module.has_method("set_interaction_focus"):
			current_module.call("set_interaction_focus", false)
		current_module = nearest_module
		if is_instance_valid(current_module) and current_module.has_method("set_interaction_focus"):
			current_module.call("set_interaction_focus", true)
	current_station = nearest
	interact_button.visible = not current_station.is_empty()
	prompt_label.visible = not current_station.is_empty()
	if current_station.is_empty():
		prompt_label.text = ""
	elif current_station == "module" and is_instance_valid(current_module):
		prompt_label.text = "[E]  %s" % str(current_module.call("get_interaction_prompt"))
	elif current_station == "merchant_waiting":
		prompt_label.text = "[E]  하수구 밖의 낯선 고양이와 대화하기"
	elif current_station == "merchant_shop":
		prompt_label.text = "[E]  행상인과 거래하기"
	else:
		prompt_label.text = "[E]  %s" % STATIONS[current_station]["label"]


func _interact() -> void:
	if merchant_ui_open:
		return
	match current_station:
		"module":
			if is_instance_valid(current_module) and current_module.has_method("interact"):
				_show_status(str(current_module.call("interact")))
		"pipe_exit":
			_open_raid_zone_select()
		"merchant_waiting":
			_open_merchant_arrival_dialog()
		"merchant_shop":
			_open_merchant_shop()
	_update_stats()


func _update_stats() -> void:
	GameState._ensure_resident_records()
	stats_label.text = "SHELTER 01  ·  Tier %d\n체력 %d/100   주민 %d/%d\n고철 %d   캣닢 %.1f\n통조림 %d   츄르 %d\n꾹꾹이 %d/%d   스크래핑 %d/%d" % [
		GameState.shelter_tier,
		GameState.player_health,
		GameState.rescued_workers,
		GameState.get_resident_capacity(),
		GameState.scrap,
		GameState.catnip,
		GameState.canned_food,
		GameState.churu,
		GameState.get_active_scratcher_workers(),
		GameState.get_scratcher_worker_slots(),
		GameState.get_active_catnip_workers(),
		GameState.get_catnip_worker_slots(),
	]
	if shelter_upgrade_button:
		var cost := GameState.get_shelter_upgrade_cost()
		if cost.is_empty():
			shelter_upgrade_button.text = "쉘터 최고 Tier"
			shelter_upgrade_button.disabled = true
		else:
			var scrap_cost := int(cost.get("scrap", 0))
			var churu_cost := int(cost.get("churu", 0))
			shelter_upgrade_button.text = "Tier %d 확장  ·  고철 %d + 츄르 %d" % [GameState.shelter_tier + 1, scrap_cost, churu_cost]
			shelter_upgrade_button.disabled = GameState.scrap < scrap_cost or GameState.churu < churu_cost


func _upgrade_shelter_tier() -> void:
	if GameState.try_upgrade_shelter_tier():
		var module_root := get_node_or_null("StageOneModules") as Node3D
		if module_root:
			_build_tier_dormitory_racks(module_root)
		refresh_shelter_residents(false)
		_show_status("쉘터 Tier %d 확장 완료 · 수용 %d · 꾹꾹이 %d · 스크래핑 %d" % [
			GameState.shelter_tier,
			GameState.get_resident_capacity(),
			GameState.get_scratcher_worker_slots(),
			GameState.get_catnip_worker_slots(),
		])
		GameState.save_persistent_state()
	_update_stats()


func _update_live_shelter_income(delta: float) -> void:
	var gained := GameState.tick_shelter_live(delta)
	shelter_save_time += delta
	if shelter_save_time >= 10.0:
		shelter_save_time = 0.0
		GameState.save_persistent_state()
	shelter_stats_refresh_time += delta
	if shelter_stats_refresh_time >= 0.5:
		shelter_stats_refresh_time = 0.0
		_update_stats()
	if gained > 0 and scrap_gain_label:
		scrap_gain_label.text = "+%d 고철   %.2f/s" % [gained, GameState.get_scrap_per_second()]
		scrap_gain_label.modulate.a = 1.0


func _open_raid_zone_select() -> void:
	if raid_zone_ui_open:
		return
	raid_zone_ui_open = true
	touch_vector = Vector2.ZERO
	player.velocity = Vector3.ZERO
	_set_motion_state("idle")
	raid_zone_ui_layer = CanvasLayer.new()
	raid_zone_ui_layer.name = "RaidZoneSelectLayer"
	raid_zone_ui_layer.layer = 70
	add_child(raid_zone_ui_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.004, 0.007, 0.009, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	raid_zone_ui_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raid_zone_ui_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(840, 650)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.033, 0.031, 0.99), Color("#8f7950")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for margin_name in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(margin_name, 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "도시 탐색 구역 선택"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ead69c"))
	header.add_child(title)
	var close := Button.new()
	close.text = "닫기"
	close.add_theme_font_override("font", FONT)
	close.pressed.connect(_close_raid_zone_select)
	header.add_child(close)
	var subtitle := Label.new()
	subtitle.text = "쉘터 Tier가 오르면 더 위험한 서울 구역과 보스 보상이 해금됩니다."
	subtitle.add_theme_font_override("font", FONT)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("#aebdb5"))
	box.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for zone_id in GameState.get_raid_zone_ids():
		list.add_child(_build_raid_zone_row(zone_id))


func _build_raid_zone_row(zone_id: String) -> Control:
	var zone := GameState.get_raid_zone(zone_id)
	var unlocked := GameState.is_raid_zone_unlocked(zone_id)
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(760, 92)
	row.add_theme_stylebox_override("panel", _panel_style(
		Color(0.055, 0.063, 0.061, 0.94) if unlocked else Color(0.025, 0.028, 0.03, 0.72),
		Color("#667e70") if unlocked else Color(0.34, 0.36, 0.36, 0.45)
	))
	var margin := MarginContainer.new()
	for margin_name in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(margin_name, 12)
	row.add_child(margin)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info)
	var name_label := Label.new()
	name_label.text = "%s  ·  위협 %d%%" % [str(zone.get("name", zone_id)), roundi(float(zone.get("threat", 0.0)) * 100.0)]
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color("#f0e6c8") if unlocked else Color("#737b77"))
	info.add_child(name_label)
	var description := Label.new()
	description.text = str(zone.get("description", ""))
	description.add_theme_font_override("font", FONT)
	description.add_theme_font_size_override("font_size", 13)
	description.add_theme_color_override("font_color", Color("#b7c8bf") if unlocked else Color("#676d69"))
	info.add_child(description)
	var reward := Label.new()
	reward.text = "주요 보상: %s" % str(zone.get("reward", "-"))
	reward.add_theme_font_override("font", FONT)
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Color("#d3b86b") if unlocked else Color("#67645b"))
	info.add_child(reward)
	var launch := Button.new()
	launch.custom_minimum_size = Vector2(130, 58)
	launch.text = "출정" if unlocked else "Tier %d 필요" % int(zone.get("required_tier", 1))
	launch.disabled = not unlocked
	launch.add_theme_font_override("font", FONT)
	launch.add_theme_font_size_override("font_size", 15)
	launch.pressed.connect(func() -> void: _launch_raid_zone(zone_id))
	content.add_child(launch)
	return row


func _launch_raid_zone(zone_id: String) -> void:
	if not GameState.select_raid_zone(zone_id):
		return
	GameState.start_new_raid()
	GameState.returning_from_shelter = true
	GameState.save_persistent_state()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _close_raid_zone_select() -> void:
	raid_zone_ui_open = false
	if is_instance_valid(raid_zone_ui_layer):
		raid_zone_ui_layer.queue_free()
	raid_zone_ui_layer = null


func _build_module_plate(parent: Node3D, position: Vector3, slot_index: int, rotation_y := 0.0) -> void:
	var slot := Node3D.new()
	slot.name = "BedSlot%02d" % slot_index
	slot.position = position + Vector3(0.0, 0.028, 0.0)
	slot.rotation_degrees.y = rotation_y
	slot.add_to_group("shelter_module_slot")
	slot.set_meta("slot_index", slot_index)
	slot.set_meta("module_kind", "bed")
	slot.set_meta("replaceable", true)
	parent.add_child(slot)
	var plate_material := _material(Color(0.035, 0.075, 0.09, 0.82))
	plate_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plate_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_plane("ModuleFloorPlate", Vector3.ZERO, BED_MODULE_PLATE_SIZE, plate_material, slot)
	var border_material := _material(Color(0.14, 0.5, 0.58, 0.75))
	border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_visual_box("NorthBorder", Vector3(0, 0.025, -BED_MODULE_PLATE_SIZE.y * 0.5), Vector3(BED_MODULE_PLATE_SIZE.x, 0.045, 0.045), border_material, slot)
	_add_visual_box("SouthBorder", Vector3(0, 0.025, BED_MODULE_PLATE_SIZE.y * 0.5), Vector3(BED_MODULE_PLATE_SIZE.x, 0.045, 0.045), border_material, slot)
	_add_visual_box("WestBorder", Vector3(-BED_MODULE_PLATE_SIZE.x * 0.5, 0.025, 0), Vector3(0.045, 0.045, BED_MODULE_PLATE_SIZE.y), border_material, slot)
	_add_visual_box("EastBorder", Vector3(BED_MODULE_PLATE_SIZE.x * 0.5, 0.025, 0), Vector3(0.045, 0.045, BED_MODULE_PLATE_SIZE.y), border_material, slot)


func _show_status(message: String) -> void:
	status_label.text = message
	status_label.modulate.a = 1.0


func _build_offline_status_text(progress: Dictionary) -> String:
	var scrap_gain := int(progress.get("scrap", 0))
	var catnip_gain := float(progress.get("catnip", 0.0))
	var repair_gain := float(progress.get("repair", 0.0))
	if scrap_gain > 0 or catnip_gain > 0.01 or repair_gain > 0.01:
		return "오프라인 정산 · 고철 +%d · 캣닢 +%.1f · 내구도 +%.1f%%" % [scrap_gain, catnip_gain, repair_gain]
	return "쉘터에 복귀했습니다. 생산기에 주민을 배치할 수 있습니다."


func _update_facing(screen_direction: Vector2) -> void:
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % 8
	var next_facing: String = SCREEN_DIRECTION_NAMES[index]
	if facing != next_facing:
		facing = next_facing
		_play_directional_animation()


func _set_motion_state(next_state: String) -> void:
	if motion_state == next_state:
		return
	motion_state = next_state
	_play_directional_animation()


func _play_directional_animation() -> void:
	if survivor == null:
		return
	survivor.flip_h = false
	survivor.play("%s_%s" % [motion_state, facing])


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


func _input(event: InputEvent) -> void:
	if raid_zone_ui_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_raid_zone_select()
		return
	if merchant_ui_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_merchant_ui()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_SPACE:
			_try_start_roll()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch.position.x < get_viewport().get_visible_rect().size.x * 0.55:
			touch_id = touch.index
			touch_origin = touch.position
			touch_vector = Vector2.ZERO
			touch_stick.position = touch_origin - touch_stick.size * 0.5
		elif not touch.pressed and touch.index == touch_id:
			touch_id = -1
			touch_vector = Vector2.ZERO
			touch_knob.position = Vector2(40, 40)
	elif event is InputEventScreenDrag and event.index == touch_id:
		var radius := touch_stick.size.x * 0.34
		var offset: Vector2 = (event.position - touch_origin).limit_length(radius)
		touch_vector = offset / radius
		touch_knob.position = Vector2(40, 40) + offset


func _build_roll_audio() -> void:
	if not is_instance_valid(player):
		return
	roll_audio_player = AudioStreamPlayer3D.new()
	roll_audio_player.name = "ShelterRollWhoosh"
	roll_audio_player.stream = _create_roll_stream()
	roll_audio_player.unit_size = 4.0
	roll_audio_player.max_distance = 22.0
	roll_audio_player.volume_db = -6.0
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
		var sample := clampf(air * 0.34 + cloth + low, -1.0, 1.0)
		var encoded := int(sample * 32767.0)
		data[index * 2] = encoded & 0xff
		data[index * 2 + 1] = (encoded >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_roll_sound() -> void:
	if not is_instance_valid(roll_audio_player):
		return
	roll_audio_player.stop()
	roll_audio_player.pitch_scale = randf_range(0.94, 1.08)
	roll_audio_player.play()


func _try_start_roll() -> void:
	if roll_active or roll_stamina < ROLL_STAMINA_COST or not is_instance_valid(player):
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
		roll_direction = Vector3(roll_input.x + roll_input.y, 0.0, -roll_input.x + roll_input.y).normalized()
		_update_facing(roll_input)
	else:
		roll_direction = _get_current_facing_world_direction()
	roll_active = true
	roll_stamina = maxf(0.0, roll_stamina - ROLL_STAMINA_COST)
	roll_elapsed = 0.0
	roll_afterimage_timer = 0.0
	_set_motion_state("roll")
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


func _spawn_roll_afterimage() -> void:
	if survivor == null or survivor.sprite_frames == null:
		return
	var ghost_texture := survivor.sprite_frames.get_frame_texture(survivor.animation, survivor.frame)
	if ghost_texture == null:
		return
	var ghost := Sprite3D.new()
	ghost.name = "ShelterRollAfterimage"
	ghost.texture = ghost_texture
	ghost.position = player.position + Vector3(0, 0.3, 0)
	ghost.pixel_size = survivor.pixel_size
	ghost.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ghost.shaded = false
	ghost.transparent = true
	ghost.no_depth_test = true
	ghost.render_priority = survivor.render_priority - 1
	ghost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.72, 0.82, 0.9, 0.42)
	add_child(ghost)
	roll_afterimages.append(ghost)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate", Color(0.62, 0.68, 0.72, 0.0), 0.28)
	tween.tween_property(ghost, "scale", Vector3.ONE * 1.08, 0.28)
	tween.finished.connect(func():
		roll_afterimages.erase(ghost)
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


func _update_roll_feedback() -> void:
	if roll_cooldown_indicator == null or shelter_camera == null or player == null:
		return
	var stamina_ratio := clampf(roll_stamina / ROLL_STAMINA_MAX, 0.0, 1.0)
	var stamina_is_active := roll_active or stamina_ratio < 0.999
	var head_position := shelter_camera.unproject_position(player.global_position + Vector3(0, 2.05, 0))
	roll_cooldown_indicator.position = head_position + Vector2(26.0, -9.0)
	roll_cooldown_indicator.call("set_cooldown_progress", stamina_ratio, stamina_is_active)


func _get_current_facing_world_direction() -> Vector3:
	match facing:
		"n": return Vector3(-1, 0, -1).normalized()
		"ne": return Vector3(0, 0, -1)
		"e": return Vector3(1, 0, -1).normalized()
		"se": return Vector3(1, 0, 0)
		"s": return Vector3(1, 0, 1).normalized()
		"sw": return Vector3(0, 0, 1)
		"w": return Vector3(-1, 0, 1).normalized()
		"nw": return Vector3(-1, 0, 0)
	return Vector3(1, 0, 1).normalized()


func _add_obstacle(node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_plane(node_name: String, position: Vector3, size: Vector2, material: Material, parent: Node) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	parent.add_child(instance)


func _add_visual_box(node_name: String, position: Vector3, size: Vector3, material: Material, parent: Node) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _texture_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
