extends Control

signal open_state_changed(is_open: bool)
signal weapon_mods_changed

const WEAPON_SYSTEM := preload("res://scripts/weapon_system.gd")

const SLOT_ORDER := ["sight", "muzzle", "stock", "magazine", "tactical", "special"]
const MOD_COMPONENTS := {
	"scope_2x": {"component": "scope_lens", "amount": 1, "scrap": 35},
	"muffled_sock": {"component": "rubber_gasket", "amount": 1, "scrap": 25},
	"sponge_pad": {"component": "rubber_gasket", "amount": 1, "scrap": 45},
	"quick_mag": {"component": "magazine_spring", "amount": 1, "scrap": 55},
	"bell_bait": {"component": "magazine_spring", "amount": 1, "scrap": 20},
	"ak_precision_receiver": {"component": "scope_lens", "amount": 2, "scrap": 160},
}

var font_ref: Font
var weapon_texture: Texture2D
var ammo_texture: Texture2D
var component_textures: Dictionary = {}

var opened := false
var weapon_detail_open := false

var modal: Control
var open_button: Button
var equipped_grid: GridContainer
var bag_grid: GridContainer
var loot_grid: GridContainer
var quickbar: HBoxContainer
var weapon_title: Label
var weapon_stats: Label
var mod_slot_grid: GridContainer
var mod_inventory_list: VBoxContainer
var weight_label: Label

var has_weapon_state := false
var magazine_state := 0
var reserve_state := 0
var weapon_name_state := "AK-47"
var magazine_size_state := 30
var durability_state := 100.0
var mod_names_state: Array[String] = []
var canned_food_state := 0
var stored_weapons_state := 0
var mod_components_state: Dictionary = {}
var rescued_workers_state := 0
var fatigue_state := 0.0


func setup(
	font: Font,
	next_weapon_texture: Texture2D,
	next_ammo_texture: Texture2D,
	next_component_textures: Dictionary = {}
) -> void:
	font_ref = font
	weapon_texture = next_weapon_texture
	ammo_texture = next_ammo_texture
	component_textures = next_component_textures
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_open_button()
	_build_modal()
	set_open(false)


func update_state(
	has_weapon: bool,
	magazine: int,
	reserve: int,
	weapon_name: String = "AK-47",
	magazine_size: int = 30,
	durability: float = 100.0,
	mod_names: Array[String] = [],
	canned_food: int = 0,
	stored_weapons: int = 0,
	mod_components: Dictionary = {},
	rescued_workers: int = 0,
	fatigue: float = 0.0
) -> void:
	has_weapon_state = has_weapon
	magazine_state = magazine
	reserve_state = reserve
	weapon_name_state = weapon_name
	magazine_size_state = magazine_size
	durability_state = durability
	mod_names_state = mod_names
	canned_food_state = canned_food
	stored_weapons_state = stored_weapons
	mod_components_state = mod_components.duplicate(true)
	rescued_workers_state = rescued_workers
	fatigue_state = fatigue
	if opened:
		_refresh_contents()


func toggle() -> void:
	set_open(not opened)


func set_open(value: bool) -> void:
	opened = value
	if modal:
		modal.visible = opened
	if open_button:
		open_button.visible = not opened
	if opened:
		_refresh_contents()
	open_state_changed.emit(opened)


func is_open() -> bool:
	return opened


func _build_open_button() -> void:
	open_button = Button.new()
	open_button.name = "InventoryButton"
	open_button.text = "가방"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.offset_left = -94
	open_button.offset_top = 112
	open_button.offset_right = -22
	open_button.offset_bottom = 154
	_apply_button_font(open_button, 14)
	open_button.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.027, 0.025, 0.94), Color("#8ab7a0"), 6))
	open_button.add_theme_stylebox_override("hover", _panel_style(Color(0.06, 0.075, 0.068, 0.98), Color("#d9c579"), 6))
	open_button.pressed.connect(toggle)
	add_child(open_button)


func _build_modal() -> void:
	modal = Control.new()
	modal.name = "InventoryModal"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.008, 0.01, 0.014, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 38
	root.offset_top = 30
	root.offset_right = -38
	root.offset_bottom = -36
	root.add_theme_constant_override("separation", 22)
	modal.add_child(root)

	root.add_child(_build_inventory_panel())
	root.add_child(_build_weapon_panel())
	root.add_child(_build_loot_panel())
	_build_quickbar()


