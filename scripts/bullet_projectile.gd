extends Area3D

const SPEED := 30.0
const MAX_LIFETIME := 1.6

var direction := Vector3.FORWARD
var source_body: Node3D
var damage := 20
var hostile := false
var lifetime := 0.0


func _ready() -> void:
	collision_layer = 4 if not hostile else 8
	collision_mask = 3 if not hostile else 1
	monitoring = true
	body_entered.connect(_on_body_entered)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("#ff7a58") if hostile else Color("#ffd36a")
	material.emission_enabled = true
	material.emission = Color("#ff3d2e") if hostile else Color("#ff9d32")
	material.emission_energy_multiplier = 3.2

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.055, 0.055, 0.48)
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.1, 0.1, 0.42)
	collision.shape = shape
	add_child(collision)

	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	var next_position := global_position + direction * SPEED * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position, collision_mask)
	if is_instance_valid(source_body) and source_body is CollisionObject3D:
		query.exclude = [(source_body as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_apply_hit(hit.get("collider"))
		return
	global_position = next_position
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == source_body:
		return
	_apply_hit(body)


func _apply_hit(body: Object) -> void:
	if body != null and body.has_method("take_damage"):
		body.call("take_damage", damage)
	elif body is Node and (body as Node).get_parent() != null and (body as Node).get_parent().has_method("take_damage"):
		(body as Node).get_parent().call("take_damage", damage)
	queue_free()
