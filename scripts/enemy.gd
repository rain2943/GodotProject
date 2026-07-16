extends CharacterBody3D

signal died(enemy: CharacterBody3D)

const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const MELEE_SPEED := 3.1
const PISTOL_SPEED := 2.5
const PATROL_SPEED := 1.35
const PATROL_RADIUS := 6.5
const FRAME_SIZE := Vector2(384, 384)
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const SPRITE_BASE_POSITION := Vector3(0, 0.25, 0)
const MELEE_WINDUP_TIME := 0.46
const MELEE_STRIKE_TIME := 0.16
const MELEE_RECOVERY_TIME := 0.34
const HIT_STAGGER_TIME := 0.13

var enemy_kind := "melee"
var target: CharacterBody3D
var animation_sheets := {}
var health := 55
var attack_cooldown := 0.0
var sprite: AnimatedSprite3D
var shadow: MeshInstance3D
var threat_marker: Label3D
var motion_state := "idle"
var facing := "s"
var combat_state := "normal"
var state_timer := 0.0
var pending_attack_direction := Vector3.ZERO
var stagger_velocity := Vector3.ZERO
var dying := false
var visual_tween: Tween
var patrol_origin := Vector3.ZERO
var patrol_target := Vector3.ZERO
var patrol_pause := 0.0
var patrol_repath_time := 0.0
var threat_level := 0.0
var alerted := false
var alert_marker_time := 0.0
var pursuit_time := 0.0
var last_known_position := Vector3.ZERO
var visual_contact_confirmed := false
var burst_shots_remaining := 0
var strafe_sign := 1.0
var strafe_switch_time := 0.0
var facing_world_direction := Vector3(1.0, 0.0, 1.0).normalized()
var backstab_stunned := false


func configure(kind: String, target_body: CharacterBody3D, sheets: Dictionary, initial_threat: float = 0.0) -> void:
	enemy_kind = kind
	target = target_body
	animation_sheets = sheets
	threat_level = clampf(initial_threat, 0.0, 1.0)
	var base_health := 70 if enemy_kind == "melee" else 50
	health = base_health + roundi(35.0 * threat_level)


func set_threat_level(value: float) -> void:
	threat_level = clampf(value, 0.0, 1.0)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 3

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.3
	collision.shape = shape
	add_child(collision)

	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0, 0, 0, 0.34)
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.46
	shadow_mesh.bottom_radius = 0.46
	shadow_mesh.height = 0.015
	shadow_mesh.radial_segments = 20
	shadow_mesh.material = shadow_material
	shadow = MeshInstance3D.new()
	shadow.name = "Shadow"
	shadow.position.y = -0.7
	shadow.mesh = shadow_mesh
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

	sprite = AnimatedSprite3D.new()
	sprite.name = "EnemySprite"
	sprite.sprite_frames = _create_sprite_frames()
	sprite.position = SPRITE_BASE_POSITION
	sprite.pixel_size = 0.0068
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.no_depth_test = true
	sprite.render_priority = 30
	add_child(sprite)

	threat_marker = Label3D.new()
	threat_marker.name = "ThreatMarker"
	threat_marker.text = "!"
	threat_marker.position = Vector3(0, 1.62, 0)
	threat_marker.font_size = 72
	threat_marker.outline_size = 18
	threat_marker.modulate = Color("#ff4d3d")
	threat_marker.outline_modulate = Color(0.12, 0.008, 0.004, 1.0)
	threat_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	threat_marker.no_depth_test = true
	threat_marker.render_priority = 120
	threat_marker.visible = false
	add_child(threat_marker)
	patrol_origin = global_position
	_choose_patrol_target()
	_play_animation()


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	_update_alert_marker(delta)
	if dying:
		velocity = velocity.move_toward(Vector3.ZERO, 7.0 * delta)
		move_and_slide()
		return
	if backstab_stunned:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if combat_state == "stagger":
		_update_stagger(delta)
		return
	if combat_state != "normal":
		_update_combat_state(delta)
		return
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		_set_motion_state("idle")
		return
	if _target_is_in_safe_zone():
		combat_state = "normal"
		_clear_alert()
		_update_patrol(delta)
		move_and_slide()
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var base_vision_range := 9.5 if enemy_kind == "melee" else 13.0
	var vision_range := base_vision_range + lerpf(0.0, 5.5, threat_level)
	var can_see_target := distance <= vision_range and _has_line_of_sight()
	if can_see_target:
		last_known_position = target.global_position
		pursuit_time = lerpf(4.5, 12.0, threat_level)
		if not visual_contact_confirmed:
			_become_alerted()
	elif alerted and pursuit_time > 0.0:
		pursuit_time = maxf(0.0, pursuit_time - delta)
		_pursue_last_known_position()
		move_and_slide()
		return
	else:
		_clear_alert()
		_update_patrol(delta)
		move_and_slide()
		return

	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	_set_facing_from_world_direction(direction)
	if enemy_kind == "melee":
		_update_melee(direction, distance)
	else:
		_update_pistol(direction, distance, delta)
	if combat_state == "normal":
		_set_motion_state("walk" if velocity.length_squared() > 0.05 else "idle")
	move_and_slide()