func _build_inventory_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 620)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.085, 0.096, 0.105, 0.82), Color(0.78, 0.82, 0.82, 0.42), 10))
	var margin := _margin(14, 14, 14, 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	top.add_child(_label("인벤토리", 22, Color("#f0e8d0")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_label("고철 %d" % GameState.scrap, 18, Color("#f0d889")))

	box.add_child(_section("장비"))
	equipped_grid = GridContainer.new()
	equipped_grid.columns = 4
	equipped_grid.add_theme_constant_override("h_separation", 10)
	equipped_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(equipped_grid)

	box.add_child(_section("가방"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	bag_grid = GridContainer.new()
	bag_grid.columns = 5
	bag_grid.add_theme_constant_override("h_separation", 8)
	bag_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(bag_grid)

	var weight_panel := PanelContainer.new()
	weight_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.026, 0.03, 0.84), Color(0.75, 0.8, 0.78, 0.25), 8))
	box.add_child(weight_panel)
	var weight_row := HBoxContainer.new()
	weight_row.add_theme_constant_override("separation", 8)
	weight_panel.add_child(weight_row)
	weight_row.add_child(_label("소지 중량", 13, Color("#d7ddd6")))
	weight_label = _label("0 / 49kg", 13, Color("#b7ef72"))
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weight_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weight_row.add_child(weight_label)
	return panel


func _build_weapon_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 620)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.036, 0.044, 0.05, 0.74), Color(0.86, 0.92, 0.86, 0.32), 10))
	var margin := _margin(20, 18, 20, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	weapon_title = _label("무기 상세", 26, Color("#f0e8cf"))
	box.add_child(weapon_title)

	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 18)
	box.add_child(preview)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(154, 96)
	icon.texture = weapon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(icon)
	weapon_stats = _label("", 14, Color("#d6ddd5"))
	weapon_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_child(weapon_stats)

	box.add_child(_section("부착 슬롯"))
	mod_slot_grid = GridContainer.new()
	mod_slot_grid.columns = 2
	mod_slot_grid.add_theme_constant_override("h_separation", 10)
	mod_slot_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(mod_slot_grid)

	box.add_child(_section("보유 부품"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	mod_inventory_list = VBoxContainer.new()
	mod_inventory_list.add_theme_constant_override("separation", 8)
	scroll.add_child(mod_inventory_list)
	return panel


func _build_loot_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 260)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.085, 0.096, 0.105, 0.78), Color(0.78, 0.82, 0.82, 0.36), 10))
	var margin := _margin(14, 14, 14, 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	box.add_child(_label("전리품", 28, Color("#f0e8cf")))
	loot_grid = GridContainer.new()
	loot_grid.columns = 5
	loot_grid.add_theme_constant_override("h_separation", 8)
	loot_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(loot_grid)
	return panel


func _build_quickbar() -> void:
	quickbar = HBoxContainer.new()
	quickbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	quickbar.offset_left = -260
	quickbar.offset_top = -86
	quickbar.offset_right = 260
	quickbar.offset_bottom = -18
	quickbar.add_theme_constant_override("separation", 12)
	modal.add_child(quickbar)


func _refresh_contents() -> void:
	if equipped_grid == null:
		return
	_clear(equipped_grid)
	_clear(bag_grid)
	_clear(loot_grid)
	_clear(quickbar)
	_clear(mod_slot_grid)
	_clear(mod_inventory_list)

	equipped_grid.add_child(_item_button("주무기", weapon_name_state if has_weapon_state else "비어 있음", "클릭: 개조", weapon_texture, has_weapon_state, _show_weapon_detail))
	equipped_grid.add_child(_item_button("보조무기", "비어 있음", "무기", null, false))
	equipped_grid.add_child(_item_button("몸체", "비어 있음", "방어구", null, false))
	equipped_grid.add_child(_item_button("머리", "비어 있음", "방어구", null, false))
	equipped_grid.add_child(_item_button("가방", "기본", "장비", null, true))
	equipped_grid.add_child(_item_button("도그", "잠김", "보안 슬롯", null, false))
	equipped_grid.add_child(_item_button("장신구", "비어 있음", "보조", null, false))
	equipped_grid.add_child(_item_button("탈출", "하수구", "목표", null, true))

	bag_grid.add_child(_item_button("7.62mm", "x%d" % reserve_state, "탄약", ammo_texture, reserve_state > 0))
	bag_grid.add_child(_item_button("통조림", "x%d" % canned_food_state, "재화", null, canned_food_state > 0))
	bag_grid.add_child(_item_button("보관 총기", "x%d" % stored_weapons_state, "무기", weapon_texture, stored_weapons_state > 0))
	for component_id in ["scope_lens", "rubber_gasket", "magazine_spring"]:
		bag_grid.add_child(_item_button(
			_component_name(component_id),
			"x%d" % int(mod_components_state.get(component_id, 0)),
			"부품",
			component_textures.get(component_id) as Texture2D,
			int(mod_components_state.get(component_id, 0)) > 0
		))
	for index in range(18):
		bag_grid.add_child(_empty_slot())

	loot_grid.add_child(_item_button("고철", "%d" % GameState.scrap, "재화", null, true))
	loot_grid.add_child(_item_button("피로", "%d%%" % roundi(fatigue_state), "상태", null, fatigue_state > 0.0))
	loot_grid.add_child(_item_button("구출 주민", "%d" % rescued_workers_state, "쉘터", null, rescued_workers_state > 0))
	for index in range(7):
		loot_grid.add_child(_empty_slot())

	for index in range(6):
		var text := ""
		match index:
			0:
				text = "소총\n%d" % magazine_state
			1:
				text = "물\n2"
			2:
				text = "붕대\n3"
			3:
				text = "통조림\n%d" % canned_food_state
			_:
				text = ""
		quickbar.add_child(_quick_slot(index + 3, text))

	var load := 6.3 + float(reserve_state) * 0.015 + float(canned_food_state) * 0.35 + float(stored_weapons_state) * 3.2
	weight_label.text = "%.1f / 49kg" % load
	_refresh_weapon_detail()


func _show_weapon_detail() -> void:
	weapon_detail_open = true
	_refresh_weapon_detail()


func _refresh_weapon_detail() -> void:
	if weapon_title == null:
		return
	var stats := WEAPON_SYSTEM.build_stats(GameState.equipped_weapon_id, GameState.equipped_weapon_mods)
	weapon_title.text = "%s 개조" % weapon_name_state
	weapon_stats.text = "탄창 %02d / %02d  예비 %03d\n내구도 %.1f%%  탄퍼짐 %.1f도\n피해 %d  반동 %.2f  장전 %.1fs\n부착물은 아래 부품을 클릭해서 장착합니다." % [
		magazine_state,
		magazine_size_state,
		reserve_state,
		durability_state,
		float(stats.get("base_spread_deg", 0.0)),
		int(stats.get("damage", 0)),
		float(stats.get("recoil_kick", 0.0)),
		float(stats.get("reload_time", 0.0)),
	]

	if mod_slot_grid == null:
		return
	_clear(mod_slot_grid)
	for slot in SLOT_ORDER:
		mod_slot_grid.add_child(_build_mod_slot_button(slot))

	if mod_inventory_list == null:
		return
	_clear(mod_inventory_list)
	for mod_id in MOD_COMPONENTS.keys():
		mod_inventory_list.add_child(_build_mod_install_button(str(mod_id)))


func _build_mod_slot_button(slot: String) -> Button:
	var installed := _get_mod_in_slot(slot)
	var text := "%s\n비어 있음" % _slot_name(slot)
	if not installed.is_empty():
		text = "%s\n%s\n클릭: 해제" % [_slot_name(slot), _mod_name(installed)]
	var button := _tile_button(text, not installed.is_empty())
	button.custom_minimum_size = Vector2(210, 76)
	button.icon = _slot_icon(slot)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not installed.is_empty():
		button.pressed.connect(func() -> void:
			GameState.equipped_weapon_mods.erase(installed)
			weapon_mods_changed.emit()
			_refresh_contents()
		)
	return button


func _build_mod_install_button(mod_id: String) -> Button:
	var definition := WEAPON_SYSTEM.get_mod(mod_id)
	var slot := str(definition.get("slot", ""))
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	var available := GameState.get_mod_component_count(component_id)
	var can_install := _can_install_mod(mod_id)
	var text := "%s\n%s 슬롯  |  %s %d/%d  |  고철 %d" % [
		_mod_name(mod_id),
		_slot_name(slot),
		_component_name(component_id),
		available,
		int(cost["amount"]),
		int(cost["scrap"]),
	]
	var button := _tile_button(text, can_install)
	button.custom_minimum_size = Vector2(430, 66)
	button.icon = component_textures.get(component_id) as Texture2D
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = not can_install
	button.pressed.connect(func() -> void:
		_install_mod(mod_id)
	)
	return button


func _can_install_mod(mod_id: String) -> bool:
	if not MOD_COMPONENTS.has(mod_id):
		return false
	var definition := WEAPON_SYSTEM.get_mod(mod_id)
	if definition.is_empty():
		return false
	var slot := str(definition.get("slot", ""))
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	var next_mods: Array[String] = []
	next_mods.assign(GameState.equipped_weapon_mods)
	next_mods.append(mod_id)
	return (
		_get_mod_in_slot(slot).is_empty()
		and WEAPON_SYSTEM.validate_mod_loadout(next_mods, GameState.equipped_weapon_id)
		and not (slot == "special" and GameState.shelter_workbench_level < 5)
		and GameState.get_mod_component_count(component_id) >= int(cost["amount"])
		and GameState.scrap >= int(cost["scrap"])
	)


func _install_mod(mod_id: String) -> void:
	if not _can_install_mod(mod_id):
		return
	var cost: Dictionary = MOD_COMPONENTS[mod_id]
	var component_id := str(cost["component"])
	GameState.mod_component_inventory[component_id] = GameState.get_mod_component_count(component_id) - int(cost["amount"])
	GameState.scrap -= int(cost["scrap"])
	GameState.equipped_weapon_mods.append(mod_id)
	weapon_mods_changed.emit()
	_refresh_contents()


func _get_mod_in_slot(slot: String) -> String:
	for mod_id in GameState.equipped_weapon_mods:
		var definition := WEAPON_SYSTEM.get_mod(str(mod_id))
		if str(definition.get("slot", "")) == slot:
			return str(mod_id)
	return ""


func _item_button(title: String, count: String, subtitle: String, texture: Texture2D, active: bool, pressed_callback: Callable = Callable()) -> Button:
	var button := _tile_button("%s\n%s\n%s" % [title, count, subtitle], active)
	button.custom_minimum_size = Vector2(76, 76)
	button.icon = texture
	button.expand_icon = texture != null
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pressed_callback.is_valid():
		button.pressed.connect(pressed_callback)
	return button


func _empty_slot() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(76, 76)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.042, 0.048, 0.58), Color(0.76, 0.8, 0.82, 0.28), 8))
	return panel


