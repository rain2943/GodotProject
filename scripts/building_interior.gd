extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const ROOM_MODULE_SCENE := preload("res://scenes/modules/building_room_module.tscn")
const TRANSITION_MODULE_SCENE := preload("res://scenes/modules/building_transition_module.tscn")
const LOOT_MODULE_SCENE := preload("res://scenes/modules/building_loot_module.tscn")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const BULLET_SCRIPT := preload("res://scripts/bullet_projectile.gd")
const CAT_ANIMATION_ROOT := "res://assets/characters/cat_8way"
const CAT_DIRECTION_STATES := {
	"n": "up", "ne": "up_right", "e": "right", "se": "down_right",
	"s": "down", "sw": "down_left", "w": "left", "nw": "up_left",
}
const SCREEN_DIRECTIONS := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const ROOM_TYPES := ["open_office", "open_office", "meeting", "storage", "server", "executive"]
const MOVE_SPEED := 4.65
const FLOOR_BOUNDS := Vector2(16.45, 11.4)

var floor_root: Node3D
var player: CharacterBody3D
var survivor: AnimatedSprite3D
var camera: Camera3D
var prompt_label: Label
var status_label: Label
var floor_label: Label
var health_bar: ProgressBar
var current_interactable: Node3D
var enemies: Array[CharacterBody3D] = []
var facing := "s"
var motion_state := "idle"
var camera_focus := Vector3.ZERO
var fire_cooldown := 0.0
var loading_floor := false
@onready var BuildingRunState: Node = get_node("/root/BuildingRunState")
@onready var GameState: Node = get_node("/root/GameState")


func _ready() -> void:
	if not BuildingRunState.active:
		BuildingRunState.begin_run(
			"editor_preview_tower",
			int(GameState.map_seed) ^ 0x424C4447,
			"res://scenes/main.tscn",
			Vector3.ZERO,
			5
		)
	_build_environment()
	_build_player()
	_build_interface()
	_load_floor(BuildingRunState.current_floor, "entry")


func _physics_process(delta: float) -> void:
	if player == null or loading_floor:
		return
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W): input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_vector.y += 1.0
	input_vector = input_vector.limit_length(1.0)
	var direction := Vector3(input_vector.x + input_vector.y, 0.0, -input_vector.x + input_vector.y)
	if direction.length_squared() > 0.01:
		player.velocity = direction.normalized() * MOVE_SPEED
		_update_facing(input_vector)
		_set_motion_state("walk")
	else:
		player.velocity = Vector3.ZERO
		_set_motion_state("idle")
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -FLOOR_BOUNDS.x, FLOOR_BOUNDS.x)
	player.position.z = clampf(player.position.z, -FLOOR_BOUNDS.y, FLOOR_BOUNDS.y)
	_update_camera(delta)
	_update_nearby_interactable()
	status_label.modulate.a = move_toward(status_label.modulate.a, 0.0, delta * 0.16)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_F:
			_fire_at_nearest_enemy()
		elif event.keycode == KEY_ESCAPE and BuildingRunState.current_floor == 1:
			_show_status("1층 출구에서 나갈 수 있습니다.")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fire_toward_screen_point(event.position)


func take_damage(amount: int) -> void:
	GameState.player_health = maxi(0, GameState.player_health - amount)
	_update_health()
	_show_status("피격 · 체력 %d" % GameState.player_health)
	if GameState.player_health <= 0:
		GameState.player_health = 35
		BuildingRunState.active = false
		if GameState.has_method("register_shelter_return"):
			GameState.call("register_shelter_return")
		get_tree().change_scene_to_file("res://scenes/shelter_interior.tscn")


func _build_environment() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#758087")
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var outside_material := _material(Color.BLACK)
	outside_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_add_plane(self, "BlackOutside", Vector3(0, -0.2, 0), Vector2(180, 180), outside_material)
	camera = Camera3D.new()
	camera.name = "BuildingCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.0
	camera.position = Vector3(17.5, 18.5, 17.5)
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.name = "InteriorKeyLight"
	light.rotation_degrees = Vector3(-57, -42, 0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "BuildingPlayer"
	player.add_to_group("player")
	player.position = Vector3(0, 0.78, 0)
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
	_play_animation()


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "BuildingHUD"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(330, 126)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.022, 0.9)
	style.border_color = Color(0.42, 0.55, 0.52, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	floor_label = Label.new()
	floor_label.add_theme_font_override("font", FONT)
	floor_label.add_theme_font_size_override("font_size", 18)
	box.add_child(floor_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(290, 10)
	health_bar.max_value = 100
	health_bar.show_percentage = false
	box.add_child(health_bar)
	var help := Label.new()
	help.text = "이동 WASD · 상호작용 E · 사격 F/클릭"
	help.add_theme_font_override("font", FONT)
	help.add_theme_font_size_override("font_size", 13)
	help.modulate = Color("#aeb7b3")
	box.add_child(help)
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-250, -82)
	prompt_label.size = Vector2(500, 42)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_override("font", FONT)
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.modulate = Color("#efe1a4")
	canvas.add_child(prompt_label)
	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-330, 22)
	status_label.size = Vector2(660, 40)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", FONT)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.modulate = Color("#d8e4dd")
	canvas.add_child(status_label)
	var fire_button := Button.new()
	fire_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire_button.position = Vector2(-142, -128)
	fire_button.size = Vector2(104, 82)
	fire_button.text = "사격"
	fire_button.add_theme_font_override("font", FONT)
	fire_button.pressed.connect(_fire_at_nearest_enemy)
	canvas.add_child(fire_button)
	var interact_button := Button.new()
	interact_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact_button.position = Vector2(-260, -128)
	interact_button.size = Vector2(104, 82)
	interact_button.text = "상호작용"
	interact_button.add_theme_font_override("font", FONT)
	interact_button.pressed.connect(_interact)
	canvas.add_child(interact_button)
	_update_health()


