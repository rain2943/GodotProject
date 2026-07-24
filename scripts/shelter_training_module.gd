class_name ShelterTrainingModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const UI_ICONS := preload("res://scripts/ui_icon_factory.gd")

@export var interaction_radius := 3.5

@onready var sprite: Sprite3D = $TrainingSprite

var ui_layer: CanvasLayer
var content: VBoxContainer
var status_label: Label
var compact_layout := false
var narrow_layout := false


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("training_facility")
	set_meta("module_kind", "training")


func get_interaction_prompt() -> String:
	return "생존 체력 훈련장"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	_open_ui()
	return "통조림을 투자해 플레이어 능력을 영구 강화합니다."


func set_interaction_focus(value: bool) -> void:
	if sprite:
		sprite.modulate = Color(1.08, 1.08, 0.88, 1.0) if value else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "TrainingFacilityUILayer"
	ui_layer.layer = 90
	ui_layer.add_to_group("shelter_modal_ui")
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(ui_layer)
	var modal := Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(modal)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.004, 0.006, 0.006, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)
	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport().get_visible_rect().size
	compact_layout = viewport_size.x < 1040.0 or viewport_size.y < 680.0
	narrow_layout = viewport_size.x < 760.0
	var outer_margin := 10 if viewport_size.y < 640.0 else 18
	safe_margin.add_theme_constant_override("margin_left", outer_margin)
	safe_margin.add_theme_constant_override("margin_top", outer_margin)
	safe_margin.add_theme_constant_override("margin_right", outer_margin)
	safe_margin.add_theme_constant_override("margin_bottom", outer_margin)
	modal.add_child(safe_margin)
	var panel := PanelContainer.new()
	panel.name = "TrainingPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.02, 0.019, 0.98), Color("#8fa164"), 8))
	safe_margin.add_child(panel)
	var margin := MarginContainer.new()
	var inner_margin := 12 if compact_layout else 24
	margin.add_theme_constant_override("margin_left", inner_margin)
	margin.add_theme_constant_override("margin_top", inner_margin)
	margin.add_theme_constant_override("margin_right", inner_margin)
	margin.add_theme_constant_override("margin_bottom", inner_margin)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10 if compact_layout else 14)
	margin.add_child(content)
	_rebuild_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(ui_layer) or not ui_layer.is_inside_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		ui_layer.queue_free()
		get_viewport().set_input_as_handled()


func _rebuild_ui() -> void:
	for child in content.get_children():
		child.queue_free()
	var header := VBoxContainer.new()
	header.name = "TrainingHeader"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_theme_constant_override("separation", 5)
	content.add_child(header)
	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 12)
	header.add_child(top_row)
	var title := _label("생존 체력 훈련장", 24 if compact_layout else 30, Color("#e7d58f"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_row.add_child(title)
	var resource_panel := PanelContainer.new()
	resource_panel.custom_minimum_size = Vector2(134 if compact_layout else 168, 40)
	resource_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resource_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("#101716"), Color(0.66, 0.56, 0.28, 0.72), 6)
	)
	var resource_box := HBoxContainer.new()
	resource_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resource_box.add_theme_constant_override("separation", 8)
	resource_panel.add_child(resource_box)
	var resource_icon := TextureRect.new()
	resource_icon.custom_minimum_size = Vector2(28, 28)
	resource_icon.texture = UI_ICONS.get_icon("food", 38, Color("#efbd66"))
	resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_box.add_child(resource_icon)
	var resource_value := _label("통조림  %d" % GameState.canned_food, 16 if compact_layout else 18, Color("#efbd66"))
	resource_value.name = "TrainingResourceLabel"
	resource_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resource_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	resource_box.add_child(resource_value)
	top_row.add_child(resource_panel)
	var close := _close_button()
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: ui_layer.queue_free())
	top_row.add_child(close)
	var subtitle := _label(
		"레이드에서 확보한 통조림을 훈련에 투자해 영구 능력을 개방합니다.",
		14 if compact_layout else 15,
		Color("#9eafa6")
	)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subtitle)

	var summary := GridContainer.new()
	summary.columns = 1 if narrow_layout else (2 if compact_layout else 4)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("h_separation", 10)
	summary.add_theme_constant_override("v_separation", 8)
	content.add_child(summary)
	_add_summary_chip(summary, "health", "최대 체력", "%d" % GameState.get_max_health(), Color("#e87668"))
	_add_summary_chip(summary, "stamina", "스태미나", "%d" % roundi(GameState.get_max_stamina()), Color("#e4ca6c"))
	_add_summary_chip(summary, "speed", "이동 배율", "x%.2f" % GameState.get_move_speed_multiplier(), Color("#77c5a1"))
	_add_summary_chip(summary, "fitness", "피로 획득", "x%.2f" % GameState.get_fatigue_gain_multiplier(), Color("#8db5d1"))

	var divider := HSeparator.new()
	content.add_child(divider)
	content.add_child(_label("영구 강화 트리", 21, Color("#dce4dc")))
	var scroll := ScrollContainer.new()
	scroll.name = "TrainingTreeScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = false
	content.add_child(scroll)
	var tree := GridContainer.new()
	tree.columns = 1 if narrow_layout else (2 if compact_layout else 3)
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.add_theme_constant_override("h_separation", 16)
	tree.add_theme_constant_override("v_separation", 14)
	scroll.add_child(tree)
	_add_training_card(tree, "vitality")
	_add_connector(tree, "중량 훈련 2단계 필요")
	_add_training_card(tree, "recovery")
	_add_training_card(tree, "endurance")
	_add_connector(tree, "유산소 훈련 2단계 필요")
	_add_training_card(tree, "agility")
	_add_spacer(tree)
	_add_connector(tree, "회복 루틴·풋워크 2단계")
	_add_training_card(tree, "fieldcraft")
	status_label = _label("강화 노드를 선택하면 비용과 선행 조건을 확인할 수 있습니다.", 15, Color("#9db0a6"))
	content.add_child(status_label)


