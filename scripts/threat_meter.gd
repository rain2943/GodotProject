extends Control

const THREAT_ICON := preload("res://assets/ui/threat_megaphone.png")
const UI_FONT := preload("res://assets/fonts/Pretendard-Regular.otf")

var bars: Array[ProgressBar] = []
var icon: TextureRect
var title_label: Label


func _ready() -> void:
	name = "ThreatMeter"
	position = Vector2(24, 196)
	size = Vector2(238, 68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	set_threat(0.0)


func _build_ui() -> void:
	var background := Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.018, 0.024, 0.026, 0.9)
	background_style.border_color = Color(0.31, 0.34, 0.33, 0.86)
	background_style.set_border_width_all(1)
	background_style.set_corner_radius_all(5)
	background.add_theme_stylebox_override("panel", background_style)
	add_child(background)

	icon = TextureRect.new()
	icon.name = "MegaphoneIcon"
	icon.texture = THREAT_ICON
	icon.position = Vector2(8, 7)
	icon.size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	title_label = Label.new()
	title_label.position = Vector2(68, 7)
	title_label.size = Vector2(158, 22)
	title_label.text = "소란도 0 / 3"
	title_label.add_theme_font_override("font", UI_FONT)
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("#c9ceca"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)

	for index in 3:
		var bar := ProgressBar.new()
		bar.name = "ThreatCell%d" % (index + 1)
		bar.position = Vector2(68 + index * 51, 35)
		bar.size = Vector2(44, 17)
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var background_box := StyleBoxFlat.new()
		background_box.bg_color = Color(0.09, 0.105, 0.105, 0.96)
		background_box.border_color = Color(0.31, 0.33, 0.32, 0.94)
		background_box.set_border_width_all(1)
		background_box.set_corner_radius_all(3)
		var fill_box := StyleBoxFlat.new()
		fill_box.bg_color = [Color("#d7b253"), Color("#df7b38"), Color("#d9342d")][index]
		fill_box.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", background_box)
		bar.add_theme_stylebox_override("fill", fill_box)
		add_child(bar)
		bars.append(bar)


func set_threat(value: float) -> void:
	var threat := clampf(value, 0.0, 3.0)
	for index in bars.size():
		bars[index].value = clampf(threat - float(index), 0.0, 1.0) * 100.0
	var pulse := 1.0 + 0.05 * sin(Time.get_ticks_msec() * 0.012) if threat >= 2.0 else 1.0
	icon.scale = Vector2.ONE * pulse
	icon.pivot_offset = icon.size * 0.5
	icon.modulate = Color.WHITE.lerp(Color("#ff7563"), threat / 3.0)
	title_label.text = "소란도 %d / 3" % floori(threat + 0.001)
