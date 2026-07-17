class_name AimReticle
extends Control

var aim_position := Vector2.ZERO
var spread_radius := 10.0
var recoil_offset := Vector2.ZERO
var laser_active := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_feedback(position: Vector2, spread_degrees: float, recoil: Vector2, is_laser_active: bool) -> void:
	aim_position = position
	spread_radius = clampf(8.0 + spread_degrees * 4.2, 8.0, 68.0)
	recoil_offset = recoil
	laser_active = is_laser_active
	queue_redraw()


func _draw() -> void:
	var center := aim_position + recoil_offset
	var color := Color(1.0, 0.24, 0.16, 0.92) if laser_active else Color(0.88, 0.82, 0.62, 0.9)
	var soft_color := Color(color.r, color.g, color.b, 0.34)
	draw_arc(center, spread_radius, 0.0, TAU, 40, soft_color, 1.5, true)
	var tick_length := 7.0
	var gap := spread_radius + 3.0
	draw_line(center + Vector2(-gap - tick_length, 0), center + Vector2(-gap, 0), color, 2.0, true)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + tick_length, 0), color, 2.0, true)
	draw_line(center + Vector2(0, -gap - tick_length), center + Vector2(0, -gap), color, 2.0, true)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + tick_length), color, 2.0, true)
	draw_circle(center, 2.0, color)