func _load_floor(floor_number: int, arrival: String) -> void:
	loading_floor = true
	current_interactable = null
	prompt_label.text = ""
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	if floor_root != null:
		floor_root.queue_free()
		await get_tree().process_frame
	floor_root = Node3D.new()
	floor_root.name = "Floor%02dModules" % floor_number
	floor_root.add_to_group("building_floor_root")
	floor_root.set_meta("floor_number", floor_number)
	floor_root.set_meta("floor_seed", BuildingRunState.get_floor_seed(floor_number))
	add_child(floor_root)
	BuildingRunState.current_floor = floor_number
	var random := RandomNumberGenerator.new()
	random.seed = BuildingRunState.get_floor_seed(floor_number)
	_build_floor_shell()
	_build_room_modules(random)
	_build_transitions()
	_spawn_floor_loot(random)
	_spawn_floor_enemies(random)
	match arrival:
		"from_below": player.position = Vector3(-12.8, 0.78, 0.0)
		"from_above": player.position = Vector3(12.8, 0.78, 0.0)
		_: player.position = Vector3(0.0, 0.78, 0.0)
	camera_focus = Vector3(player.position.x, 0, player.position.z)
	floor_label.text = "%s · %d / %d층" % [BuildingRunState.building_id, floor_number, BuildingRunState.max_floors]
	_show_status("%d층 진입 · 배치 시드 %d" % [floor_number, BuildingRunState.get_floor_seed(floor_number)])
	loading_floor = false


func _build_floor_shell() -> void:
	var floor_material := _material(Color("#272d30"))
	_add_plane(floor_root, "CorridorFloor", Vector3(0, 0, 0), Vector2(34, 24), floor_material)
	var corridor_material := _material(Color("#363d40"))
	_add_plane(floor_root, "MainCorridor", Vector3(0, 0.012, 0), Vector2(30, 4.6), corridor_material)
	_add_static_box(floor_root, "NorthOuterWall", Vector3(0, 1.4, -12), Vector3(34, 2.8, 0.35), Color("#42494c"))
	_add_static_box(floor_root, "SouthOuterWall", Vector3(0, 1.4, 12), Vector3(34, 2.8, 0.35), Color("#42494c"))
	_add_static_box(floor_root, "WestOuterWall", Vector3(-17, 1.4, 0), Vector3(0.35, 2.8, 24), Color("#42494c"))
	_add_static_box(floor_root, "EastOuterWall", Vector3(17, 1.4, 0), Vector3(0.35, 2.8, 24), Color("#42494c"))
	for light_index in 7:
		var x := -13.5 + light_index * 4.5
		_add_visual_box(floor_root, "CorridorLight%d" % light_index, Vector3(x, 0.05, -1.85), Vector3(1.7, 0.05, 0.08), Color("#75c8c1"))


func _build_room_modules(random: RandomNumberGenerator) -> void:
	var room_width := 6.75
	for row in 2:
		var entrance_sign := 1.0 if row == 0 else -1.0
		var center_z := -7.35 if row == 0 else 7.35
		for column in 4:
			var index := row * 4 + column
			var room := ROOM_MODULE_SCENE.instantiate() as Node3D
			var type_name: String = ROOM_TYPES[random.randi_range(0, ROOM_TYPES.size() - 1)]
			room.call("configure", index, Vector2(room_width, 9.1), entrance_sign, type_name, random.randi())
			room.name = "Room%02d_%s" % [index + 1, type_name]
			room.position = Vector3(-10.2 + column * 6.8, 0, center_z)
			floor_root.add_child(room)
			var label := Label3D.new()
			label.name = "RoomLabel"
			label.position = Vector3(0, 2.45, entrance_sign * 4.48)
			label.text = "%02d · %s" % [index + 1, _room_display_name(type_name)]
			label.font = FONT
			label.font_size = 28
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			room.add_child(label)


