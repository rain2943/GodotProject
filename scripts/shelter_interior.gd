extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const FLOOR_TEXTURE_PATH := "res://assets/interiors/shelter_floor_topdown_v3.png"
const WALL_TEXTURE_PATH := "res://assets/interiors/shelter_wall_panel_v3.png"
const ESCAPE_PIPE_TEXTURE_PATH := "res://assets/interiors/shelter_escape_pipe_v1.png"
const BED_MODULE_SCENE := preload("res://scenes/modules/shelter_bed_module.tscn")
const MOVE_SPEED := 4.6
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
const ROOM_ART_SIZE := Vector2(44.0, 25.0)
const PLAYER_BOUNDS := Vector2(21.2, 11.7)
const BED_MODULE_PLATE_SIZE := Vector2(2.65, 3.45)
const STAGE_ONE_BED_POSITIONS := [
	Vector3(-15.0, 0, -10.35),
	Vector3(-11.5, 0, -10.35),
	Vector3(-8.0, 0, -10.35),
	Vector3(-4.5, 0, -10.35),
	Vector3(-1.0, 0, -10.35),
]
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const STATIONS := {
	"pipe_exit": {"position": Vector2(16.0, -10.55), "label": "파이프를 타고 도시로 올라가기", "radius": 2.2},
}

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
var interact_button: Button
var touch_stick: Control
var touch_knob: Control
var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_vector := Vector2.ZERO


func _ready() -> void:
	_build_room()
	_build_stage_one_modules()
	_build_player()
	_build_interface()
	_update_stats()
	_show_status("1단계 쉘터입니다. 5개의 침대 모듈이 설치되어 있습니다.")


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
	else:
		player.velocity = Vector3.ZERO
		_set_motion_state("idle")
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -PLAYER_BOUNDS.x, PLAYER_BOUNDS.x)
	player.position.z = clampf(player.position.z, -PLAYER_BOUNDS.y, PLAYER_BOUNDS.y)
	_update_camera(delta)
	_update_nearby_station()
	status_label.modulate.a = move_toward(status_label.modulate.a, 0.0, delta * 0.08)


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
	module_root.set_meta("cat_capacity", 5)
	module_root.set_meta("module_grid_size", BED_MODULE_PLATE_SIZE)
	add_child(module_root)
	for index in STAGE_ONE_BED_POSITIONS.size():
		_build_module_plate(module_root, STAGE_ONE_BED_POSITIONS[index], index + 1)
		var bed := BED_MODULE_SCENE.instantiate() as Node3D
		bed.name = "BedModule%02d" % (index + 1)
		bed.position = STAGE_ONE_BED_POSITIONS[index]
		bed.set("bed_index", index + 1)
		module_root.add_child(bed)


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
	panel.size = Vector2(300, 128)
	panel.theme = theme
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.023, 0.92), Color("#577a69")))
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 16)
	margin.add_child(stats_label)
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
	_build_touch_stick(canvas)


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
	var player_ground := Vector2(player.position.x, player.position.z)
	var nearest := ""
	var nearest_distance := INF
	var nearest_module: Node3D
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
	else:
		prompt_label.text = "[E]  %s" % STATIONS[current_station]["label"]


func _interact() -> void:
	match current_station:
		"module":
			if is_instance_valid(current_module) and current_module.has_method("interact"):
				_show_status(str(current_module.call("interact")))
		"pipe_exit":
			GameState.start_new_raid()
			GameState.returning_from_shelter = true
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	_update_stats()


func _update_stats() -> void:
	stats_label.text = "SHELTER 01  ·  1단계\n수용 규모  5마리    침대  5개\n체력  %d / 100    고철  %d" % [GameState.player_health, GameState.scrap]


func _build_module_plate(parent: Node3D, position: Vector3, slot_index: int) -> void:
	var slot := Node3D.new()
	slot.name = "BedSlot%02d" % slot_index
	slot.position = position + Vector3(0.0, 0.028, 0.0)
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
	return frames


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
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