func _quick_slot(number: int, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(76, 66)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.042, 0.048, 0.54), Color(0.76, 0.8, 0.82, 0.34), 8))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	box.add_child(_label(text, 12, Color("#d7ded8")))
	var number_label := _label("%d" % number, 12, Color("#10151a"))
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number_label)
	return panel


func _tile_button(text: String, active: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_button_font(button, 12)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.06, 0.068, 0.078, 0.68), Color(0.86, 0.9, 0.9, 0.45 if active else 0.22), 8))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.105, 0.11, 0.84), Color("#d9c579"), 8))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.1, 0.06, 0.9), Color("#e0b75f"), 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.035, 0.04, 0.045, 0.5), Color(0.45, 0.48, 0.48, 0.2), 8))
	return button


func _section(text: String) -> Label:
	var label := _label(text, 15, Color("#d9ded8"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 3)
	return label


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font_ref)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _apply_button_font(button: Button, size: int) -> void:
	button.add_theme_font_override("font", font_ref)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color("#e4e9e3"))
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.74, 0.72, 0.46))


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _slot_name(slot: String) -> String:
	match slot:
		"sight":
			return "조준경"
		"muzzle":
			return "총구"
		"stock":
			return "개머리판"
		"magazine":
			return "탄창"
		"tactical":
			return "보조공구"
		"special":
			return "특수 모듈"
	return slot


