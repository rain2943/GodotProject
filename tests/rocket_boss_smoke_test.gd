extends SceneTree

const ROCKET_BOSS := preload("res://scripts/rocket_boss.gd")
const ROCKET_PROJECTILE := preload("res://scripts/rocket_projectile.gd")


class DummyTarget:
	extends CharacterBody3D
	var received_damage := 0

	func take_hit(amount: int, _direction: Vector3) -> void:
		received_damage += amount


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	var target := DummyTarget.new()
	target.position = Vector3(8.0, 0.78, 0.0)
	arena.add_child(target)

	var boss := CharacterBody3D.new()
	boss.set_script(ROCKET_BOSS)
	boss.call("configure_rocket_boss", target, 0.8)
	arena.add_child(boss)
	await process_frame

	assert(boss.is_in_group("rocket_boss"))
	assert(int(boss.call("get_rocket_magazine_ammo")) == 4)
	var sprite := boss.get("sprite") as AnimatedSprite3D
	assert(sprite != null)
	for direction in ["n", "ne", "e", "se", "s", "sw", "w", "nw"]:
		assert(sprite.sprite_frames.get_frame_count("idle_%s" % direction) == 4)
		assert(sprite.sprite_frames.get_frame_count("walk_%s" % direction) == 4)

	var replacement_texture := load("res://assets/enemies/rocket_boss/up_right_walk_0.png") as Texture2D
	var replacement_frame := replacement_texture.get_image()
	assert(replacement_frame.get_width() == 256 and replacement_frame.get_height() == 256)
	assert(replacement_frame.get_pixel(0, 0).a < 0.01)

	for shot in 4:
		boss.call("_fire_rocket", Vector3.RIGHT)
	assert(int(boss.call("get_rocket_magazine_ammo")) == 0)
	boss.call("_start_boss_reload")
	assert(bool(boss.call("is_rocket_reloading")))

	var direct_rocket := Node3D.new()
	direct_rocket.set_script(ROCKET_PROJECTILE)
	direct_rocket.call(
		"configure", boss, target, Vector3(0.0, 1.0, 0.0),
		target.global_position, 40, 2.65
	)
	arena.add_child(direct_rocket)
	await process_frame
	direct_rocket.call("_detonate")
	assert(target.received_damage == 40)

	print("ROCKET_BOSS_OK frames=64 magazine=4 damage=%d" % target.received_damage)
	arena.queue_free()
	await process_frame
	quit(0)