func _add_summary_chip(parent: Container, icon_name: String, title: String, value: String, color: Color) -> void:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _panel_style(Color("#101716"), Color(0.43, 0.52, 0.48, 0.45), 6))
	parent.add_child(chip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.texture = UI_ICONS.get_icon(icon_name, 42, color)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(_label(title, 13, Color("#92a39b")))
	text_box.add_child(_label(value, 20, Color("#e6ece7")))
	row.add_child(text_box)


func _add_training_card(parent: GridContainer, node_id: String) -> void:
	var definition := GameState.get_training_definition(node_id)
	var rank := GameState.get_training_rank(node_id)
	var max_rank := int(definition.get("max_rank", 1))
	var cost := GameState.get_training_cost(node_id)
	var requirements_met := GameState.get_training_requirements_met(node_id)
	var card := Button.new()
	card.custom_minimum_size = Vector2(0 if narrow_layout or compact_layout else 250, 118 if compact_layout else 126)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.text = "%s   %d/%d\n%s\n%s" % [
		str(definition.get("title", node_id)),
		rank,
		max_rank,
		str(definition.get("description", "")),
		"최대 단계" if rank >= max_rank else ("선행 강화 필요" if not requirements_met else "통조림 %d · 강화" % cost),
	]
	card.icon = UI_ICONS.get_icon(str(definition.get("icon", "fitness")), 54, Color("#d9c874"))
	card.expand_icon = false
	card.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_font_override("font", FONT)
	card.add_theme_font_size_override("font_size", 16)
	card.add_theme_color_override("font_color", Color("#e4ebe5"))
	card.add_theme_color_override("font_disabled_color", Color(0.66, 0.7, 0.68, 0.55))
	card.add_theme_stylebox_override("normal", _panel_style(Color("#101514"), Color("#596760"), 7))
	card.add_theme_stylebox_override("hover", _panel_style(Color("#1b231d"), Color("#d6c36f"), 7))
	card.add_theme_stylebox_override("pressed", _panel_style(Color("#292a1c"), Color("#f0d77d"), 7))
	card.disabled = rank >= max_rank or not requirements_met
	card.pressed.connect(_upgrade_training.bind(node_id))
	parent.add_child(card)


func _add_connector(parent: GridContainer, text: String) -> void:
	var connector := VBoxContainer.new()
	connector.alignment = BoxContainer.ALIGNMENT_CENTER
	connector.add_child(_label("↓" if narrow_layout else "→", 28, Color("#7c8c84")))
	var note := _label(text, 12, Color("#84968d"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connector.add_child(note)
	parent.add_child(connector)


func _add_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(80, 40)
	parent.add_child(spacer)


func _upgrade_training(node_id: String) -> void:
	var result := GameState.try_upgrade_training(node_id)
	if bool(result.get("ok", false)):
		_rebuild_ui()
		return
	var reason := str(result.get("reason", ""))
	status_label.text = (
		"통조림이 부족합니다. 필요 수량: %d" % int(result.get("cost", 0))
		if reason == "canned_food"
		else "선행 강화를 먼저 완료해야 합니다."
	)


func _button(text: String, icon_name: String = "") -> Button:
	var button := Button.new()
	button.text = text
	if not icon_name.is_empty():
		button.icon = UI_ICONS.get_icon(icon_name, 28, Color("#dce5df"))
		button.expand_icon = true
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#111716"), Color("#64766d"), 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#1b2420"), Color("#d9c579"), 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#29291b"), Color("#e2c66e"), 6))
	return button


func _close_button() -> Button:
	var button := _button("", "close")
	button.name = "CloseButton"
	button.custom_minimum_size = Vector2(40, 40)
	button.icon = UI_ICONS.get_icon("close", 24, Color("#dce5df"))
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = "닫기"
	button.focus_mode = Control.FOCUS_NONE
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style
