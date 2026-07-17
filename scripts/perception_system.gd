class_name PerceptionSystem
extends CanvasLayer

const MAX_OCCLUDERS := 24
const FOV_HALF_ANGLE_DEGREES := 58.0
const VISION_WORLD_RANGE := 11.5
const SOUND_HEARING_RANGE := 48.0
const SOUND_WAVE_SCRIPT := preload("res://scripts/sound_wave.gd")

var player: CharacterBody3D
var camera: Camera3D
var fog_rect: ColorRect
var fog_material: ShaderMaterial
var aim_world_direction := Vector3(1, 0, 1).normalized()
var vision_world_range := VISION_WORLD_RANGE
var aim_expanded := false
var sound_timers := {}
var sound_waves: Array[Control] = []
var last_player_combat_sound_msec := -10000
var enemy_gunshot_timers := {}


func setup(player_body: CharacterBody3D, active_camera: Camera3D) -> void:
	player = player_body
	camera = active_camera


func _ready() -> void:
	name = "PerceptionSystem"
	layer = 2
	add_to_group("perception_system")


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	# Enemy sounds remain simulation-only. Only player gunfire gets a visible wave.
	_update_sound_waves()


func set_aim_direction(world_direction: Vector3) -> void:
	world_direction.y = 0.0
	if world_direction.length_squared() > 0.01:
		aim_world_direction = world_direction.normalized()


func set_vision_range(world_range: float) -> void:
	vision_world_range = maxf(2.0, world_range)


func set_aim_expanded(value: bool) -> void:
	aim_expanded = value


func report_sound(world_position: Vector3, sound_kind: String, strength: float = 1.0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	if player.global_position.distance_to(world_position) > SOUND_HEARING_RANGE:
		return
	if _position_is_visible(world_position):
		return
	_spawn_sound_wave(world_position, sound_kind, strength)


func emit_player_gunshot(world_position: Vector3, hearing_radius: float = 52.0) -> void:
	var now := Time.get_ticks_msec()
	# Keep one readable pulse on screen at a time while automatic fire continues.
	if now - last_player_combat_sound_msec < 1850:
		return
	last_player_combat_sound_msec = now
	_spawn_sound_wave(world_position, "player_gunshot", 1.0)
	_propagate_sound_to_enemies(world_position, hearing_radius)


func emit_enemy_gunshot(enemy: Node3D) -> void:
	pass


func _propagate_sound_to_enemies(world_position: Vector3, hearing_radius: float) -> void:
	for node in get_tree().get_nodes_in_group("sound_source"):
		if not (node is CharacterBody3D) or not node.has_method("hear_sound"):
			continue
		var enemy := node as CharacterBody3D
		var distance := enemy.global_position.distance_to(world_position)
		if distance > hearing_radius:
			continue
		var effective_radius := hearing_radius
		var query := PhysicsRayQueryParameters3D.create(
			world_position + Vector3(0, 0.35, 0),
			enemy.global_position + Vector3(0, 0.35, 0),
			1
		)
		if is_instance_valid(player):
			query.exclude = [player.get_rid()]
		if not player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			effective_radius *= 0.68
		if distance > effective_radius:
			continue
		var loudness := clampf(1.0 - distance / maxf(effective_radius, 0.1), 0.25, 1.0)
		var travel_delay := distance / 38.0
		var hearing_enemy := enemy
		get_tree().create_timer(travel_delay).timeout.connect(func() -> void:
			if is_instance_valid(hearing_enemy):
				hearing_enemy.call("hear_sound", world_position, loudness)
		)


func _build_fog() -> void:
	fog_rect = ColorRect.new()
	fog_rect.name = "DirectionalFog"
	fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog_rect)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

const int MAX_OCCLUDERS = 24;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 player_uv = vec2(0.5, 0.5);
uniform vec2 aim_screen_direction = vec2(0.0, -1.0);
uniform vec4 occluders[MAX_OCCLUDERS];
uniform int occluder_count = 0;
uniform float fov_half_angle = 58.0;
uniform float vision_radius = 470.0;
uniform float darkness = 0.92;
uniform float aim_expanded = 0.0;

