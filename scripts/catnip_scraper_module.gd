class_name CatnipScraperModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")

@export var interaction_radius := 2.35

@onready var sprite: Sprite3D = $ScraperSprite

var ui_layer: CanvasLayer
var content: VBoxContainer


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("catnip_scraper")
	set_meta("module_kind", "catnip_scraper")


func get_interaction_prompt() -> String:
	return "스크래핑 캣닢 생산기"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	GameState.process_shelter_progress()
	_open_ui()
	return "주민을 배치해 캣닢을 자동 생산합니다."


func set_interaction_focus(value: bool) -> void:
	if sprite:
		sprite.modulate = Color(0.92, 1.16, 0.9, 1.0) if value else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "CatnipScraperUILayer"
	ui_layer.layer = 20
	var ui_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	ui_parent.add_child(ui_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-420, -280)
	panel.size = Vector2(840, 560)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.019, 0.97), Color("#6fa66d")))
	ui_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	_rebuild_ui()


func _rebuild_ui() -> void:
	GameState._ensure_resident_records()
	for child in content.get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := _label("스크래핑 캣닢 생산기", 24, Color("#d9efb0"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button("닫기")
	close.pressed.connect(func(): ui_layer.queue_free())
	header.add_child(close)
	content.add_child(_label("쉘터 Tier %d  ·  배치 %d / %d  ·  시간당 캣닢 %.2f" % [
		GameState.shelter_tier,
		GameState.get_active_catnip_workers(),
		GameState.get_catnip_worker_slots(),
		GameState.get_catnip_per_hour(),
	], 17, Color("#d3ded4")))
	content.add_child(_label("캣닢 효율이 높은 주민을 배치하면 부스터를 더 자주 사용할 수 있습니다.", 14, Color("#9fb8a0")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	scroll.add_child(grid)
	for resident_index in GameState.resident_cat_ids.size():
		grid.add_child(_resident_button(str(GameState.resident_cat_ids[resident_index])))
	if GameState.resident_cat_ids.is_empty():
		grid.add_child(_label("구출한 주민이 없습니다.", 15, Color("#7d887f")))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)
	var collect := _button("진행 정산")
	collect.pressed.connect(_collect_progress)
	footer.add_child(collect)
	var remaining: int = GameState.get_catnip_boost_remaining()
	var status := "부스터 대기" if remaining <= 0 else "고철 x10  %02d:%02d" % [remaining / 60, remaining % 60]
	footer.add_child(_label("보유 캣닢 %.1f  ·  %s" % [GameState.catnip, status], 16, Color("#cde79e")))


func _resident_button(resident_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 86)
	var active := GameState.assigned_catnip_worker_ids.has(resident_id)
	var available := active or GameState.assigned_catnip_worker_ids.size() < GameState.get_catnip_worker_slots()
	var trait_data: Dictionary = GameState.get_resident_trait(resident_id)
	var border := Color("#7fc779") if active else (Color("#60735c") if available else Color("#343a35"))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.045, 0.034, 0.96), border))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.05, 0.075, 0.052, 0.98), Color("#b8dc83")))
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.disabled = not available
	button.text = "%s · %s\n%s  ·  캣닢 x%.2f" % [
		resident_id,
		trait_data.get("name", "평범한 주민"),
		"스크래핑 중" if active else "대기",
		trait_data.get("catnip", 1.0),
	]
	button.pressed.connect(func(): _toggle_worker(resident_id))
	return button


func _toggle_worker(resident_id: String) -> void:
	GameState.toggle_catnip_worker_assignment(resident_id)
	get_tree().call_group("shelter_resident_host", "refresh_shelter_residents", false)
	_rebuild_ui()


func _collect_progress() -> void:
	GameState.process_shelter_progress()
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
