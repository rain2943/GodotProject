class_name ShelterWorkbenchModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const WEAPON_SYSTEM := preload("res://scripts/weapon_system.gd")
const MOD_CHIP_BUTTON := preload("res://scripts/mod_chip_button.gd")
const MOD_SLOT_DROP_PANEL := preload("res://scripts/mod_slot_drop_panel.gd")

const MOD_COMPONENTS := {
	"scope_2x": {"component": "scope_lens", "amount": 1, "scrap": 35},
	"muffled_sock": {"component": "rubber_gasket", "amount": 1, "scrap": 25},
	"sponge_pad": {"component": "rubber_gasket", "amount": 1, "scrap": 45},
	"quick_mag": {"component": "magazine_spring", "amount": 1, "scrap": 55},
	"bell_bait": {"component": "magazine_spring", "amount": 1, "scrap": 20},
	"ak_precision_receiver": {"component": "scope_lens", "amount": 2, "scrap": 160},
}
const SLOT_ORDER := ["sight", "muzzle", "stock", "magazine", "tactical", "special"]
const SLOT_POSITIONS := {
	"sight": Vector2(270, 46),
	"muzzle": Vector2(526, 116),
	"stock": Vector2(34, 148),
	"magazine": Vector2(326, 298),
	"tactical": Vector2(188, 314),
	"special": Vector2(486, 288),
}

@export var interaction_radius := 2.9

@onready var sprite: Sprite3D = $WorkbenchSprite

var has_focus := false
var ui_layer: CanvasLayer
var content_root: Control
var stat_compare_label: Label
var component_icon_cache: Dictionary = {}


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("shelter_workbench")
	set_meta("module_kind", "workbench")


func get_interaction_prompt() -> String:
	return "무기 모딩 작업대"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	GameState.process_shelter_progress()
	GameState.claim_workbench_starter_parts()
	if not GameState.can_mod_weapon(GameState.equipped_weapon_id) and GameState.get_weapon_count("mp5") > 0:
		_select_weapon_base("mp5")
	_open_ui()
	return "작업대 기본 부품 상자를 열었습니다. 부품 카드를 슬롯으로 끌거나 클릭해서 장착하세요."


func set_interaction_focus(value: bool) -> void:
	has_focus = value
	if sprite:
		sprite.modulate = Color(1.16, 1.12, 0.88, 1.0) if has_focus else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "WorkbenchUILayer"
	ui_layer.layer = 20
	var ui_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	ui_parent.add_child(ui_layer)
	_rebuild_ui()


func _rebuild_ui() -> void:
	if not is_instance_valid(ui_layer):
		return
	for child in ui_layer.get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 14
	panel.offset_top = 12
	panel.offset_right = -14
	panel.offset_bottom = -12
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.011, 0.017, 0.016, 0.97), Color("#86c6a6"), 2, 8))
	ui_layer.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)

	content_root = VBoxContainer.new()
	content_root.custom_minimum_size = Vector2(1140, 650)
	content_root.add_theme_constant_override("separation", 14)
	margin.add_child(content_root)

	_build_header()
	_build_weapon_selector()
	_build_body()
	_build_actions()


