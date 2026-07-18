class_name ScratcherBankModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const UI_ICONS := preload("res://scripts/ui_icon_factory.gd")

@export var interaction_radius := 3.15

@onready var sprite: Sprite3D = $BankSprite

var has_focus := false
var ui_layer: CanvasLayer
var content: VBoxContainer


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("scratcher_bank")
	set_meta("module_kind", "scratcher_bank")


func get_interaction_prompt() -> String:
	return "꾹꾹이 고철 생산기"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	GameState.process_shelter_progress()
	_open_ui()
	return "주민의 특성에 따라 고철을 자동 생산합니다."


func set_interaction_focus(value: bool) -> void:
	has_focus = value
	if sprite:
		sprite.modulate = Color(1.14, 1.1, 0.88, 1.0) if has_focus else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "ScratcherBankUILayer"
	ui_layer.layer = 80
	ui_layer.add_to_group("shelter_modal_ui")
	var ui_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	ui_parent.add_child(ui_layer)
	var modal := Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(modal)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.004, 0.006, 0.008, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)
	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 22)
	safe_margin.add_theme_constant_override("margin_top", 22)
	safe_margin.add_theme_constant_override("margin_right", 22)
	safe_margin.add_theme_constant_override("margin_bottom", 22)
	modal.add_child(safe_margin)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 510)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.023, 0.02, 0.96), Color("#c29c5b")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	_rebuild_ui()


func _rebuild_ui() -> void:
	GameState._ensure_resident_records()
	for child in content.get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_label("꾹꾹이 고철 생산기", 26, Color("#f4ddb2")))
	title_box.add_child(_label("주민 배치 · 자동 생산 · 캣닢 부스터", 13, Color("#9eaa9f")))
	var close := _button("닫기", "close")
	close.custom_minimum_size = Vector2(76, 38)
	close.pressed.connect(func(): ui_layer.queue_free())
	header.add_child(close)
	var workers: int = GameState.get_active_scratcher_workers()
	var slots: int = GameState.get_scratcher_worker_slots()
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	content.add_child(summary)
	summary.add_child(_summary_card("시설", "Lv.%d · Tier %d" % [GameState.scratcher_bank_level, GameState.shelter_tier]))
	summary.add_child(_summary_card("배치", "%d / %d명" % [workers, slots]))
	summary.add_child(_summary_card("시간당 생산", "🔩 %.0f" % GameState.get_scrap_per_hour()))
	summary.add_child(_summary_card("부스터", "x%.0f" % GameState.get_production_multiplier()))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	content.add_child(body)
	var resident_panel := PanelContainer.new()
	resident_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resident_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.026, 0.032, 0.028, 0.9), Color("#4c6254")))
	body.add_child(resident_panel)
	var resident_margin := MarginContainer.new()
	resident_margin.add_theme_constant_override("margin_left", 12)
	resident_margin.add_theme_constant_override("margin_top", 10)
	resident_margin.add_theme_constant_override("margin_right", 12)
	resident_margin.add_theme_constant_override("margin_bottom", 10)
	resident_panel.add_child(resident_margin)
	var resident_box := VBoxContainer.new()
	resident_box.add_theme_constant_override("separation", 8)
	resident_margin.add_child(resident_box)
	resident_box.add_child(_label("주민 배치", 16, Color("#e3decf")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 230)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	resident_box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for index in range(GameState.resident_cat_ids.size()):
		grid.add_child(_worker_slot_button(index, slots))
	if GameState.resident_cat_ids.is_empty():
		grid.add_child(_label("구출한 주민이 없습니다.", 15, Color("#8f978f")))

	var operations := PanelContainer.new()
	operations.custom_minimum_size = Vector2(252, 0)
	operations.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.034, 0.028, 0.92), Color("#66563a")))
	body.add_child(operations)
	var operations_margin := MarginContainer.new()
	operations_margin.add_theme_constant_override("margin_left", 14)
	operations_margin.add_theme_constant_override("margin_top", 12)
	operations_margin.add_theme_constant_override("margin_right", 14)
	operations_margin.add_theme_constant_override("margin_bottom", 12)
	operations.add_child(operations_margin)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	operations_margin.add_child(actions)
	actions.add_child(_label("시설 운용", 16, Color("#ead7ad")))
	actions.add_child(_label("주민 카드를 눌러 작업자를 배치하거나 해제합니다.", 12, Color("#9fb0a7")))
	var collect := _button("진행 정산", "collect")
	collect.custom_minimum_size = Vector2(0, 38)
	collect.pressed.connect(_collect_progress)
	actions.add_child(collect)
	var boost_remaining: int = GameState.get_catnip_boost_remaining()
	var boost := _button(
		"부스터 %02d:%02d" % [boost_remaining / 60, boost_remaining % 60]
		if boost_remaining > 0
		else "🌿 캣닢 25 · 10분 x10",
		"catnip"
	)
	boost.disabled = boost_remaining > 0 or GameState.catnip < GameState.CATNIP_BOOST_COST
	boost.custom_minimum_size = Vector2(0, 38)
	boost.pressed.connect(_activate_boost)
	actions.add_child(boost)
	var upgrade_cost := int(GameState.SCRATCHER_UPGRADE_COSTS.get(GameState.scratcher_bank_level + 1, 0))
	var upgrade := _button("최고 레벨" if upgrade_cost == 0 else "Lv.%d 업그레이드  🔩 고철 %d" % [GameState.scratcher_bank_level + 1, upgrade_cost], "upgrade")
	upgrade.disabled = upgrade_cost == 0 or GameState.scrap < upgrade_cost
	upgrade.custom_minimum_size = Vector2(0, 38)
	upgrade.pressed.connect(_upgrade)
	actions.add_child(upgrade)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	actions.add_child(_label("보유 자원", 13, Color("#8fa096")))
	actions.add_child(_label("🔩 %d   🌿 %.1f\n🥫 %d   🍗 %d" % [
		GameState.scrap,
		GameState.catnip,
		GameState.canned_food,
		GameState.churu,
	], 15, Color("#d9dfd9")))


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
	button.custom_minimum_size = Vector2(176, 76)
	var resident_id := ""
	if index < GameState.resident_cat_ids.size():
		resident_id = str(GameState.resident_cat_ids[index])
	var active := not resident_id.is_empty() and GameState.assigned_worker_ids.has(resident_id)
	var available := active or GameState.assigned_worker_ids.size() < slots
	var bg := Color(0.035, 0.04, 0.033, 0.92)
	var border := Color("#80b887") if active else (Color("#635847") if available else Color("#333333"))
	button.add_theme_stylebox_override("normal", _panel_style(bg, border))
	button.add_theme_stylebox_override("hover", _panel_style(bg.lightened(0.08), Color("#d1c27a") if available else border))
	button.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.05), Color("#f0d16f") if available else border))
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.icon = UI_ICONS.get_icon("resident", 42, Color("#dfc98f"))
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not available or resident_id.is_empty()
	var trait_data: Dictionary = GameState.get_resident_trait(resident_id) if not resident_id.is_empty() else {}
	if active:
		button.text = "%s · %s\n작업 중  x%.2f" % [resident_id, trait_data.get("name", ""), trait_data.get("kneading", 1.0)]
	elif resident_id.is_empty():
		button.text = "빈 주민 슬롯"
	else:
		button.text = "%s · %s\n꾹꾹이 x%.2f  🌿 캣닢 x%.2f" % [
			resident_id,
			trait_data.get("name", ""),
			trait_data.get("kneading", 1.0),
			trait_data.get("catnip", 1.0),
		]
	if not resident_id.is_empty():
		button.pressed.connect(func(): _toggle_worker(resident_id))
	return button


