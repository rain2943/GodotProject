extends Control


var cooldown_progress := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(18, 18)
	size = Vector2(18, 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	queue_redraw()


func set_cooldown_progress(value: float, is_active: bool) -> void:
	cooldown_progress = clampf(value, 0.0, 1.0)
	visible = is_active
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 8.0, Color(0.025, 0.03, 0.032, 0.78))
	draw_arc(center, 6.2, 0.0, TAU, 32, Color(0.42, 0.45, 0.45, 0.42), 2.2, true)
	if cooldown_progress > 0.001:
		draw_arc(
			center,
			6.2,
			-PI * 0.5,
			-PI * 0.5 + TAU * cooldown_progress,
			32,
			Color(0.86, 0.88, 0.86, 0.96),
			2.4,
			true
		)
	draw_circle(center, 1.25, Color(0.7, 0.73, 0.72, 0.82))