func _update_patrol(delta: float) -> void:
	patrol_pause = maxf(0.0, patrol_pause - delta)
	patrol_repath_time = maxf(0.0, patrol_repath_time - delta)
	if patrol_pause > 0.0:
		velocity = velocity.move_toward(Vector3.ZERO, 8.0 * delta)
		_set_motion_state("idle")
		return

	var offset := patrol_target - global_position
	offset.y = 0.0
	if offset.length() <= 0.65 or patrol_repath_time <= 0.0 or is_on_wall():
		velocity = Vector3.ZERO
		patrol_pause = randf_range(0.25, 0.75)
		_choose_patrol_target()
		_set_motion_state("idle")
		return

	var direction := offset.normalized()
	velocity = direction * PATROL_SPEED
	_set_facing_from_world_direction(direction)
	_set_motion_state("walk")


func _choose_patrol_target() -> void:
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(PATROL_RADIUS * 0.35, PATROL_RADIUS)
	patrol_target = patrol_origin + Vector3(cos(angle), 0.0, sin(angle)) * radius
	patrol_repath_time = randf_range(2.0, 4.5)


func _become_alerted() -> void:
	alerted = true
	visual_contact_confirmed = true
	alert_marker_time = 1.25
	threat_marker.text = "!"
	threat_marker.modulate = Color("#ff4d3d")
	threat_marker.visible = true
	threat_marker.scale = Vector3.ONE * 1.45


func hear_sound(world_position: Vector3, loudness: float = 1.0) -> void:
	if dying or not is_instance_valid(target) or _target_is_in_safe_zone():
		return
	last_known_position = world_position
	pursuit_time = maxf(pursuit_time, lerpf(5.5, 12.0, threat_level) * clampf(loudness, 0.35, 1.0))
	alerted = true
	if not visual_contact_confirmed:
		alert_marker_time = 0.9
		threat_marker.text = "?"
		threat_marker.modulate = Color("#f3c65b")
		threat_marker.visible = true


func _clear_alert() -> void:
	alerted = false
	visual_contact_confirmed = false
	pursuit_time = 0.0
	if combat_state != "melee_windup":
		threat_marker.visible = false


func _update_alert_marker(delta: float) -> void:
	if alert_marker_time > 0.0:
		alert_marker_time = maxf(0.0, alert_marker_time - delta)
		threat_marker.visible = true
		_update_threat_marker()
	elif combat_state != "melee_windup":
		threat_marker.visible = false


func _pursue_last_known_position() -> void:
	var offset := last_known_position - global_position
	offset.y = 0.0
	if offset.length() <= 0.7:
		velocity = Vector3.ZERO
		_set_motion_state("idle")
		return
	var direction := offset.normalized()
	if is_on_wall():
		direction = Vector3(-direction.z, 0.0, direction.x) * strafe_sign
		strafe_sign *= -1.0
	var base_speed := MELEE_SPEED if enemy_kind == "melee" else PISTOL_SPEED
	velocity = direction * base_speed * lerpf(1.0, 1.32, threat_level)
	_set_facing_from_world_direction(direction)
	_set_motion_state("walk")