func _component_name(component_id: String) -> String:
	match component_id:
		"rubber_gasket":
			return "고무 패킹"
		"scope_lens":
			return "스코프 렌즈"
		"magazine_spring":
			return "탄창 스프링"
	return component_id


func _mod_name(mod_id: String) -> String:
	match mod_id:
		"scope_2x":
			return "폐점포 2x 스코프"
		"muffled_sock":
			return "소리 방지용 양말"
		"sponge_pad":
			return "스펀지 턱받이"
		"quick_mag":
			return "테이프 듀얼 탄창"
		"bell_bait":
			return "딸랑이 방울"
		"ak_precision_receiver":
			return "AK 정밀 단발 리시버"
	return str(WEAPON_SYSTEM.get_mod(mod_id).get("display_name", mod_id))


func _slot_icon(slot: String) -> ImageTexture:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var color := Color("#8fcdb2")
	match slot:
		"sight":
			color = Color("#64d4de")
		"muzzle":
			color = Color("#b8bdae")
		"stock":
			color = Color("#a7d27a")
		"magazine":
			color = Color("#d6c06f")
		"tactical":
			color = Color("#dca65b")
		"special":
			color = Color("#e28b5c")
	for y in range(9, 39):
		for x in range(9, 39):
			var d := Vector2(x - 24, y - 24).length()
			if d < 14.0 and d > 8.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _panel_style(background: Color, border: Color, radius: int, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_top = 7
	style.content_margin_right = 8
	style.content_margin_bottom = 7
	return style
