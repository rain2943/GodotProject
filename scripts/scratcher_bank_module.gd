class_name ScratcherBankModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")

@export var interaction_radius := 2.35

@onready var sprite: Sprite3D = $BankSprite

var has_focus := false
var ui_layer: CanvasLayer
var content: VBoxContainer


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("scratcher_bank")
	set_meta("module_kind", "scratcher_bank")


func get_interaction_prompt() -> String:
	return "꾹꾹이 화폐 복사소"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	GameState.process_shelter_progress()
	_open_ui()
	return "구출한 주민 고양이를 배치해 고철을 자동 생산합니다."


func set_interaction_focus(value: bool) -> void:
	has_focus = value
	if sprite:
		sprite.modulate = Color(1.14, 1.1, 0.88, 1.0) if has_focus else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "ScratcherBankUILayer"
	ui_layer.layer = 20
	var ui_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	ui_parent.add_child(ui_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-390, -230)
	panel.size = Vector2(780, 460)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.023, 0.02, 0.96), Color("#c29c5b")))
	ui_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	_rebuild_ui()


func _rebuild_ui() -> void:
	GameState._ensure_resident_records()
	for child in content.get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := _label("꾹꾹이 화폐 복사소  Lv.%d" % GameState.scratcher_bank_level, 24, Color("#f4ddb2"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button("닫기")
	close.pressed.connect(func(): ui_layer.queue_free())
	header.add_child(close)
	var workers: int = GameState.get_active_scratcher_workers()
	var slots: int = GameState.get_scratcher_worker_slots()
	content.add_child(_label("구출 주민 %d마리  ·  통조림 %d개  ·  가동 %d / %d마리" % [
		GameState.rescued_workers,
		GameState.canned_food,
		workers,
		slots,
	], 17, Color("#dedbd0")))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for index in range(8):
		grid.add_child(_worker_slot_button(index, slots))
	content.add_child(_label("시간당 고철  %.0f  ·  생산 배율 x%.1f" % [
		GameState.get_scrap_per_hour(),
		GameState.scratcher_multiplier,
	], 18, Color("#d6b86e")))
	var help_text := "통조림이 부족하면 구조한 주민이 있어도 일하지 않습니다. 레이드에서 통조림을 챙기면 자동 생산 인원이 늘어납니다."
	content.add_child(_label(help_text, 14, Color("#9fb0a7")))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var collect := _button("진행 정산")
	collect.pressed.connect(_collect_progress)
	actions.add_child(collect)
	var upgrade_cost := int(GameState.SCRATCHER_UPGRADE_COSTS.get(GameState.scratcher_bank_level + 1, 0))
	var upgrade := _button("최고 레벨" if upgrade_cost == 0 else "Lv.%d 업그레이드  고철 %d" % [GameState.scratcher_bank_level + 1, upgrade_cost])
	upgrade.disabled = upgrade_cost == 0 or GameState.scrap < upgrade_cost
	upgrade.pressed.connect(_upgrade)
	actions.add_child(upgrade)
	content.add_child(_label("보유 고철 %d" % GameState.scrap, 15, Color("#b9c9c0")))


func _worker_slot(index: int, active_workers: int, slots: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(168, 72)
	var active := index < active_workers
	var unlocked := index < slots
	var bg := Color(0.035, 0.04, 0.033, 0.92)
	var border := Color("#80b887") if active else (Color("#635847") if unlocked else Color("#333333"))
	panel.add_theme_stylebox_override("panel", _panel_style(bg, border))
	var label := _label(
		"작업 중" if active else ("대기 슬롯" if unlocked else "잠김"),
		15,
		Color("#dff0c2") if active else Color("#8f978f")
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _collect_progress() -> void:
	GameState.process_shelter_progress()
	_rebuild_ui()


func _worker_slot_button(index: int, slots: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(168, 72)
	var unlocked := index < slots
	var resident_id := ""
	if index < GameState.resident_cat_ids.size():
		resident_id = str(GameState.resident_cat_ids[index])
	var active := not resident_id.is_empty() and GameState.assigned_worker_ids.has(resident_id)
	var bg := Color(0.035, 0.04, 0.033, 0.92)
	var border := Color("#80b887") if active else (Color("#635847") if unlocked else Color("#333333"))
	button.add_theme_stylebox_override("normal", _panel_style(bg, border))
	button.add_theme_stylebox_override("hover", _panel_style(bg.lightened(0.08), Color("#d1c27a") if unlocked else border))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.05), Color("#f0d16f") if unlocked else border))
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.disabled = not unlocked or resident_id.is_empty()
	if active:
		var active_count := maxf(1.0, float(GameState.get_active_scratcher_workers()))
		button.text = "%s\nWORK  +%.2f/s" % [resident_id, GameState.get_scrap_per_second() / active_count]
	elif resident_id.is_empty():
		button.text = "EMPTY" if unlocked else "LOCKED"
	else:
		button.text = "%s\nSTANDBY" % resident_id
	if not resident_id.is_empty():
		button.pressed.connect(func(): _toggle_worker(resident_id))
	return button


func _toggle_worker(resident_id: String) -> void:
	GameState.toggle_worker_assignment(resident_id)
	_rebuild_ui()


func _upgrade() -> void:
	if GameState.try_upgrade_scratcher_bank():
		_rebuild_ui()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 14)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