func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in animation_sheets:
		_add_sheet_animation(frames, direction_name, "idle", range(0, 8), 7.0, true)
		_add_sheet_animation(frames, direction_name, "walk", range(8, 16), 8.5, true)
		_add_sheet_animation(frames, direction_name, "attack", [8, 10, 12, 14, 13, 11, 9, 8], 15.0, false)
		_add_sheet_animation(frames, direction_name, "hit", [3, 2, 3], 18.0, false)
		_add_sheet_animation(frames, direction_name, "death", [5, 6, 7], 7.0, false)
	return frames


func _add_sheet_animation(
	frames: SpriteFrames,
	direction_name: String,
	state: String,
	frame_indices,
	speed: float,
	looped: bool
) -> void:
	var animation_name := "%s_%s" % [state, direction_name]
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looped)
	frames.set_animation_speed(animation_name, speed)
	for frame_index in frame_indices:
		var atlas := AtlasTexture.new()
		atlas.atlas = animation_sheets[direction_name]
		atlas.region = Rect2(
			(int(frame_index) % 4) * FRAME_SIZE.x,
			(int(frame_index) / 4) * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		frames.add_frame(animation_name, atlas)


func _set_motion_state(next_state: String) -> void:
	if motion_state == next_state:
		return
	motion_state = next_state
	_play_animation()


func _set_facing(direction_name: String) -> void:
	if facing == direction_name:
		return
	facing = direction_name
	_play_animation()


func _set_facing_from_world_direction(world_direction: Vector3) -> void:
	if world_direction.length_squared() <= 0.01:
		return
	facing_world_direction = world_direction.normalized()
	var screen_direction := Vector2(
		world_direction.x - world_direction.z,
		world_direction.x + world_direction.z
	).normalized()
	var angle := fposmod(rad_to_deg(atan2(screen_direction.x, -screen_direction.y)), 360.0)
	var index := int(round(angle / 45.0)) % 8
	_set_facing(SCREEN_DIRECTION_NAMES[index])


func _play_animation() -> void:
	if sprite == null:
		return
	var source := facing
	var flipped := false
	match facing:
		"sw": source = "se"; flipped = true
		"w": source = "e"; flipped = true
		"nw": source = "ne"; flipped = true
	sprite.flip_h = flipped
	var animation_name := "%s_%s" % [motion_state, source]
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _update_melee(direction: Vector3, distance: float) -> void:
	if distance > 1.4:
		velocity = direction * MELEE_SPEED * lerpf(1.0, 1.36, threat_level)
	elif attack_cooldown <= 0.0:
		_start_melee_windup(direction)
	else:
		velocity = Vector3.ZERO


func _start_melee_windup(direction: Vector3) -> void:
	combat_state = "melee_windup"
	state_timer = MELEE_WINDUP_TIME
	pending_attack_direction = direction
	attack_cooldown = lerpf(1.2, 0.82, threat_level)
	velocity = Vector3.ZERO
	_set_motion_state("attack")
	threat_marker.visible = true
	_start_windup_pose()


func _update_pistol(direction: Vector3, distance: float, delta: float) -> void:
	var movement_speed := PISTOL_SPEED * lerpf(1.12, 1.48, threat_level)
	strafe_switch_time = maxf(0.0, strafe_switch_time - delta)
	if distance > 10.5:
		velocity = direction * movement_speed
	elif distance < 5.2:
		velocity = -direction * movement_speed
	else:
		if strafe_switch_time <= 0.0 or is_on_wall():
			strafe_sign = -strafe_sign if strafe_switch_time > 0.0 else (1.0 if randf() >= 0.5 else -1.0)
			strafe_switch_time = randf_range(0.85, 1.55)
		var strafe_direction := Vector3(-direction.z, 0.0, direction.x) * strafe_sign
		velocity = strafe_direction * movement_speed * 0.78
	if distance <= 14.5 and attack_cooldown <= 0.0:
		burst_shots_remaining = 1 + roundi(2.0 * threat_level)
		combat_state = "pistol_burst"
		state_timer = 0.16
		pending_attack_direction = direction
		velocity = Vector3.ZERO
		_set_motion_state("attack")
		_fire_pistol(direction)
		_start_recoil_pose()


func _update_combat_state(delta: float) -> void:
	state_timer = maxf(0.0, state_timer - delta)
	velocity = Vector3.ZERO
	if combat_state == "melee_windup":
		_update_threat_marker()
		if state_timer <= 0.0:
			threat_marker.visible = false
			combat_state = "melee_strike"
			state_timer = MELEE_STRIKE_TIME
			velocity = pending_attack_direction * 2.2
			_perform_melee_strike()
			_spawn_melee_slash()
			_start_strike_pose()
	elif combat_state == "melee_strike":
		velocity = pending_attack_direction * 1.2
		if state_timer <= 0.0:
			combat_state = "melee_recovery"
			state_timer = MELEE_RECOVERY_TIME
			velocity = Vector3.ZERO
	elif combat_state == "pistol_burst" and state_timer <= 0.0:
		if burst_shots_remaining > 0 and is_instance_valid(target) and _has_line_of_sight():
			var burst_direction := target.global_position - global_position
			burst_direction.y = 0.0
			if burst_direction.length_squared() > 0.01:
				burst_direction = burst_direction.normalized()
				pending_attack_direction = burst_direction
				_set_facing_from_world_direction(burst_direction)
				_fire_pistol(burst_direction)
				_start_recoil_pose()
			burst_shots_remaining -= 1
			state_timer = lerpf(0.22, 0.12, threat_level)
		else:
			burst_shots_remaining = 0
			attack_cooldown = lerpf(1.05, 0.48, threat_level)
			combat_state = "normal"
			_reset_sprite_pose()
			_set_motion_state("idle")
	elif combat_state in ["melee_recovery", "pistol_fire"] and state_timer <= 0.0:
		combat_state = "normal"
		_reset_sprite_pose()
		_set_motion_state("idle")
	move_and_slide()


func _perform_melee_strike() -> void:
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() > 1.75 or not _has_line_of_sight():
		return
	if target.has_method("take_damage"):
		target.call("take_damage", 12 + roundi(6.0 * threat_level))
	elif target.get_parent() != null and target.get_parent().has_method("take_damage"):
		target.get_parent().call("take_damage", 12 + roundi(6.0 * threat_level))


func _update_stagger(delta: float) -> void:
	state_timer = maxf(0.0, state_timer - delta)
	velocity = stagger_velocity
	stagger_velocity = stagger_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()
	if state_timer <= 0.0:
		combat_state = "normal"
		_reset_sprite_pose()
		_set_motion_state("idle")


func _has_line_of_sight() -> bool:
	var from := global_position + Vector3(0, 0.35, 0)
	var to := target.global_position + Vector3(0, 0.35, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target


func _target_is_in_safe_zone() -> bool:
	if not is_instance_valid(target) or target.get_parent() == null:
		return false
	var world := target.get_parent().get_node_or_null("World")
	return world != null and world.has_method("is_position_in_safe_zone") and world.call("is_position_in_safe_zone", target.global_position)


func _fire_pistol(direction: Vector3) -> void:
	var projectile := Area3D.new()
	projectile.name = "EnemyPistolBullet"
	projectile.set_script(BULLET_PROJECTILE)
	projectile.set("direction", direction)
	projectile.set("source_body", self)
	projectile.set("damage", 11 + roundi(7.0 * threat_level))
	projectile.set("hostile", true)
	projectile.position = global_position + direction * 0.72 + Vector3(0, 0.05, 0)
	get_parent().add_child(projectile)
	var perception := get_tree().get_first_node_in_group("perception_system")
	if perception:
		perception.call("emit_enemy_gunshot", self)
	_play_attack_feedback()


func _update_threat_marker() -> void:
	if threat_marker == null or not threat_marker.visible:
		return
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.025) * 0.18
	threat_marker.scale = Vector3.ONE * pulse
	threat_marker.position.y = 1.62 + sin(Time.get_ticks_msec() * 0.012) * 0.08


func _start_windup_pose() -> void:
	_kill_visual_tween()
	visual_tween = create_tween()
	visual_tween.set_parallel(true)
	visual_tween.tween_property(sprite, "scale", Vector3(0.9, 1.08, 1.0), MELEE_WINDUP_TIME)
	visual_tween.tween_property(sprite, "rotation", Vector3(0, 0, deg_to_rad(-8.0 if not sprite.flip_h else 8.0)), MELEE_WINDUP_TIME)
	visual_tween.tween_property(sprite, "position", SPRITE_BASE_POSITION - pending_attack_direction * 0.1, MELEE_WINDUP_TIME)


func _start_strike_pose() -> void:
	_kill_visual_tween()
	visual_tween = create_tween()
	visual_tween.set_parallel(true)
	visual_tween.tween_property(sprite, "scale", Vector3(1.12, 0.94, 1.0), 0.07)
	visual_tween.tween_property(sprite, "rotation", Vector3(0, 0, deg_to_rad(12.0 if not sprite.flip_h else -12.0)), 0.07)
	visual_tween.tween_property(sprite, "position", SPRITE_BASE_POSITION + pending_attack_direction * 0.18, 0.07)


func _start_recoil_pose() -> void:
	_kill_visual_tween()
	visual_tween = create_tween()
	visual_tween.tween_property(sprite, "position", SPRITE_BASE_POSITION - pending_attack_direction * 0.08, 0.05)
	visual_tween.tween_property(sprite, "position", SPRITE_BASE_POSITION, 0.12)


func _reset_sprite_pose() -> void:
	if sprite == null or dying:
		return
	sprite.position = SPRITE_BASE_POSITION
	sprite.scale = Vector3.ONE
	sprite.rotation = Vector3.ZERO
	sprite.modulate = Color.WHITE


func _kill_visual_tween() -> void:
	if visual_tween != null:
		visual_tween.kill()


func _play_attack_feedback() -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.45, 0.82, 0.58, 1), 0.045)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.11)


