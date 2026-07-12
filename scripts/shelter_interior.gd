extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")

var status_label: Label
var stats_label: Label
var rest_button: Button
var upgrade_button: Button
var craft_button: Button


func _ready() -> void:
	_build_room()
	_build_interface()
	_update_interface("쉘터 01에 진입했습니다. 이곳은 안전합니다.")


func _build_room() -> void:
	var floor_material := _material(Color("#252d2c"))
	var wall_material := _material(Color("#394542"))
	var accent_material := _material(Color("#54d89b"), true)
	_add_box("Floor", Vector3(0, -0.15, 0), Vector3(18, 0.3, 12), floor_material)
	_add_box("BackWall", Vector3(0, 2.5, -6), Vector3(18, 5, 0.35), wall_material)
	_add_box("LeftWall", Vector3(-9, 2.5, 0), Vector3(0.35, 5, 12), wall_material)
	_add_box("RightWall", Vector3(9, 2.5, 0), Vector3(0.35, 5, 12), wall_material)
	_add_box("RestBed", Vector3(-5.5, 0.45, -2), Vector3(4.2, 0.9, 2.2), accent_material)
	_add_box("Workbench", Vector3(0, 0.8, -3.8), Vector3(4.5, 1.6, 1.4), wall_material)
	_add_box("UpgradeStation", Vector3(5.5, 1.2, -4.6), Vector3(2.8, 2.4, 1.2), accent_material)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(10.5, 9.5, 12.5)
	camera.look_at(Vector3(0, 0.8, -1))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.1
	add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 3.5, 0)
	fill.light_color = Color("#9fe8c5")
	fill.light_energy = 2.2
	fill.omni_range = 16.0
	add_child(fill)


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(36, 34)
	panel.size = Vector2(430, 430)
	canvas.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.038, 0.94)
	style.border_color = Color("#5ad69f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "SHELTER 01  ·  안전가옥"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(stats_label)
	rest_button = _make_button("휴식  ·  체력 완전 회복")
	rest_button.pressed.connect(_on_rest_pressed)
	vbox.add_child(rest_button)
	upgrade_button = _make_button("무기 강화")
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	vbox.add_child(upgrade_button)
	craft_button = _make_button("응급키트 제작  ·  고철 15")
	craft_button.pressed.connect(_on_craft_pressed)
	vbox.add_child(craft_button)
	var exit_button := _make_button("도시로 돌아가기")
	exit_button.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_button)
	status_label = Label.new()
	status_label.custom_minimum_size.y = 58
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color("#9fe8c5")
	vbox.add_child(status_label)
	var theme := Theme.new()
	theme.default_font = FONT
	panel.theme = theme


func _make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 17)
	return button


func _on_rest_pressed() -> void:
	GameState.player_health = 100
	_update_interface("충분히 쉬었습니다. 체력이 모두 회복되었습니다.")


func _on_upgrade_pressed() -> void:
	var cost := GameState.weapon_level * 25
	if GameState.scrap < cost:
		_update_interface("고철이 부족합니다. 강화에는 고철 %d개가 필요합니다." % cost)
		return
	GameState.scrap -= cost
	GameState.weapon_level += 1
	_update_interface("무기를 %d단계로 강화했습니다." % GameState.weapon_level)


func _on_craft_pressed() -> void:
	if GameState.scrap < 15:
		_update_interface("응급키트를 제작할 고철이 부족합니다.")
		return
	GameState.scrap -= 15
	GameState.medkits += 1
	_update_interface("응급키트 1개를 제작했습니다.")


func _on_exit_pressed() -> void:
	GameState.returning_from_shelter = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _update_interface(message: String) -> void:
	var next_cost := GameState.weapon_level * 25
	stats_label.text = "체력  %d / 100\n고철  %d\n무기 강화  Lv.%d\n응급키트  %d" % [GameState.player_health, GameState.scrap, GameState.weapon_level, GameState.medkits]
	upgrade_button.text = "무기 강화  ·  고철 %d" % next_cost
	upgrade_button.disabled = GameState.scrap < next_cost
	craft_button.disabled = GameState.scrap < 15
	rest_button.disabled = GameState.player_health >= 100
	status_label.text = message


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_exit_pressed()


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	add_child(instance)


func _material(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	return material
