extends Area3D

const SPEED := 30.0
const MAX_LIFETIME := 1.6

var direction := Vector3.FORWARD
var source_body: Node3D
var lifetime := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("#ffd36a")
	material.emission_enabled = true
	material.emission = Color("#ff9d32")
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
	global_position += direction * SPEED * delta
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == source_body:
		return
	queue_free()
