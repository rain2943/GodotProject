extends Control

var age := 0.0
var duration := 1.45
var strength := 1.0
var sound_kind := "footstep"
var wave_color := Color(0.72, 0.82, 0.78, 0.34)
var max_radius := 72.0
var ring_count := 3


func configure(kind: String, wave_strength: float) -> void:
	sound_kind = kind
	strength = clampf(wave_strength, 0.4, 1.8)
	match kind:
		"player_gunshot":
			duration = 2.05
			max_radius = 680.0
			ring_count = 1
			wave_color = Color(1.0, 0.72, 0.38, 0.19)
		"enemy_gunshot":
			duration = 1.65
			max_radius = 300.0
			ring_count = 1
			wave_color = Color(1.0, 0.48, 0.38, 0.17)
		"heavy_step":
			duration = 1.35
			max_radius = 76.0
			ring_count = 3
			wave_color = Color(0.9, 0.72, 0.43, 0.24)
		_:
			duration = 1.2
			max_radius = 62.0
			ring_count = 3
			wave_color = Color(0.58, 0.78, 0.72, 0.22)


func _ready() -> void:
	var diameter := (max_radius * strength + 18.0) * 2.0
	size = Vector2(diameter, diameter)
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
	var ring_duration := 1.0 / float(maxi(1, ring_count))
	for ring_index in range(ring_count):
		var ring_start := float(ring_index) * ring_duration
		if progress < ring_start or progress >= ring_start + ring_duration:
			continue
		var ring_progress := clampf((progress - ring_start) / ring_duration, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - ring_progress, 2.15)
		var radius := lerpf(7.0, max_radius * strength, eased_progress)
		var envelope := sin(ring_progress * PI)
		var alpha := wave_color.a * envelope
		var glow_color := Color(wave_color.r, wave_color.g, wave_color.b, alpha * 0.24)
		var line_color := Color(wave_color.r, wave_color.g, wave_color.b, alpha)
		draw_arc(center, radius, 0.0, TAU, 96, glow_color, 7.0, true)
		draw_arc(center, radius, 0.0, TAU, 96, line_color, 1.6, true)