func _build_header() -> void:
	var header := HBoxContainer.new()
	content_root.add_child(header)
	var title := _label("무기 모딩 작업대  Lv.%d" % GameState.shelter_workbench_level, 26, Color("#f2e4bc"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button("닫기")
	close.custom_minimum_size = Vector2(72, 42)
	close.pressed.connect(func(): ui_layer.queue_free())
	header.add_child(close)


func _build_weapon_selector() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content_root.add_child(row)
	row.add_child(_label("베이스 총기", 15, Color("#91aaa0")))
	for weapon_id in ["m1911", "mp5", "ak47", "double_barrel"]:
		if GameState.get_weapon_count(weapon_id) <= 0:
			continue
		var definition := WEAPON_SYSTEM.get_weapon(weapon_id)
		var button := _button(str(definition.get("display_name", weapon_id)))
		button.toggle_mode = true
		button.button_pressed = weapon_id == GameState.equipped_weapon_id
		button.disabled = weapon_id == GameState.equipped_weapon_id
		button.custom_minimum_size = Vector2(170, 42)
		button.pressed.connect(func(): _select_weapon_base(weapon_id))
		row.add_child(button)


func _build_body() -> void:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_root.add_child(body)

	var board := _build_mod_board()
	body.add_child(board)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(410, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	body.add_child(side)

	side.add_child(_build_stat_card())
	side.add_child(_build_inventory_panel())


func _build_mod_board() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 470)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.029, 0.028, 0.94), Color("#3f6f63"), 1, 8))
	var board := Control.new()
	board.custom_minimum_size = Vector2(720, 470)
	panel.add_child(board)

	var weapon_id := GameState.equipped_weapon_id
	var weapon_def := WEAPON_SYSTEM.get_weapon(weapon_id)
	var weapon_card := PanelContainer.new()
	weapon_card.position = Vector2(214, 136)
	weapon_card.size = Vector2(285, 126)
	weapon_card.add_theme_stylebox_override("panel", _panel_style(Color("#141f1e"), Color("#d2b86a"), 2, 8))
	board.add_child(weapon_card)
	var weapon_box := VBoxContainer.new()
	weapon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_box.add_theme_constant_override("separation", 6)
	weapon_card.add_child(weapon_box)
	weapon_box.add_child(_label(str(weapon_def.get("display_name", weapon_id)), 20, Color("#f2e4bc")))
	weapon_box.add_child(_label("내구도 %.1f%%  |  %s" % [
		GameState.weapon_durability,
		"수리 중" if GameState.workbench_repair_active else "수리 대기",
	], 14, Color("#c6d4cb")))
	weapon_box.add_child(_label("부품을 주변 슬롯으로 드래그", 13, Color("#86c6a6")))

	for slot in SLOT_ORDER:
		board.add_child(_connection_line(slot))
		var slot_panel := _slot_panel(slot)
		slot_panel.position = SLOT_POSITIONS[slot]
		board.add_child(slot_panel)

	return panel


func _connection_line(slot: String) -> Control:
	var line := Control.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.position = Vector2.ZERO
	line.size = Vector2(720, 470)
	line.draw.connect(func():
		var from := Vector2(356, 200)
		var to: Vector2 = SLOT_POSITIONS[slot] + Vector2(70, 44)
		var installed := not _get_mod_in_slot(slot).is_empty()
		line.draw_line(from, to, Color(0.55, 0.82, 0.68, 0.52 if installed else 0.22), 2.0)
	)
	return line


func _slot_panel(slot: String) -> PanelContainer:
	var panel := MOD_SLOT_DROP_PANEL.new()
	panel.slot_name = slot
	panel.workbench = self
	panel.custom_minimum_size = Vector2(152, 86)
	panel.size = Vector2(152, 86)
	var installed := _get_mod_in_slot(slot)
	var active := not installed.is_empty()
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color(0.025, 0.038, 0.034, 0.96), Color("#83caa5") if active else Color("#426a5f"), 2 if active else 1, 7)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.texture = _slot_icon(slot)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 3)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	texts.add_child(_label(_slot_name(slot), 13, Color("#8fb3a7")))
	var value_text := "비어 있음"
	if active:
		value_text = str(WEAPON_SYSTEM.get_mod(installed).get("display_name", installed))
	texts.add_child(_label(value_text, 13, Color("#e1dfd2")))
	if active:
		var remove := _button("해제")
		remove.custom_minimum_size = Vector2(48, 28)
		remove.pressed.connect(func(): _remove_mod(installed))
		row.add_child(remove)
	return panel


func _build_stat_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(410, 132)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.033, 0.95), Color("#415d55"), 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	stat_compare_label = _label(_build_stat_compare_text(""), 14, Color("#c7d8cc"))
	margin.add_child(stat_compare_label)
	return panel


