class_name ModChipButton
extends Button

var mod_id := ""
var slot_name := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or mod_id.is_empty():
		return null
	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.045, 0.04, 0.96)
	style.border_color = Color("#86c6a6")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_top = 7
	style.content_margin_right = 10
	style.content_margin_bottom = 7
	preview.add_theme_stylebox_override("panel", style)
	var preview_label := Label.new()
	preview_label.text = text.get_slice("\n", 0)
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_color_override("font_color", Color("#f1e4b5"))
	preview.add_child(preview_label)
	set_drag_preview(preview)
	return {"kind": "weapon_mod", "mod_id": mod_id, "slot": slot_name}