func take_damage(amount: int) -> void:
	take_hit(amount, Vector3.ZERO)


func is_backstab_from(attacker_position: Vector3) -> bool:
	var direction_to_attacker := attacker_position - global_position
	direction_to_attacker.y = 0.0
	if direction_to_attacker.length_squared() <= 0.01:
		return false
	return facing_world_direction.dot(direction_to_attacker.normalized()) <= -0.42


func take_melee_hit(amount: int, hit_direction: Vector3, backstab: bool) -> void:
	if dying or backstab_stunned:
		return
	if not backstab:
		take_hit(amount, hit_direction)
		return
	backstab_stunned = true
	health = 0
	combat_state = "stagger"
	state_timer = 0.28
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	threat_marker.text = "★"
	threat_marker.modulate = Color("#ffe17a")
	threat_marker.visible = true
	alert_marker_time = 0.28
	_set_motion_state("hit")
	_spawn_hit_burst(hit_direction, Color("#fff0a3"), 16, 0.34)
	_play_hit_reaction(hit_direction)
	get_tree().create_timer(0.24).timeout.connect(func() -> void:
		if is_instance_valid(self) and not dying:
			backstab_stunned = false
			_start_death(hit_direction)
	)


func take_hit(amount: int, hit_direction: Vector3) -> void:
	if dying or backstab_stunned:
		return
	health -= amount
	threat_marker.visible = false
	var knockback_direction := hit_direction
	knockback_direction.y = 0.0
	if knockback_direction.length_squared() <= 0.01:
		knockback_direction = -pending_attack_direction
	knockback_direction = knockback_direction.normalized()
	stagger_velocity = knockback_direction * 3.6
	_spawn_hit_burst(knockback_direction, Color("#ffcf91"), 10, 0.3)
	_play_hit_reaction(knockback_direction)
	if health <= 0:
		_start_death(knockback_direction)
		return
	combat_state = "stagger"
	state_timer = HIT_STAGGER_TIME
	_set_motion_state("hit")