func _build_inventory_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.024, 0.023, 0.95), Color("#415d55"), 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(_label("보유 부품 가방", 20, Color("#e3d49b")))
	box.add_child(_label("카드를 슬롯에 끌어 놓거나 클릭하면 장착됩니다.", 13, Color("#91aaa0")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for mod_id in MOD_COMPONENTS.keys():
		list.add_child(_mod_button(mod_id))
	return panel


func _build_actions() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content_root.add_child(row)
	var repair := _button("시간제 수리 시작")
	repair.pressed.connect(_start_repair)
	row.add_child(repair)
	var instant := _button("고철 60 즉시 수리")
	instant.disabled = GameState.scrap < 60 or GameState.weapon_durability >= 100.0
	instant.pressed.connect(_instant_repair)
	row.add_child(instant)
	var upgrade_cost := int(GameState.WORKBENCH_UPGRADE_COSTS.get(GameState.shelter_workbench_level + 1, 0))
	var upgrade := _button("최고 레벨" if upgrade_cost == 0 else "Lv.%d 업그레이드  고철 %d" % [GameState.shelter_workbench_level + 1, upgrade_cost])
	upgrade.disabled = upgrade_cost == 0 or GameState.scrap < upgrade_cost
	upgrade.pressed.connect(_upgrade)
	row.add_child(upgrade)
	var footer := _label("고철 %d  |  장착 슬롯 %d개  |  Lv.3부터 소총 개조, Lv.5부터 특수 모듈 해금" % [
		GameState.scrap,
		GameState.get_workbench_slot_limit(),
	], 14, Color("#9fb8ad"))
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer)


func _mod_button(mod_id: String) -> Button:
	var definition := WEAPON_SYSTEM.get_mod(mod_id)
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	var needed := int(cost["amount"])
	var available := GameState.get_mod_component_count(component_id)
	var can_install := can_install_mod(mod_id)
	var button := MOD_CHIP_BUTTON.new()
	button.mod_id = mod_id
	button.slot_name = str(definition.get("slot", ""))
	button.text = "%s\n%s 슬롯  |  %s %d/%d  |  고철 %d" % [
		str(definition.get("display_name", mod_id)),
		_slot_name(button.slot_name),
		_component_name(component_id),
		available,
		needed,
		int(cost["scrap"]),
	]
	button.icon = _component_icon(component_id)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(362, 68)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.disabled = not can_install
	button.tooltip_text = _mod_tooltip(mod_id)
	button.mouse_entered.connect(func(): _show_mod_preview(mod_id))
	button.mouse_exited.connect(func(): _show_mod_preview(""))
	button.focus_entered.connect(func(): _show_mod_preview(mod_id))
	button.focus_exited.connect(func(): _show_mod_preview(""))
	button.pressed.connect(func(): _install_mod(mod_id))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.05, 0.047, 0.96), Color("#567a6f") if can_install else Color("#333b38"), 1, 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.065, 0.085, 0.075, 0.98), Color("#86c6a6"), 1, 6))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.028, 0.03, 0.03, 0.78), Color("#2d3532"), 1, 6))
	return button


func can_install_mod(mod_id: String) -> bool:
	if not MOD_COMPONENTS.has(mod_id):
		return false
	var definition := WEAPON_SYSTEM.get_mod(mod_id)
	if definition.is_empty():
		return false
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	var slot := str(definition.get("slot", ""))
	return (
		GameState.can_mod_weapon(GameState.equipped_weapon_id)
		and WEAPON_SYSTEM.validate_mod_loadout([mod_id], GameState.equipped_weapon_id)
		and not GameState.equipped_weapon_mods.has(mod_id)
		and not _slot_occupied(slot)
		and not (slot == "special" and GameState.shelter_workbench_level < 5)
		and GameState.get_mod_component_count(component_id) >= int(cost["amount"])
		and GameState.scrap >= int(cost["scrap"])
	)


func install_mod_from_drop(mod_id: String) -> void:
	if can_install_mod(mod_id):
		_install_mod(mod_id)


func _install_mod(mod_id: String) -> void:
	if not can_install_mod(mod_id):
		return
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	GameState.mod_component_inventory[component_id] = GameState.get_mod_component_count(component_id) - int(cost["amount"])
	GameState.scrap -= int(cost["scrap"])
	GameState.equipped_weapon_mods.append(mod_id)
	_rebuild_ui()


