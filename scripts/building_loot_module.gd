extends Node3D

const SALVAGE_TEXTURE := preload("res://assets/interiors/office_dungeon/modules/office_salvage_loot_v1.png")
const AMMO_TEXTURE := preload("res://assets/items/ammo_762.png")
const COMPONENT_TEXTURES := [
	preload("res://assets/items/mod_components/rubber_gasket.png"),
	preload("res://assets/items/mod_components/scope_lens.png"),
	preload("res://assets/items/mod_components/magazine_spring.png"),
]
const UI_ICONS := preload("res://scripts/ui_icon_factory.gd")

signal collected(loot_key: String, description: String)

var loot_key := ""
var loot_type := "canned_food"
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
		"ammo":
			GameState.set_ammo_count(
				GameState.equipped_ammo_id,
				GameState.get_ammo_count(GameState.equipped_ammo_id) + amount
			)
			description = "탄약 %d발 획득" % amount
		"canned_food":
			GameState.canned_food += amount
			description = "통조림 %d개 획득" % amount
		"component":
			var component_id := _resolved_component_id()
			GameState.add_mod_component(component_id, amount)
			description = "%s %d개 획득" % [_component_display_name(component_id), amount]
		"weapon":
			var weapon_id := _resolved_weapon_id()
			GameState.add_weapon(weapon_id, amount)
			description = "%s 획득 · 가방에서 장착" % _weapon_display_name(weapon_id)
		"equipment":
			var equipment_id := _resolved_equipment_id()
			GameState.add_equipment(equipment_id, amount)
			var definition: Dictionary = GameState.get_equipment_definition(equipment_id)
			description = "%s 획득 · 가방에서 장착" % str(definition.get("display_name", "방어구"))
		_:
			# Legacy/unknown field loot is converted to food. Scrap is shelter-produced only.
			GameState.canned_food += maxi(1, amount)
			description = "통조림 %d개 획득" % maxi(1, amount)
	BuildingRunState.mark_loot_collected(floor_number, loot_key)
	GameState.save_persistent_state()
	collected.emit(loot_key, description)
	queue_free()
	return description


func _display_name() -> String:
	match loot_type:
		"ammo": return "탄약 상자"
		"canned_food": return "비상 식량"
		"component": return "부품 보관함"
		"weapon": return "버려진 총기"
		"equipment": return "방어 장비"
	return "보급품"


func _build_visual() -> void:
	var texture: Texture2D = SALVAGE_TEXTURE
	var pixel_size := 0.00075
	match loot_type:
		"ammo":
			texture = AMMO_TEXTURE
			pixel_size = 0.0032
		"canned_food":
			texture = UI_ICONS.get_icon("food", 96, Color("#d9b85f"))
			pixel_size = 0.007
		"component":
			texture = COMPONENT_TEXTURES[absi(loot_key.hash()) % COMPONENT_TEXTURES.size()]
			pixel_size = 0.00075
		"weapon":
			texture = UI_ICONS.get_icon("weapon", 96, Color("#c4d0ca"))
			pixel_size = 0.007
		"equipment":
			var equipment: Dictionary = GameState.get_equipment_definition(_resolved_equipment_id())
			var icon_name := "helmet" if str(equipment.get("slot", "body")) == "head" else "armor"
			texture = UI_ICONS.get_icon(icon_name, 96, Color("#a9c8b8"))
			pixel_size = 0.007
	var sprite := Sprite3D.new()
	sprite.name = "GeneratedLootVisual"
	sprite.texture = texture
	sprite.pixel_size = pixel_size
	sprite.position = Vector3(0, float(texture.get_height()) * pixel_size * 0.5, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(sprite)
	var marker := Label3D.new()
	marker.name = "LootMarker"
	marker.position = Vector3(0, 1.25, 0)
	marker.text = "◆"
	marker.font_size = 38
	marker.modulate = Color("#e0ba55")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	add_child(marker)


func _resolved_component_id() -> String:
	var component_ids: Array[String] = ["rubber_gasket", "scope_lens", "magazine_spring"]
	return component_ids[absi(loot_key.hash()) % component_ids.size()]


func _resolved_weapon_id() -> String:
	var weapon_ids: Array[String] = ["m1911", "mp5", "double_barrel"]
	return weapon_ids[absi(loot_key.hash()) % weapon_ids.size()]


func _resolved_equipment_id() -> String:
	var equipment_ids: Array[String] = [
		"scav_vest",
		"patched_helmet",
		"riot_vest",
		"tactical_helmet",
		"patched_sneakers",
		"tactical_boots",
	]
	return equipment_ids[absi(loot_key.hash()) % equipment_ids.size()]


func _component_display_name(component_id: String) -> String:
	match component_id:
		"rubber_gasket": return "고무 패킹"
		"scope_lens": return "스코프 렌즈"
		"magazine_spring": return "탄창 스프링"
	return "총기 부품"


func _weapon_display_name(weapon_id: String) -> String:
	match weapon_id:
		"m1911": return "M1911"
		"mp5": return "MP5"
		"double_barrel": return "더블배럴 산탄총"
	return "총기"
