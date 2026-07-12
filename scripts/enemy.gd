extends CharacterBody3D

signal died(enemy: CharacterBody3D)

const BULLET_PROJECTILE := preload("res://scripts/bullet_projectile.gd")
const MELEE_SPEED := 3.1
const PISTOL_SPEED := 2.5

var enemy_kind := "melee"
var target: CharacterBody3D
var sprite_texture: Texture2D
var health := 55
var attack_cooldown := 0.0
var sprite: Sprite3D


func configure(kind: String, target_body: CharacterBody3D, texture: Texture2D) -> void:
	enemy_kind = kind
	target = target_body
	sprite_texture = texture
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

	sprite = Sprite3D.new()
	sprite.name = "EnemySprite"
	sprite.texture = sprite_texture
	sprite.position.y = 0.25
	sprite.pixel_size = 0.0019
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.no_depth_test = true
	sprite.render_priority = 30
	add_child(sprite)


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var vision_range := 9.5 if enemy_kind == "melee" else 13.0
	var can_see_target := distance <= vision_range and _has_line_of_sight()
	if not can_see_target:
		velocity = velocity.move_toward(Vector3.ZERO, 12.0 * delta)
		move_and_slide()
		return

	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	sprite.flip_h = direction.x - direction.z < 0.0
	if enemy_kind == "melee":
		_update_melee(direction, distance)
	else:
		_update_pistol(direction, distance)
	move_and_slide()


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