func _remove_mod(mod_id: String) -> void:
	GameState.equipped_weapon_mods.erase(mod_id)
	_rebuild_ui()


func _select_weapon_base(weapon_id: String) -> void:
	GameState.equipped_weapon_id = weapon_id
	var weapon_definition := WEAPON_SYSTEM.get_weapon(weapon_id)
	GameState.equipped_magazine_id = str(weapon_definition.get("magazine_id", GameState.equipped_magazine_id))
	GameState.equipped_ammo_id = str(weapon_definition.get("default_ammo_id", GameState.equipped_ammo_id))
	GameState.equipped_weapon_mods.clear()
	_rebuild_ui()


func _start_repair() -> void:
	GameState.workbench_repair_active = true
	GameState.workbench_repair_weapon_id = GameState.equipped_weapon_id
	GameState.process_shelter_progress()
	_rebuild_ui()


func _instant_repair() -> void:
	if GameState.scrap < 60:
		return
	GameState.scrap -= 60
	GameState.weapon_durability = minf(100.0, GameState.weapon_durability + 28.0)
	if GameState.weapon_durability >= 100.0:
		GameState.workbench_repair_active = false
	_rebuild_ui()


func _upgrade() -> void:
	if GameState.try_upgrade_workbench():
		_rebuild_ui()


func _get_mod_in_slot(slot: String) -> String:
	for mod_id in GameState.equipped_weapon_mods:
		var definition := WEAPON_SYSTEM.get_mod(str(mod_id))
		if str(definition.get("slot", "")) == slot:
			return str(mod_id)
	return ""


func _slot_occupied(slot: String) -> bool:
	return not _get_mod_in_slot(slot).is_empty()


func _show_mod_preview(mod_id: String) -> void:
	if stat_compare_label:
		stat_compare_label.text = _build_stat_compare_text(mod_id)


func _build_stat_compare_text(preview_mod_id: String) -> String:
	var weapon_id := GameState.equipped_weapon_id
	var current_mods: Array[String] = []
	current_mods.assign(GameState.equipped_weapon_mods)
	var preview_mods: Array[String] = []
	preview_mods.assign(current_mods)
	var preview_name := "현재 장착"
	if not preview_mod_id.is_empty():
		preview_name = str(WEAPON_SYSTEM.get_mod(preview_mod_id).get("display_name", preview_mod_id))
		if can_install_mod(preview_mod_id):
			preview_mods.append(preview_mod_id)
	var current_stats := WEAPON_SYSTEM.build_stats(weapon_id, current_mods)
	var preview_stats := WEAPON_SYSTEM.build_stats(weapon_id, preview_mods)
	return "%s\n피해 %s   탄퍼짐 %s\n반동 %s   장전 %s   소음 %s" % [
		preview_name,
		_stat_delta(current_stats, preview_stats, "damage", false),
		_stat_delta(current_stats, preview_stats, "base_spread_deg", true),
		_stat_delta(current_stats, preview_stats, "recoil_kick", true),
		_stat_delta(current_stats, preview_stats, "reload_time", true),
		_stat_delta(current_stats, preview_stats, "sound_radius", true),
	]


func _stat_delta(current_stats: Dictionary, preview_stats: Dictionary, stat_name: String, lower_is_better: bool) -> String:
	var current := float(current_stats.get(stat_name, 0.0))
	var preview := float(preview_stats.get(stat_name, current))
	var delta := preview - current
	var sign := "+" if delta > 0.001 else ""
	var marker := ""
	if absf(delta) > 0.001:
		var better := false
		if lower_is_better:
			better = delta < 0.0
		else:
			better = delta > 0.0
		marker = " ▲" if better else " ▼"
	return "%.2f -> %.2f (%s%.2f)%s" % [current, preview, sign, delta, marker]


