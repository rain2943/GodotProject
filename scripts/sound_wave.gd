extends Control

var age := 0.0
var duration := 1.35
var strength := 1.0
var sound_kind := "footstep"
var dot_color := Color(0.78, 0.82, 0.76, 0.9)


func configure(kind: String, wave_strength: float) -> void:
	sound_kind = kind
	strength = clampf(wave_strength, 0.45, 1.5)
	duration = 1.1 if kind == "light_step" else 1.45
	dot_color = Color(0.72, 0.86, 0.8, 0.96) if kind == "light_step" else Color(0.98, 0.78, 0.42, 1.0)


func _ready() -> void:
	size = Vector2(220, 220)
	pivot_offset = size * 0.5
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(age / duration, 0.0, 1.0)
	var center := size * 0.5
	var pulse := sin(progress * PI)
	var base_alpha := pulse * (1.0 - progress * 0.35)
	var ring_count := 4 if strength >= 0.9 else 3
	var dot_count := 22 if strength >= 0.9 else 16
	for ring_index in range(ring_count):
		var ring_delay := float(ring_index) * 0.12
		var ring_progress := clampf((progress - ring_delay) / maxf(0.01, 1.0 - ring_delay), 0.0, 1.0)
		if ring_progress <= 0.0:
			continue
		var radius := lerpf(10.0, 78.0 * strength, ring_progress)
		var alpha := base_alpha * (1.0 - float(ring_index) * 0.2)
		for dot_index in range(dot_count):
			if (dot_index + ring_index * 2) % 5 == 0:
				continue
			var angle := TAU * float(dot_index) / float(dot_count)
			var roughness := sin(float(dot_index * 17 + ring_index * 31)) * 3.8
			var point := center + Vector2(cos(angle), sin(angle)) * (radius + roughness)
			var radius_dot := 1.5 + strength * 0.8 + sin(float(dot_index * 7)) * 0.3
			draw_circle(point, radius_dot, Color(dot_color, alpha))
