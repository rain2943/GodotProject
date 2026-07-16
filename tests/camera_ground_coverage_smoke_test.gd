extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(main_scene)
	await process_frame
	await physics_frame

	var camera := main_scene.get_node("CameraRig/Camera3D") as Camera3D
	var viewport_size := root.get_viewport().get_visible_rect().size
	var bottom_center := Vector2(viewport_size.x * 0.5, viewport_size.y)
	var bottom_ray_origin := camera.project_ray_origin(bottom_center)
	assert(bottom_ray_origin.y > 0.5)
	print("CAMERA_GROUND_COVERAGE_OK bottom_ray_y=%.3f" % bottom_ray_origin.y)
	quit(0)