func _mod_tooltip(mod_id: String) -> String:
	var definition := WEAPON_SYSTEM.get_mod(mod_id)
	var component_id := str(MOD_COMPONENTS[mod_id]["component"])
	var slot := str(definition.get("slot", ""))
	if not GameState.can_mod_weapon(GameState.equipped_weapon_id):
		return "현재 작업대 레벨에서는 권총/기관단총만 개조할 수 있습니다."
	if slot == "special" and GameState.shelter_workbench_level < 5:
		return "특수 모듈은 작업대 Lv.5에서 해금됩니다."
	if _slot_occupied(slot):
		return "%s 슬롯이 이미 사용 중입니다." % _slot_name(slot)
	if GameState.get_mod_component_count(component_id) < int(MOD_COMPONENTS[mod_id]["amount"]):
		return "%s이 부족합니다." % _component_name(component_id)
	if GameState.scrap < int(MOD_COMPONENTS[mod_id]["scrap"]):
		return "고철이 부족합니다."
	return "드래그하거나 클릭해서 %s 슬롯에 장착합니다." % _slot_name(slot)


func _slot_name(slot: String) -> String:
	match slot:
		"sight": return "조준경"
		"muzzle": return "총구"
		"stock": return "개머리판"
		"magazine": return "탄창"
		"tactical": return "보조공구"
		"special": return "특수 모듈"
	return slot


func _component_name(component_id: String) -> String:
	match component_id:
		"rubber_gasket": return "고무 패킹"
		"scope_lens": return "스코프 렌즈"
		"magazine_spring": return "탄창 스프링"
	return component_id


func _component_icon(component_id: String) -> Texture2D:
	if component_icon_cache.has(component_id):
		return component_icon_cache[component_id]
	var texture := _make_icon_texture(component_id)
	component_icon_cache[component_id] = texture
	return texture


func _slot_icon(slot: String) -> Texture2D:
	return _make_icon_texture(slot)


func _make_icon_texture(kind: String) -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, Rect2i(5, 5, 54, 54), Color(0.07, 0.11, 0.1, 0.92))
	_stroke_rect(image, Rect2i(5, 5, 54, 54), Color("#83b89e"))
	match kind:
		"scope_lens", "sight":
			_draw_circle(image, Vector2i(32, 32), 17, Color("#68d8d0"))
			_draw_circle(image, Vector2i(32, 32), 10, Color(0.04, 0.14, 0.15, 1.0))
			_draw_circle(image, Vector2i(38, 25), 4, Color("#d8fff0"))
		"rubber_gasket", "muzzle", "stock":
			_draw_circle(image, Vector2i(32, 32), 18, Color("#4e5653"))
			_draw_circle(image, Vector2i(32, 32), 9, Color(0.015, 0.02, 0.02, 1.0))
			_stroke_rect(image, Rect2i(18, 27, 28, 10), Color("#b9c0aa"))
		"magazine_spring", "magazine", "tactical":
			for i in range(7):
				_draw_line(image, Vector2i(15 + i * 5, 21), Vector2i(19 + i * 5, 43), Color("#d6c06f"))
				_draw_line(image, Vector2i(19 + i * 5, 43), Vector2i(23 + i * 5, 21), Color("#d6c06f"))
		"special":
			_draw_circle(image, Vector2i(32, 32), 18, Color("#d49248"))
			_draw_line(image, Vector2i(20, 32), Vector2i(44, 32), Color("#fff0aa"))
			_draw_line(image, Vector2i(32, 20), Vector2i(32, 44), Color("#fff0aa"))
		_:
			_fill_rect(image, Rect2i(19, 19, 26, 26), Color("#7e9f90"))
	return ImageTexture.create_from_image(image)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _stroke_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		image.set_pixel(x, rect.position.y, color)
		image.set_pixel(x, rect.position.y + rect.size.y - 1, color)
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		image.set_pixel(rect.position.x, y, color)
		image.set_pixel(rect.position.x + rect.size.x - 1, y, color)


func _draw_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_squared := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var delta := Vector2i(x - center.x, y - center.y)
			if delta.x * delta.x + delta.y * delta.y <= radius_squared and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var delta := to - from
	var steps := maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var point := Vector2i(roundi(lerpf(from.x, to.x, t)), roundi(lerpf(from.y, to.y, t)))
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				var x := point.x + ox
				var y := point.y + oy
				if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
					image.set_pixel(x, y, color)


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


func _panel_style(background: Color, border: Color, width := 1, radius := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style