func _play_hit_reaction(hit_direction: Vector3) -> void:
	_kill_visual_tween()
	visual_tween = create_tween()
	visual_tween.tween_property(sprite, "modulate", Color(2.4, 2.4, 2.4, 1), 0.025)
	visual_tween.tween_property(sprite, "modulate", Color(1.8, 0.16, 0.1, 1), 0.055)
	visual_tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	var shake := create_tween()
	shake.tween_property(sprite, "position", SPRITE_BASE_POSITION + hit_direction * 0.11, 0.035)
	shake.tween_property(sprite, "position", SPRITE_BASE_POSITION - hit_direction * 0.055, 0.035)
	shake.tween_property(sprite, "position", SPRITE_BASE_POSITION, 0.07)


func _start_death(hit_direction: Vector3) -> void:
	dying = true
	backstab_stunned = false
	combat_state = "dying"
	threat_marker.visible = false
	collision_layer = 0
	collision_mask = 0
	velocity = hit_direction * 2.5
	_set_motion_state("death")
	_spawn_hit_burst(hit_direction, Color("#8b1717"), 18, 0.55)
	died.emit(self)
	_kill_visual_tween()
	visual_tween = create_tween()
	visual_tween.set_parallel(true)
	visual_tween.tween_property(sprite, "modulate", Color(0.35, 0.08, 0.07, 0.0), 0.48)
	visual_tween.tween_property(sprite, "scale", Vector3(1.18, 0.48, 1.0), 0.48)
	visual_tween.tween_property(sprite, "position", Vector3(0, -0.25, 0), 0.48)
	visual_tween.tween_property(sprite, "rotation", Vector3(0, 0, deg_to_rad(18.0 if not sprite.flip_h else -18.0)), 0.48)
	if shadow:
		var shadow_tween := create_tween()
		shadow_tween.tween_property(shadow, "scale", Vector3(0.2, 0.2, 0.2), 0.42)
	get_tree().create_timer(0.52).timeout.connect(queue_free)


