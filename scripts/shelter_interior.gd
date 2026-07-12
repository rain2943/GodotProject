extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const INTERIOR_TEXTURE_PATH := "res://assets/interiors/shelter_interior_generated.png"
const MOVE_SPEED := 4.6
const FRAME_SIZE := Vector2(384, 384)
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const ANIMATION_SHEETS := {
	"s": preload("res://assets/characters/survivor_anim_s.png"),
	"se": preload("res://assets/characters/survivor_anim_se.png"),
	"e": preload("res://assets/characters/survivor_anim_e.png"),
	"ne": preload("res://assets/characters/survivor_anim_ne.png"),
	"n": preload("res://assets/characters/survivor_anim_n.png"),
}
const STATIONS := {
	"bed": {"position": Vector2(-5.4, -2.2), "label": "휴식하기", "radius": 2.2},
	"craft": {"position": Vector2(0.0, -3.8), "label": "응급키트 제작", "radius": 2.0},
	"upgrade": {"position": Vector2(5.2, -3.6), "label": "무기 강화", "radius": 2.0},
	"exit": {"position": Vector2(2.8, 4.5), "label": "도시로 나가기", "radius": 1.8},
}

var player: CharacterBody3D
var survivor: AnimatedSprite3D
var facing := "s"
var motion_state := "idle"
var current_station := ""
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
	_build_player()
	_build_interface()
	_update_stats()
	_show_status("쉘터 내부입니다. 침대와 작업 설비에 가까이 가세요.")


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
	player.position.x = clampf(player.position.x, -7.7, 7.7)
	player.position.z = clampf(player.position.z, -4.8, 4.8)
	_update_nearby_station()
	status_label.modulate.a = move_toward(status_label.modulate.a, 0.0, delta * 0.08)


func _build_room() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color.BLACK
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("#53645d")
	environment_resource.ambient_light_energy = 0.72
	environment.environment = environment_resource
	add_child(environment)
	_add_plane("BlackOutside", Vector3(0, -0.12, 0), Vector2(52, 52), _material(Color.BLACK), self)
	var floor_material: StandardMaterial3D
	if ResourceLoader.exists(INTERIOR_TEXTURE_PATH):
		floor_material = _texture_material(load(INTERIOR_TEXTURE_PATH) as Texture2D)
	else:
		floor_material = _material(Color("#242c2a"))
	_add_plane("ShelterInteriorArt", Vector3(0, 0, 0), Vector2(20, 14), floor_material, self)
	var wall_material := _material(Color("#1b2422"))
	_add_box("NorthWall", Vector3(0, 1.4, -5.7), Vector3(17, 2.8, 0.3), wall_material, self)
	_add_box("SouthWallLeft", Vector3(-3.0, 1.4, 5.7), Vector3(11.0, 2.8, 0.3), wall_material, self)
	_add_box("SouthWallRight", Vector3(6.0, 1.4, 5.7), Vector3(5.0, 2.8, 0.3), wall_material, self)
	_add_box("WestWall", Vector3(-8.5, 1.4, 0), Vector3(0.3, 2.8, 11.7), wall_material, self)
	_add_box("EastWall", Vector3(8.5, 1.4, -1.5), Vector3(0.3, 2.8, 8.7), wall_material, self)
	_add_station_marker("BedMarker", Vector3(-5.4, 0.05, -2.2), Color("#65a9c9"))
	_add_station_marker("CraftMarker", Vector3(0, 0.05, -3.8), Color("#e1b65e"))
	_add_station_marker("UpgradeMarker", Vector3(5.2, 0.05, -3.6), Color("#65df9e"))
	_add_station_marker("ExitMarker", Vector3(2.8, 0.05, 4.5), Color("#63e5c6"))
	_add_obstacle("BedCollision", Vector3(-5.4, 0.45, -2.2), Vector3(3.7, 0.9, 1.8))
	_add_obstacle("WorkbenchCollision", Vector3(0, 0.55, -4.35), Vector3(3.8, 1.1, 1.0))
	_add_obstacle("UpgradeCollision", Vector3(5.2, 0.8, -4.35), Vector3(2.5, 1.6, 1.0))
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.5
	camera.position = Vector3(10.5, 12.0, 10.5)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -38, 0)
	light.light_energy = 0.95
	add_child(light)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "ShelterPlayer"
	player.position = Vector3(2.8, 0.78, 3.5)
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
	survivor.pixel_size = 0.0068
	survivor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	survivor.shaded = false
	survivor.transparent = true
	survivor.no_depth_test = true
	survivor.render_priority = 127
	survivor.sprite_frames = _create_character_frames()
	player.add_child(survivor)
	_play_directional_animation()


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
	for station_name in STATIONS:
		var station: Dictionary = STATIONS[station_name]
		var distance := player_ground.distance_to(station["position"])
		if distance <= float(station["radius"]) and distance < nearest_distance:
			nearest = station_name
			nearest_distance = distance
	current_station = nearest
	interact_button.visible = not current_station.is_empty()
	prompt_label.visible = not current_station.is_empty()
	if current_station.is_empty():
		prompt_label.text = ""
	else:
		prompt_label.text = "[E]  %s" % STATIONS[current_station]["label"]


func _interact() -> void:
	match current_station:
		"bed":
			GameState.player_health = 100
			_show_status("충분히 쉬었습니다. 체력이 모두 회복되었습니다.")
		"craft":
			if GameState.scrap < 15:
				_show_status("고철이 부족합니다. 응급키트 제작에는 고철 15개가 필요합니다.")
			else:
				GameState.scrap -= 15
				GameState.medkits += 1
				_show_status("응급키트 1개를 제작했습니다.")
		"upgrade":
			var cost := GameState.weapon_level * 25
			if GameState.scrap < cost:
				_show_status("고철이 부족합니다. 강화에는 고철 %d개가 필요합니다." % cost)
			else:
				GameState.scrap -= cost
				GameState.weapon_level += 1
				_show_status("무기를 Lv.%d로 강화했습니다." % GameState.weapon_level)
		"exit":
			GameState.returning_from_shelter = true
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	_update_stats()


func _update_stats() -> void:
	stats_label.text = "SHELTER 01  ·  안전가옥\n체력  %d / 100    고철  %d\n무기  Lv.%d    응급키트  %d" % [GameState.player_health, GameState.scrap, GameState.weapon_level, GameState.medkits]


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
	var source := facing
	var flipped := false
	match facing:
		"sw": source = "se"; flipped = true
		"w": source = "e"; flipped = true
		"nw": source = "ne"; flipped = true
	survivor.flip_h = flipped
	survivor.play("%s_%s" % [motion_state, source])


func _create_character_frames() -> SpriteFrames:
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
				atlas.region = Rect2((frame_index % 4) * FRAME_SIZE.x, (frame_index / 4) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
				frames.add_frame(animation_name, atlas)
	return frames


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_ESCAPE:
			current_station = "exit"
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


func _add_station_marker(node_name: String, position: Vector3, color: Color) -> void:
	var material := _material(Color(color.r, color.g, color.b, 0.24))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 0.8
	mesh.height = 0.035
	mesh.material = material
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.position = position
	marker.mesh = mesh
	add_child(marker)


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


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, parent: Node) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
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
