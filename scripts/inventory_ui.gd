extends Control

signal open_state_changed(is_open: bool)

var modal: Control
var open_button: Button
var weapon_name_label: Label
var weapon_ammo_label: Label
var ammo_slot_label: Label
var capacity_label: Label
var opened := false


func setup(font: Font, weapon_texture: Texture2D, ammo_texture: Texture2D) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	open_button = Button.new()
	open_button.name = "InventoryButton"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.offset_left = -96
	open_button.offset_top = 112
	open_button.offset_right = -22
	open_button.offset_bottom = 154
	open_button.text = "가방"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.add_theme_font_override("font", font)
	open_button.add_theme_font_size_override("font_size", 14)
	open_button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.032, 0.031, 0.94), Color("#718477"), 4))
	open_button.add_theme_stylebox_override("hover", _panel_style(Color(0.055, 0.07, 0.064, 0.97), Color("#a3b09d"), 4))
	open_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.11, 0.095, 0.055, 0.98), Color("#c4aa68"), 4))
	open_button.pressed.connect(toggle)
	add_child(open_button)

	modal = Control.new()
	modal.name = "InventoryModal"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.008, 0.008, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -245
	panel.offset_right = 350
	panel.offset_bottom = 245
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.022, 0.028, 0.027, 0.985), Color("#748277"), 6, 2))
	modal.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	var title := Label.new()
	title.text = "생존 가방"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#d7dbd3"))
	header.add_child(title)
	capacity_label = Label.new()
	capacity_label.text = "사용  4 / 16"
	capacity_label.add_theme_font_override("font", font)
	capacity_label.add_theme_font_size_override("font_size", 14)
	capacity_label.add_theme_color_override("font_color", Color("#bca96c"))
	capacity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(capacity_label)
	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(38, 34)
	close_button.text = "×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", font)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_stylebox_override("normal", _panel_style(Color(0.09, 0.045, 0.035, 0.9), Color("#8d604a"), 3))
	close_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.22, 0.07, 0.04, 0.96), Color("#d18b61"), 3))
	close_button.pressed.connect(func() -> void: set_open(false))
	header.add_child(close_button)

	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 1)
	content.add_child(separator)

	var equipment := PanelContainer.new()
	equipment.custom_minimum_size = Vector2(0, 112)
	equipment.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.052, 0.048, 0.96), Color("#53665a"), 4))
	content.add_child(equipment)
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 16)
	equipment.add_child(equipment_row)
	var weapon_icon := TextureRect.new()
	weapon_icon.custom_minimum_size = Vector2(118, 92)
	weapon_icon.texture = weapon_texture
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipment_row.add_child(weapon_icon)
	var weapon_info := VBoxContainer.new()
	weapon_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_info.alignment = BoxContainer.ALIGNMENT_CENTER
	equipment_row.add_child(weapon_info)
	var category := Label.new()
	category.text = "주무기"
	category.add_theme_font_override("font", font)
	category.add_theme_font_size_override("font_size", 12)
	category.add_theme_color_override("font_color", Color("#8fa092"))
	weapon_info.add_child(category)
	weapon_name_label = Label.new()
	weapon_name_label.text = "미장착"
	weapon_name_label.add_theme_font_override("font", font)
	weapon_name_label.add_theme_font_size_override("font_size", 20)
	weapon_name_label.add_theme_color_override("font_color", Color("#e2e3dd"))
	weapon_info.add_child(weapon_name_label)
	weapon_ammo_label = Label.new()
	weapon_ammo_label.custom_minimum_size = Vector2(195, 0)
	weapon_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_ammo_label.add_theme_font_override("font", font)
	weapon_ammo_label.add_theme_font_size_override("font_size", 16)
	weapon_ammo_label.add_theme_color_override("font_color", Color("#d2bd76"))
	equipment_row.add_child(weapon_ammo_label)

	var section_title := Label.new()
	section_title.text = "소지품"
	section_title.add_theme_font_override("font", font)
	section_title.add_theme_font_size_override("font_size", 15)
	section_title.add_theme_color_override("font_color", Color("#aeb8ae"))
	content.add_child(section_title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	content.add_child(grid)
	ammo_slot_label = _add_item_slot(grid, font, ammo_texture, "7.62mm 탄약", "x0", Color("#bca96c"))
	_add_item_slot(grid, font, null, "생수", "x2", Color("#668f9b"), "물")
	_add_item_slot(grid, font, null, "붕대", "x3", Color("#a8aaa0"), "+")
	_add_item_slot(grid, font, null, "통조림", "x1", Color("#8b7657"), "캔")
	for index in 4:
		_add_item_slot(grid, font, null, "빈 슬롯", "", Color("#39423d"), "")
	set_open(false)


func _add_item_slot(
	grid: GridContainer,
	font: Font,
	texture: Texture2D,
	item_name: String,
	count_text: String,
	accent: Color,
	fallback_icon: String = ""
) -> Label:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(153, 104)
	slot.add_theme_stylebox_override("panel", _panel_style(Color(0.032, 0.04, 0.038, 0.96), Color(accent.r, accent.g, accent.b, 0.62), 4))
	grid.add_child(slot)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(box)
	if texture:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 48)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
	else:
		var icon_label := Label.new()
		icon_label.custom_minimum_size = Vector2(0, 48)
		icon_label.text = fallback_icon
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_override("font", font)
		icon_label.add_theme_font_size_override("font_size", 20)
		icon_label.add_theme_color_override("font_color", accent)
		box.add_child(icon_label)
	var name_label := Label.new()
	name_label.text = item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color("#bdc4bc") if item_name != "빈 슬롯" else Color("#59615c"))
	box.add_child(name_label)
	var count_label := Label.new()
	count_label.text = count_text
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_override("font", font)
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", accent)
	box.add_child(count_label)
	return count_label


func update_state(has_weapon: bool, magazine: int, reserve: int) -> void:
	var total := magazine + reserve
	weapon_name_label.text = "AK-47" if has_weapon else "미장착"
	weapon_ammo_label.text = "탄창  %02d / 30\n예비  %03d\n총 탄약  %03d" % [magazine, reserve, total]
	ammo_slot_label.text = "x%d" % reserve
	capacity_label.text = "사용  %d / 16" % (4 if has_weapon else 3)


func toggle() -> void:
	set_open(not opened)


func set_open(value: bool) -> void:
	opened = value
	modal.visible = opened
	open_button.visible = not opened
	open_state_changed.emit(opened)


func is_open() -> bool:
	return opened


func _panel_style(background: Color, border: Color, radius: int, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_top = 7
	style.content_margin_right = 10
	style.content_margin_bottom = 7
	return style
