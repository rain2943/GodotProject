class_name WorkbenchModGraph
extends Control


const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const WEAPON_SYSTEM := preload("res://scripts/weapon_system.gd")

var weapon_id := "ak47"
var installed_mods: Array[String] = []
var slot_names: Dictionary = {}


func setup(next_weapon_id: String, next_mods: Array[String], next_slot_names: Dictionary) -> void:
	weapon_id = next_weapon_id
	installed_mods.assign(next_mods)
	slot_names = next_slot_names.duplicate(true)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.018, 0.025, 0.024, 0.58), true)
	draw_rect(rect, Color("#4f7d6f"), false, 1.2)
	var center := rect.get_center()
	var weapon_rect := Rect2(center - Vector2(92, 38), Vector2(184, 76))
	draw_line(center + Vector2(-76, 0), center + Vector2(76, 0), Color("#d6c285"), 8.0, true)
	draw_line(center + Vector2(-50, -14), center + Vector2(86, -14), Color("#4d5651"), 16.0, true)
	draw_line(center + Vector2(-12, 12), center + Vector2(12, 42), Color("#6c4d35"), 12.0, true)
	draw_rect(weapon_rect, Color("#101716"), false, 1.4)
	_draw_text(center + Vector2(-70, 5), _weapon_short_name(), 16, Color("#efe6c9"))

	var slots := _slot_positions(center)
	for slot in slots:
		var slot_center: Vector2 = slots[slot]
		var installed := _get_mod_in_slot(str(slot))
		var active := not installed.is_empty()
		draw_line(center, slot_center, Color("#6ca990", 0.82 if active else 0.34), 2.0, true)
		draw_circle(slot_center, 31.0, Color(0.03, 0.045, 0.043, 0.95))
		draw_arc(slot_center, 31.0, 0.0, TAU, 40, Color("#9dc8b4") if active else Color("#53645e"), 2.4, true)
		_draw_text(slot_center + Vector2(-36, -7), str(slot_names.get(slot, slot)).substr(0, 9), 12, Color("#dce7dc") if active else Color("#8d9b94"))
		if active:
			_draw_text(slot_center + Vector2(-34, 12), "ON", 11, Color("#f3d36c"))


func _slot_positions(center: Vector2) -> Dictionary:
	return {
		"sight": center + Vector2(0, -122),
		"muzzle": center + Vector2(185, -58),
		"stock": center + Vector2(-185, -58),
		"magazine": center + Vector2(0, 126),
		"tactical": center + Vector2(185, 75),
		"special": center + Vector2(-185, 75),
	}


func _get_mod_in_slot(slot: String) -> String:
	for mod_id in installed_mods:
		var definition := WEAPON_SYSTEM.get_mod(str(mod_id))
		if str(definition.get("slot", "")) == slot:
			return str(mod_id)
	return ""


func _weapon_short_name() -> String:
	var definition := WEAPON_SYSTEM.get_weapon(weapon_id)
	return str(definition.get("display_name", weapon_id)).split(" ")[0]


func _draw_text(position: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(FONT, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