func _toggle_worker(resident_id: String) -> void:
	GameState.toggle_worker_assignment(resident_id)
	get_tree().call_group("shelter_resident_host", "refresh_shelter_residents", false)
	_rebuild_ui()


func _upgrade() -> void:
	if GameState.try_upgrade_scratcher_bank():
		_rebuild_ui()


func _activate_boost() -> void:
	if GameState.activate_catnip_boost():
		_rebuild_ui()


func _button(text: String, icon_name := "") -> Button:
	var button := Button.new()
	button.text = text
	if not icon_name.is_empty():
		button.icon = UI_ICONS.get_icon(icon_name, 28, Color("#e5dfd0"))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.06, 0.066, 0.058, 0.96), Color("#68736b")))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.11, 0.096, 0.06, 0.98), Color("#d2ad61")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.085, 0.04, 0.98), Color("#f0c463")))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.03, 0.034, 0.032, 0.72), Color("#38413c")))
	return button


func _summary_card(title: String, value: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 58)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.041, 0.036, 0.92), Color("#46564d")))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = UI_ICONS.get_icon(_summary_icon_name(title), 36, Color("#d1b96f"))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	row.add_child(box)
	box.add_child(_label(title, 11, Color("#8e9b92")))
	box.add_child(_label(value, 15, Color("#e4dfd1")))
	return panel


func _summary_icon_name(title: String) -> String:
	if title.contains("주민") or title.contains("배치"):
		return "resident"
	if title.contains("시간") or title.contains("초당"):
		return "time"
	if title.contains("생산"):
		return "scrap"
	return "workbench"


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