func _build_transitions() -> void:
	var floor_number: int = int(BuildingRunState.current_floor)
	if floor_number == 1:
		_add_transition("ExitToCity", Vector3(0, 0, 2.05), 0.0, "exit", 0, "도시로 나가기")
	if floor_number < BuildingRunState.max_floors:
		_add_transition("ElevatorUp", Vector3(-15.55, 0, -1.4), 90.0, "elevator_up", floor_number + 1, "엘리베이터 · %d층" % (floor_number + 1))
		_add_transition("StairsUp", Vector3(15.55, 0, -1.4), -90.0, "stairs_up", floor_number + 1, "계단 · %d층" % (floor_number + 1))
	if floor_number > 1:
		_add_transition("ElevatorDown", Vector3(-15.55, 0, 1.45), 90.0, "elevator_down", floor_number - 1, "엘리베이터 · %d층" % (floor_number - 1))
		_add_transition("StairsDown", Vector3(15.55, 0, 1.45), -90.0, "stairs_down", floor_number - 1, "계단 · %d층" % (floor_number - 1))


func _add_transition(node_name: String, position: Vector3, rotation_y: float, kind: String, target_floor: int, label_text: String) -> void:
	var transition := TRANSITION_MODULE_SCENE.instantiate() as Node3D
	transition.call("configure", kind, target_floor, label_text)
	transition.name = node_name
	transition.position = position
	transition.rotation_degrees.y = rotation_y
	transition.connect("activated", _on_transition_activated.bind(transition))
	floor_root.add_child(transition)


func _spawn_floor_loot(random: RandomNumberGenerator) -> void:
	var count: int = 4 + int(BuildingRunState.current_floor)
	for index in count:
		var key := "f%02d_loot_%02d" % [BuildingRunState.current_floor, index]
		if BuildingRunState.is_loot_collected(BuildingRunState.current_floor, key):
			continue
		var column: int = index % 4
		var north: bool = index % 2 == 0
		var position := Vector3(-10.2 + column * 6.8 + random.randf_range(-1.5, 1.5), 0, -5.0 if north else 5.0)
		var type_roll := random.randf()
		var type_name := "scrap"
		if type_roll > 0.72: type_name = "component"
		elif type_roll > 0.48: type_name = "ammo"
		var amount := random.randi_range(8, 22) if type_name != "component" else 1
		var loot := LOOT_MODULE_SCENE.instantiate() as Node3D
		loot.call("configure", key, type_name, amount, BuildingRunState.current_floor)
		loot.name = "Loot_%s" % key
		loot.position = position
		loot.connect("collected", _on_loot_collected)
		floor_root.add_child(loot)


func _spawn_floor_enemies(random: RandomNumberGenerator) -> void:
	var count: int = clampi(1 + int(BuildingRunState.current_floor), 2, 7)
	for index in count:
		var key := "f%02d_enemy_%02d" % [BuildingRunState.current_floor, index]
		if BuildingRunState.is_enemy_defeated(BuildingRunState.current_floor, key):
			continue
		var enemy := CharacterBody3D.new()
		enemy.name = key
		enemy.set_script(ENEMY_SCRIPT)
		enemy.position = Vector3(
			random.randf_range(-11.5, 11.5),
			0.78,
			random.randf_range(-1.25, 1.25)
		)
		var ranged: bool = index % 3 == 2 or int(BuildingRunState.current_floor) >= 3 and index % 2 == 1
		var kind := "ranged" if ranged else "melee"
		var weapon := "m1911" if ranged else "baseball_bat"
		enemy.call("configure", kind, player, {}, minf(1.0, 0.12 * BuildingRunState.current_floor), weapon)
		enemy.connect("died", _on_enemy_died.bind(key))
		floor_root.add_child(enemy)
		enemies.append(enemy)


func _on_enemy_died(enemy: CharacterBody3D, enemy_key: String) -> void:
	BuildingRunState.mark_enemy_defeated(BuildingRunState.current_floor, enemy_key)
	enemies.erase(enemy)
	var reward_key := "%s_drop" % enemy_key
	if not BuildingRunState.is_loot_collected(BuildingRunState.current_floor, reward_key):
		var loot := LOOT_MODULE_SCENE.instantiate() as Node3D
		loot.call("configure", reward_key, "ammo", 8, BuildingRunState.current_floor)
		loot.name = "Loot_%s" % reward_key
		loot.position = Vector3(enemy.position.x, 0, enemy.position.z)
		loot.connect("collected", _on_loot_collected)
		floor_root.add_child(loot)


func _on_loot_collected(_key: String, description: String) -> void:
	_show_status(description)


