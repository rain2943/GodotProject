extends Node3D

signal collected(loot_key: String, description: String)

var loot_key := ""
var loot_type := "scrap"
var amount := 1
var floor_number := 1
@onready var BuildingRunState: Node = get_node("/root/BuildingRunState")
@onready var GameState: Node = get_node("/root/GameState")


func configure(key_value: String, type_value: String, amount_value: int, floor_value: int) -> void:
	loot_key = key_value
	loot_type = type_value
	amount = amount_value
	floor_number = floor_value
	set_meta("loot_key", loot_key)
	set_meta("loot_type", loot_type)


func _ready() -> void:
	add_to_group("building_interactable")
	add_to_group("building_loot_module")
	_build_visual()


func get_interaction_radius() -> float:
	return 1.65


func get_interaction_prompt() -> String:
	return "수색하기 · %s" % _display_name()


func interact() -> String:
	if BuildingRunState.is_loot_collected(floor_number, loot_key):
		return "이미 비어 있습니다."
	var description := ""
	match loot_type:
		"scrap":
			GameState.scrap += amount
			description = "고철 %d 획득" % amount
		"ammo":
			GameState.reserve_ammo += amount
			description = "탄약 %d발 획득" % amount
		"component":
			var component_ids := ["rubber_gasket", "scope_lens", "magazine_spring"]
			var component_id: String = component_ids[absi(loot_key.hash()) % component_ids.size()]
			GameState.mod_component_inventory[component_id] = int(GameState.mod_component_inventory.get(component_id, 0)) + amount
			description = "제작 부품 %d개 획득" % amount
		_:
			GameState.scrap += amount
			description = "물자 %d 획득" % amount
	BuildingRunState.mark_loot_collected(floor_number, loot_key)
	collected.emit(loot_key, description)
	queue_free()
	return description


func _display_name() -> String:
	match loot_type:
		"ammo": return "탄약 상자"
		"component": return "부품 보관함"
	return "사무실 잔해"


func _build_visual() -> void:
	var color := Color("#71583e")
	if loot_type == "ammo": color = Color("#556348")
	elif loot_type == "component": color = Color("#465c68")
	_add_box("LootCrate", Vector3(0, 0.32, 0), Vector3(0.95, 0.64, 0.78), color)
	_add_box("LootLid", Vector3(0, 0.68, 0), Vector3(1.02, 0.11, 0.84), color.lightened(0.12))
	var marker := Label3D.new()
	marker.name = "LootMarker"
	marker.position = Vector3(0, 1.25, 0)
	marker.text = "◆"
	marker.font_size = 38
	marker.modulate = Color("#e0ba55")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	add_child(marker)


func _add_box(node_name: String, local_position: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = local_position
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	mesh.material = material
	instance.mesh = mesh
	add_child(instance)
