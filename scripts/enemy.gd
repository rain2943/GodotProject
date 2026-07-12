extends CharacterBody3D

signal died(enemy: CharacterBody3D)

const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const MELEE_SPEED := 3.1
const PISTOL_SPEED := 2.5
const FRAME_SIZE := Vector2(384, 384)
const SCREEN_DIRECTION_NAMES := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]

var enemy_kind := "melee"
var target: CharacterBody3D
var animation_sheets := {}
var health := 55
var attack_cooldown := 0.0
var sprite: AnimatedSprite3D
var motion_state := "idle"
var facing := "s"


func configure(kind: String, target_body: CharacterBody3D, sheets: Dictionary) -> void:
	enemy_kind = kind
	target = target_body
	animation_sheets = sheets
	health = 70 if enemy_kind == "melee" else 50


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
	var shadow := MeshInstance3D.new()
	shadow.name = "Shadow"
	shadow.position.y = -0.7
	shadow.mesh = shadow_mesh
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

	sprite = AnimatedSprite3D.new()
	sprite.name = "EnemySprite"
	sprite.sprite_frames = _create_sprite_frames()
	sprite.position.y = 0.25
	sprite.pixel_size = 0.0068
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.no_depth_test = true
	sprite.render_priority = 30
	add_child(sprite)
	_play_animation()


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		_set_motion_state("idle")
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var vision_range := 9.5 if enemy_kind == "melee" else 13.0
	var can_see_target := distance <= vision_range and _has_line_of_sight()
	if not can_see_target:
		velocity = velocity.move_toward(Vector3.ZERO, 12.0 * delta)
		_set_motion_state("idle")
		move_and_slide()
		return

	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	_set_facing_from_world_direction(direction)
	if enemy_kind == "melee":
		_update_melee(direction, distance)
	else:
		_update_pistol(direction, distance)
	_set_motion_state("walk" if velocity.length_squared() > 0.05 else "idle")
	move_and_slide()


func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction_name in animation_sheets:
		for state in ["idle", "walk"]:
			var animation_name := "%s_%s" % [state, direction_name]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, true)
			frames.set_animation_speed(animation_name, 7.0 if state == "idle" else 8.5)
			var first_frame := 0 if state == "idle" else 8
			for frame_index in range(first_frame, first_frame + 8):
				var atlas := AtlasTexture.new()
				atlas.atlas = animation_sheets[direction_name]
				atlas.region = Rect2(
					(frame_index % 4) * FRAME_SIZE.x,
					(frame_index / 4) * FRAME_SIZE.y,
					FRAME_SIZE.x,
					FRAME_SIZE.y
				)
				frames.add_frame(animation_name, atlas)
	return frames


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
	if distance > 1.35:
		velocity = direction * MELEE_SPEED
	else:
		velocity = Vector3.ZERO
		if attack_cooldown <= 0.0:
			attack_cooldown = 0.95
			_play_attack_feedback()
			if target.has_method("take_damage"):
				target.call("take_damage", 12)
			elif target.get_parent() != null and target.get_parent().has_method("take_damage"):
				target.get_parent().call("take_damage", 12)


func _update_pistol(direction: Vector3, distance: float) -> void:
	if distance > 7.5:
		velocity = direction * PISTOL_SPEED
	elif distance < 4.2:
		velocity = -direction * PISTOL_SPEED
	else:
		velocity = Vector3.ZERO
	if distance <= 11.5 and attack_cooldown <= 0.0:
		attack_cooldown = 1.25
		_fire_pistol(direction)


func _has_line_of_sight() -> bool:
	var from := global_position + Vector3(0, 0.35, 0)
	var to := target.global_position + Vector3(0, 0.35, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target


func _fire_pistol(direction: Vector3) -> void:
	var projectile := Area3D.new()
	projectile.name = "EnemyPistolBullet"
	projectile.set_script(BULLET_PROJECTILE)
	projectile.set("direction", direction)
	projectile.set("source_body", self)
	projectile.set("damage", 9)
	projectile.set("hostile", true)
	projectile.position = global_position + direction * 0.72 + Vector3(0, 0.05, 0)
	get_parent().add_child(projectile)
	_play_attack_feedback()


func _play_attack_feedback() -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.35, 0.78, 0.62, 1), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func take_damage(amount: int) -> void:
	health -= amount
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.7, 0.35, 0.28, 1), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		died.emit(self)
		queue_free()