func _on_transition_activated(_action: String, transition: Node3D) -> void:
	if loading_floor:
		return
	var kind := str(transition.get_meta("transition_kind", ""))
	var target_floor := int(transition.get_meta("target_floor", 0))
	if kind == "exit":
		BuildingRunState.leave_building()
		return
	if target_floor < 1 or target_floor > BuildingRunState.max_floors:
		return
	var arrival := "from_below" if target_floor > BuildingRunState.current_floor else "from_above"
	_load_floor(target_floor, arrival)


func _update_nearby_interactable() -> void:
	var nearest: Node3D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("building_interactable"):
		if not candidate is Node3D or not is_ancestor_of(candidate):
			continue
		var node := candidate as Node3D
		var radius := float(node.call("get_interaction_radius")) if node.has_method("get_interaction_radius") else 1.5
		var distance := player.global_position.distance_to(node.global_position)
		if distance <= radius and distance < nearest_distance:
			nearest = node
			nearest_distance = distance
	current_interactable = nearest
	prompt_label.text = "" if nearest == null else "[E]  %s" % str(nearest.call("get_interaction_prompt"))


func _interact() -> void:
	if current_interactable == null or not is_instance_valid(current_interactable):
		return
	if current_interactable.has_method("interact"):
		var result := str(current_interactable.call("interact"))
		if not result.is_empty(): _show_status(result)


func _fire_at_nearest_enemy() -> void:
	var closest: CharacterBody3D
	var closest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or bool(enemy.get("dying")):
			continue
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance
	if closest != null:
		_fire_toward_world(closest.global_position)


func _fire_toward_screen_point(screen_point: Vector2) -> void:
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_point)
	var ray_direction := camera.project_ray_normal(screen_point)
	if absf(ray_direction.y) < 0.001:
		return
	var distance := (0.45 - origin.y) / ray_direction.y
	_fire_toward_world(origin + ray_direction * distance)


func _fire_toward_world(target_position: Vector3) -> void:
	if fire_cooldown > 0.0 or GameState.magazine_ammo <= 0:
		return
	var direction := target_position - player.global_position
	direction.y = 0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	var bullet := Area3D.new()
	bullet.name = "BuildingPlayerBullet"
	bullet.set_script(BULLET_SCRIPT)
	bullet.set("direction", direction)
	bullet.set("source_body", player)
	bullet.set("damage", 32)
	bullet.position = player.global_position + direction * 0.75 + Vector3(0, 0.35, 0)
	add_child(bullet)
	GameState.magazine_ammo -= 1
	fire_cooldown = 0.18


func _update_camera(delta: float) -> void:
	camera_focus = camera_focus.lerp(Vector3(player.position.x, 0, player.position.z), clampf(delta * 5.0, 0, 1))
	camera.position = camera_focus + Vector3(17.5, 18.5, 17.5)
	camera.look_at(camera_focus)


func _update_facing(input_vector: Vector2) -> void:
	if input_vector.length_squared() < 0.01:
		return
	var angle := fposmod(rad_to_deg(atan2(input_vector.x, -input_vector.y)), 360.0)
	var next_facing: String = SCREEN_DIRECTIONS[int(round(angle / 45.0)) % 8]
	if next_facing != facing:
		facing = next_facing
		_play_animation()


func _set_motion_state(state: String) -> void:
	if motion_state == state:
		return
	motion_state = state
	_play_animation()


func _play_animation() -> void:
	if survivor != null:
		survivor.play("%s_%s" % [motion_state, facing])


func _create_cat_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in SCREEN_DIRECTIONS:
		var state_prefix: String = CAT_DIRECTION_STATES[direction_name]
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 4.0 if state == "idle" else 8.0)
			for frame_index in 4:
				var path := "%s/%s_%s_%d.png" % [CAT_ANIMATION_ROOT, state_prefix, state, frame_index]
				if ResourceLoader.exists(path): frames.add_frame(animation_name, load(path) as Texture2D)
	return frames


func _room_display_name(type_name: String) -> String:
	match type_name:
		"meeting": return "회의실"
		"storage": return "창고"
		"server": return "서버실"
		"executive": return "임원실"
	return "사무실"


func _update_health() -> void:
	if health_bar != null:
		health_bar.value = GameState.player_health


func _show_status(message: String) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.modulate.a = 1.0


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.87
	return material


func _add_plane(parent: Node, node_name: String, position: Vector3, size: Vector2, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	parent.add_child(instance)


func _add_visual_box(parent: Node, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	instance.mesh = mesh
	parent.add_child(instance)


func _add_static_box(parent: Node, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	_add_visual_box(parent, "%sVisual" % node_name, position, size, color)
	var body := StaticBody3D.new()
	body.name = "%sCollision" % node_name
	body.position = position
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