float cross_2d(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

bool segment_blocks(vec2 origin, vec2 target, vec2 edge_a, vec2 edge_b) {
	vec2 ray = target - origin;
	vec2 edge = edge_b - edge_a;
	float denominator = cross_2d(ray, edge);
	if (abs(denominator) < 0.000001) {
		return false;
	}
	float ray_time = cross_2d(edge_a - origin, edge) / denominator;
	float edge_time = cross_2d(edge_a - origin, ray) / denominator;
	return ray_time > 0.015 && ray_time < 0.985 && edge_time >= 0.0 && edge_time <= 1.0;
}

void fragment() {
	vec2 pixel_delta = (UV - player_uv) * viewport_size;
	float distance_px = length(pixel_delta);
	vec2 view_direction = distance_px > 0.001 ? normalize(pixel_delta) : aim_screen_direction;
	float cone_limit = cos(radians(fov_half_angle));
	float alignment = dot(view_direction, normalize(aim_screen_direction));
	float cone_visibility = smoothstep(cone_limit - 0.08, cone_limit + 0.035, alignment);
	float range_visibility = 1.0 - smoothstep(vision_radius - 95.0, vision_radius, distance_px);
	float awareness = 1.0 - smoothstep(78.0, 155.0, distance_px);
	float visibility = mix(awareness, max(awareness, cone_visibility * range_visibility), aim_expanded);
	float blocked = 0.0;
	for (int index = 0; index < MAX_OCCLUDERS; index++) {
		if (index < occluder_count) {
			vec4 segment = occluders[index];
			if (segment_blocks(player_uv, UV, segment.xy, segment.zw)) {
				blocked = 1.0;
			}
		}
	}
	if (blocked > 0.5 && distance_px > 62.0) {
		visibility *= 0.035;
	}
	float fog_alpha = mix(darkness, 0.025, visibility);
	COLOR = vec4(0.006, 0.009, 0.012, fog_alpha);
}
"""
	fog_material = ShaderMaterial.new()
	fog_material.shader = shader
	fog_rect.material = fog_material


func _update_fog() -> void:
	if fog_material == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var player_screen := camera.unproject_position(player.global_position + Vector3(0, 0.22, 0))
	var aim_screen_point := camera.unproject_position(player.global_position + aim_world_direction * 2.0 + Vector3(0, 0.22, 0))
	var screen_aim := aim_screen_point - player_screen
	if screen_aim.length_squared() <= 0.01:
		screen_aim = Vector2.UP
	screen_aim = screen_aim.normalized()
	fog_material.set_shader_parameter("viewport_size", viewport_size)
	fog_material.set_shader_parameter("player_uv", player_screen / viewport_size)
	fog_material.set_shader_parameter("aim_screen_direction", screen_aim)
	fog_material.set_shader_parameter("aim_expanded", 1.0 if aim_expanded else 0.0)
	var segments := PackedVector4Array()
	segments.resize(MAX_OCCLUDERS)
	var occluders := _collect_nearby_occluders()
	var count := mini(occluders.size(), MAX_OCCLUDERS)
	for index in range(count):
		segments[index] = _occluder_screen_segment(occluders[index], viewport_size)
	fog_material.set_shader_parameter("occluders", segments)
	fog_material.set_shader_parameter("occluder_count", count)


func _collect_nearby_occluders() -> Array[Node3D]:
	var unique := {}
	for group_name in ["vision_occluder", "camera_occluder", "vehicle_obstacle"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is Node3D:
				unique[node.get_instance_id()] = node
	var result: Array[Node3D] = []
	for node in unique.values():
		var body := node as Node3D
		if is_instance_valid(body) and player.global_position.distance_squared_to(body.global_position) <= 625.0:
			result.append(body)
	result.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position)
	)
	return result


func _occluder_screen_segment(body: Node3D, viewport_size: Vector2) -> Vector4:
	var collision := _find_box_collision(body)
	if collision == null or not (collision.shape is BoxShape3D):
		var center := camera.unproject_position(body.global_position) / viewport_size
		return Vector4(center.x - 0.015, center.y, center.x + 0.015, center.y)
	var box := collision.shape as BoxShape3D
	var half := box.size * 0.5
	var local_player := collision.to_local(player.global_position)
	var point_a := Vector3.ZERO
	var point_b := Vector3.ZERO
	var ground_y := -half.y + minf(0.3, box.size.y * 0.35)
	if absf(local_player.x) > absf(local_player.z):
		var edge_x := half.x * signf(local_player.x)
		point_a = Vector3(edge_x, ground_y, -half.z)
		point_b = Vector3(edge_x, ground_y, half.z)
	else:
		var edge_z := half.z * signf(local_player.z)
		point_a = Vector3(-half.x, ground_y, edge_z)
		point_b = Vector3(half.x, ground_y, edge_z)
	var screen_a := camera.unproject_position(collision.to_global(point_a)) / viewport_size
	var screen_b := camera.unproject_position(collision.to_global(point_b)) / viewport_size
	return Vector4(screen_a.x, screen_a.y, screen_b.x, screen_b.y)


func _find_box_collision(body: Node3D) -> CollisionShape3D:
	for child in body.find_children("*", "CollisionShape3D", true, false):
		var collision := child as CollisionShape3D
		if collision and collision.shape is BoxShape3D:
			return collision
	return null


func _update_sound_sources(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("sound_source"):
		if not (node is CharacterBody3D):
			continue
		var source := node as CharacterBody3D
		var source_id := source.get_instance_id()
		var timer := float(sound_timers.get(source_id, 0.15)) - delta
		var moving := source.velocity.length_squared() > 0.3
		var distance := player.global_position.distance_to(source.global_position)
		if moving and distance <= SOUND_HEARING_RANGE and not _position_is_visible(source.global_position):
			if timer <= 0.0:
				var kind := str(source.get("enemy_kind"))
				var heavy := kind == "melee"
				_spawn_sound_wave(source.global_position, "heavy_step" if heavy else "light_step", 1.0 if heavy else 0.72)
				timer = 0.46 if heavy else 0.72
		else:
			timer = minf(timer, 0.18)
		sound_timers[source_id] = timer


func _position_is_visible(world_position: Vector3) -> bool:
	var offset := world_position - player.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= 2.2:
		return true
	if distance > vision_world_range or offset.length_squared() <= 0.01:
		return false
	var from := player.global_position + Vector3(0, 0.38, 0)
	var to := world_position + Vector3(0, 0.38, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _spawn_sound_wave(world_position: Vector3, sound_kind: String, strength: float) -> void:
	if sound_kind != "player_gunshot":
		return
	_prune_sound_waves()
	if not sound_waves.is_empty():
		var active_wave := sound_waves[0]
		if sound_kind != "player_gunshot" or active_wave.get_meta("sound_kind", "") == "player_gunshot":
			return
		for existing_wave in sound_waves:
			if is_instance_valid(existing_wave):
				existing_wave.queue_free()
		sound_waves.clear()
	var wave := SOUND_WAVE_SCRIPT.new() as Control
	wave.call("configure", sound_kind, strength)
	wave.set_meta("sound_world_position", world_position)
	wave.set_meta("sound_kind", sound_kind)
	add_child(wave)
	sound_waves.append(wave)
	_position_wave(wave)


func _update_sound_waves() -> void:
	_prune_sound_waves()
	for wave in sound_waves:
		_position_wave(wave)


func _prune_sound_waves() -> void:
	for index in range(sound_waves.size() - 1, -1, -1):
		var wave := sound_waves[index]
		if not is_instance_valid(wave):
			sound_waves.remove_at(index)


func _position_wave(wave: Control) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var world_position: Vector3 = wave.get_meta("sound_world_position", player.global_position)
	var screen_position := camera.unproject_position(world_position + Vector3(0, 0.25, 0))
	screen_position.x = clampf(screen_position.x, 46.0, viewport_size.x - 46.0)
	screen_position.y = clampf(screen_position.y, 46.0, viewport_size.y - 46.0)
	wave.position = screen_position - wave.size * 0.5
