extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene.set("run_kills", 3)
	main_scene.set("run_damage_dealt", 420)
	main_scene.call("_begin_player_death_sequence")
	assert(bool(main_scene.get("player_death_sequence_active")))
	assert(Engine.time_scale < 1.0)
	var label := main_scene.get("game_over_label") as Label
	assert(label != null)
	assert(label.text.contains("GAME OVER"))
	assert(label.text.contains("처치한 적"))
	Engine.time_scale = 1.0
	main_scene.queue_free()
	print("PLAYER_DEATH_SEQUENCE_OK")
	quit(0)