func _spawn_hit_burst(direction: Vector3, color: Color, amount: int, lifetime: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "EnemyHitBurst"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.7
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	var process := ParticleProcessMaterial.new()
	process.direction = (direction + Vector3.UP * 0.7).normalized()
	process.spread = 58.0
	process.gravity = Vector3(0, -4.5, 0)
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.8
	process.scale_min = 0.55
	process.scale_max = 1.25
	process.color = color
	particles.process_material = process
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 2.2
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.075, 0.075)
	mesh.material = material
	particles.draw_pass_1 = mesh
	get_parent().add_child(particles)
	particles.global_position = global_position + Vector3(0, 0.35, 0)
	particles.emitting = true
	get_tree().create_timer(lifetime + 0.2).timeout.connect(particles.queue_free)


func _spawn_melee_slash() -> void:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(48, 48)
	for y in 96:
		for x in 96:
			var offset := Vector2(x, y) - center
			var radius := offset.length()
			var angle := rad_to_deg(atan2(offset.y, offset.x))
			if radius >= 31.0 and radius <= 42.0 and absf(angle) <= 72.0:
				var alpha := 1.0 - absf(radius - 36.5) / 5.5
				image.set_pixel(x, y, Color(1.0, 0.72, 0.28, alpha * 0.9))
	var slash := Sprite3D.new()
	slash.name = "MeleeSlash"
	slash.texture = ImageTexture.create_from_image(image)
	slash.pixel_size = 0.011
	slash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slash.shaded = false
	slash.transparent = true
	slash.no_depth_test = true
	slash.render_priority = 95
	get_parent().add_child(slash)
	slash.global_position = global_position + pending_attack_direction * 0.62 + Vector3(0, 0.34, 0)
	slash.flip_h = sprite.flip_h
	slash.rotation.z = deg_to_rad(-22.0 if not sprite.flip_h else 22.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "scale", Vector3(1.35, 1.35, 1.35), 0.16)
	tween.tween_property(slash, "modulate", Color(1, 0.45, 0.18, 0), 0.16)
	get_tree().create_timer(0.18).timeout.connect(slash.queue_free)
