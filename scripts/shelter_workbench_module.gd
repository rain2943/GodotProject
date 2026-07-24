class_name ShelterWorkbenchModule
extends Node3D

const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")
const UI_ICONS := preload("res://scripts/ui_icon_factory.gd")
const WEAPON_VISUAL_CATALOG := preload("res://scripts/weapon_visual_catalog.gd")
const AMMO_TEXTURE := preload("res://assets/items/ammo_762.png")
const SCOPE_LENS_TEXTURE := preload("res://assets/items/mod_components/scope_lens.png")
const RUBBER_GASKET_TEXTURE := preload("res://assets/items/mod_components/rubber_gasket.png")
const MAGAZINE_SPRING_TEXTURE := preload("res://assets/items/mod_components/magazine_spring.png")

const RECIPES := {
	"parts": [
		{
			"id": "scope_lens",
			"name": "스코프 렌즈",
			"desc": "폐점포 스코프와 정밀 리시버 제작에 쓰는 투명 렌즈 부품.",
			"cost": {"scrap": 45},
			"result": {"component": "scope_lens", "amount": 1},
		},
		{
			"id": "rubber_gasket",
			"name": "고무 패킹",
			"desc": "총구 양말, 임시 완충재, 방수 부품에 쓰는 탄성 고무.",
			"cost": {"scrap": 35},
			"result": {"component": "rubber_gasket", "amount": 1},
		},
		{
			"id": "magazine_spring",
			"name": "탄창 스프링",
			"desc": "테이프 듀얼 탄창과 급탄 개선 부품에 쓰는 스프링.",
			"cost": {"scrap": 40},
			"result": {"component": "magazine_spring", "amount": 1},
		},
		{
			"id": "scope_2x",
			"name": "폐점포 2x 스코프",
			"desc": "스코프 렌즈를 조립한 완성 조준경입니다.",
			"cost": {"scrap": 35, "scope_lens": 1},
			"result": {"weapon_mod": "scope_2x", "amount": 1},
		},
		{
			"id": "muffled_sock",
			"name": "소리 방지용 양말",
			"desc": "고무 패킹으로 고정한 임시 소음기입니다.",
			"cost": {"scrap": 25, "rubber_gasket": 1},
			"result": {"weapon_mod": "muffled_sock", "amount": 1},
		},
		{
			"id": "sponge_pad",
			"name": "스펀지 턱받이",
			"desc": "반동 회복을 돕는 완성 개머리판 패드입니다.",
			"cost": {"scrap": 45, "rubber_gasket": 1},
			"result": {"weapon_mod": "sponge_pad", "amount": 1},
		},
		{
			"id": "quick_mag",
			"name": "테이프 듀얼 탄창",
			"desc": "탄창 스프링을 사용한 빠른 교체용 탄창입니다.",
			"cost": {"scrap": 55, "magazine_spring": 1},
			"result": {"weapon_mod": "quick_mag", "amount": 1},
		},
		{
			"id": "bell_bait",
			"name": "딸랑이 방울",
			"desc": "적의 주의를 유도하는 전술 보조공구입니다.",
			"cost": {"scrap": 20, "magazine_spring": 1},
			"result": {"weapon_mod": "bell_bait", "amount": 1},
		},
		{
			"id": "ak_precision_receiver",
			"name": "AK 정밀 단발 리시버",
			"desc": "AK의 발사 특성을 바꾸는 특수 전술 모듈입니다.",
			"cost": {"scrap": 160, "scope_lens": 2},
			"result": {"weapon_mod": "ak_precision_receiver", "amount": 1},
			"required_workbench": 5,
		},
	],
	"ammo": [
		{
			"id": "762_fmj_pack",
			"name": "7.62mm 보통탄 x30",
			"desc": "AK 계열 기본 탄약. 강하지만 총성이 커서 적을 끌어들입니다.",
			"cost": {"scrap": 55, "magazine_spring": 1},
			"result": {"ammo": "762_fmj", "amount": 30},
		},
		{
			"id": "9mm_fmj_pack",
			"name": "9mm 보통탄 x45",
			"desc": "기관단총용 기본 탄약. 가볍고 수급이 안정적입니다.",
			"cost": {"scrap": 45, "rubber_gasket": 1},
			"result": {"ammo": "9mm_fmj", "amount": 45},
		},
		{
			"id": "12g_buckshot_pack",
			"name": "12게이지 벅샷 x12",
			"desc": "근거리 저지력이 높은 산탄. 위기 탈출용으로 좋습니다.",
			"cost": {"scrap": 75, "rubber_gasket": 1, "magazine_spring": 1},
			"result": {"ammo": "12g_buckshot", "amount": 12},
		},
	],
	"weapons": [
		{
			"id": "m1911",
			"name": "M1911 솜방망이",
			"desc": "초반 거지런과 최후의 보루용 권총.",
			"cost": {"scrap": 160, "canned_food": 2, "rubber_gasket": 1},
			"result": {"weapon": "m1911", "amount": 1},
			"required_tier": 1,
		},
		{
			"id": "mp5",
			"name": "MP5 하악이",
			"desc": "기동전과 좀비 소탕에 강한 기관단총.",
			"cost": {"scrap": 260, "canned_food": 3, "magazine_spring": 2, "rubber_gasket": 1},
			"result": {"weapon": "mp5", "amount": 1},
			"required_tier": 1,
		},
		{
			"id": "ak47",
			"name": "AK-47 캣라시니코프",
			"desc": "강한 반동과 총성을 감수하고 화력을 얻는 소총.",
			"cost": {"scrap": 620, "canned_food": 6, "scope_lens": 1, "magazine_spring": 2},
			"result": {"weapon": "ak47", "amount": 1},
			"required_tier": 2,
		},
		{
			"id": "double_barrel",
			"name": "더블배럴 참치 헌터",
			"desc": "장전 중 무방비가 되지만 초근접 저지력이 강한 산탄총.",
			"cost": {"scrap": 940, "canned_food": 9, "rubber_gasket": 3, "magazine_spring": 2},
			"result": {"weapon": "double_barrel", "amount": 1},
			"required_tier": 3,
		},
	],
	"supplies": [
		{
			"id": "repair_kit",
			"name": "임시 총기 수리",
			"desc": "장착 총기의 내구도를 즉시 조금 회복합니다.",
			"cost": {"scrap": 60, "rubber_gasket": 1},
			"result": {"repair": 18.0},
		},
	],
	"artisan": [
		{
			"id": "artisan_roll",
			"name": "장인 고양이의 야간 제작",
			"desc": "통조림과 고철을 맡겨 현재 쉘터 Tier에서 제작 가능한 무기 하나를 받습니다. 10회 안에는 최고 등급이 확정됩니다.",
			"cost": {},
			"result": {"artisan": true},
		},
	],
	"enhance": [
		{
			"id": "enhance_equipped",
			"name": "장착 무기 영구 강화",
			"desc": "장착 중인 무기에 고철을 투자해 +99까지 피해와 안정성을 영구 강화합니다.",
			"cost": {},
			"result": {"enhance": true},
		},
	],
}

const CATEGORY_NAMES := {
	"parts": "부품",
	"ammo": "탄약",
	"weapons": "무기",
	"supplies": "보급",
	"artisan": "장인 제작",
	"enhance": "+99 강화",
}
const CATEGORY_ICONS := {
	"parts": "parts",
	"ammo": "ammo",
	"weapons": "weapon",
	"supplies": "repair",
	"artisan": "craft",
	"enhance": "upgrade",
}

@export var interaction_radius := 2.9

@onready var sprite: Sprite3D = $WorkbenchSprite

var has_focus := false
var ui_layer: CanvasLayer
var selected_category := "parts"
var selected_recipe_id := "scope_lens"
var recipe_list: VBoxContainer
var detail_box: VBoxContainer
var resource_label: Label


func _ready() -> void:
	add_to_group("shelter_module")
	add_to_group("shelter_workbench")
	set_meta("module_kind", "workbench")


func get_interaction_prompt() -> String:
	return "무기 작업대"


func get_interaction_radius() -> float:
	return interaction_radius


func interact() -> String:
	GameState.process_shelter_progress()
	GameState.claim_workbench_starter_parts()
	_open_ui()
	return "작업대 제작 메뉴를 열었습니다."


func set_interaction_focus(value: bool) -> void:
	has_focus = value
	if sprite:
		sprite.modulate = Color(1.15, 1.12, 0.9, 1.0) if has_focus else Color.WHITE


func _open_ui() -> void:
	if is_instance_valid(ui_layer):
		ui_layer.queue_free()
	ui_layer = CanvasLayer.new()
	ui_layer.name = "WorkbenchUILayer"
	ui_layer.layer = 20
	ui_layer.add_to_group("shelter_modal_ui")
	var ui_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	ui_parent.add_child(ui_layer)
	_rebuild_ui()


func _rebuild_ui() -> void:
	if not is_instance_valid(ui_layer):
		return
	for child in ui_layer.get_children():
		child.queue_free()

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.006, 0.008, 0.011, 0.68)
	ui_layer.add_child(dim)

	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 44
	root.offset_top = 34
	root.offset_right = -44
	root.offset_bottom = -36
	root.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.023, 0.027, 0.95), Color("#8ac2a7"), 2, 10))
	ui_layer.add_child(root)

	var margin := _margin(26, 22, 26, 24)
	root.add_child(margin)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	margin.add_child(main)

	main.add_child(_build_header())
	main.add_child(_build_tabs())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	main.add_child(body)

	body.add_child(_build_recipe_list())
	body.add_child(_build_detail_panel())
	_refresh_recipe_list()
	_refresh_detail_panel()


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_label("제작 작업대  Lv.%d" % GameState.shelter_workbench_level, 30, Color("#f0e6c8")))
	resource_label = _label(_resource_text(), 15, Color("#b7cfc3"))
	title_box.add_child(resource_label)

	var repair := _button("시간제 수리", "time")
	repair.custom_minimum_size = Vector2(116, 42)
	repair.pressed.connect(_start_repair)
	header.add_child(repair)

	var upgrade := _button("업그레이드", "upgrade")
	upgrade.custom_minimum_size = Vector2(116, 42)
	upgrade.pressed.connect(_upgrade_workbench)
	header.add_child(upgrade)

	var close := _button("닫기", "close")
	close.custom_minimum_size = Vector2(82, 42)
	close.pressed.connect(func() -> void:
		if is_instance_valid(ui_layer):
			ui_layer.queue_free()
	)
	header.add_child(close)
	return header


func _build_tabs() -> Control:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for category in ["parts", "ammo", "weapons", "supplies", "artisan", "enhance"]:
		var tab := _button(str(CATEGORY_NAMES[category]), str(CATEGORY_ICONS[category]))
		tab.toggle_mode = true
		tab.button_pressed = selected_category == category
		tab.custom_minimum_size = Vector2(116, 40)
		tab.pressed.connect(func() -> void:
			selected_category = category
			var recipes: Array = _recipes_for_category(selected_category)
			if not recipes.is_empty():
				selected_recipe_id = str((recipes[0] as Dictionary).get("id", ""))
			_rebuild_ui()
		)
		tabs.add_child(tab)
	return tabs


func _build_recipe_list() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.043, 0.049, 0.86), Color("#456b61"), 1, 8))
	var margin := _margin(12, 12, 12, 12)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(recipe_list)
	return panel


func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.021, 0.027, 0.032, 0.88), Color("#55776d"), 1, 8))
	var margin := _margin(22, 20, 22, 20)
	panel.add_child(margin)
	detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 14)
	margin.add_child(detail_box)
	return panel


func _refresh_recipe_list() -> void:
	_clear(recipe_list)
	var recipes: Array = _recipes_for_category(selected_category)
	for recipe_raw in recipes:
		var recipe: Dictionary = recipe_raw
		var button := _button("%s\n%s" % [str(recipe["name"]), _cost_short_text(recipe)])
		button.icon = _recipe_icon(recipe)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(330, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = str(recipe["id"]) == selected_recipe_id
		button.pressed.connect(func() -> void:
			selected_recipe_id = str(recipe["id"])
			_refresh_recipe_list()
			_refresh_detail_panel()
		)
		recipe_list.add_child(button)


func _refresh_detail_panel() -> void:
	_clear(detail_box)
	var recipe := _selected_recipe()
	if recipe.is_empty():
		detail_box.add_child(_label("선택된 설계도가 없습니다.", 18, Color("#dfe6de")))
		return

	var title := _label(str(recipe["name"]), 30, Color("#f0e6c8"))
	detail_box.add_child(title)
	detail_box.add_child(_label(str(recipe.get("desc", "")), 16, Color("#cdd8d0")))

	var icon_card := PanelContainer.new()
	icon_card.custom_minimum_size = Vector2(170, 118)
	icon_card.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.082, 0.088, 0.8), Color("#8ac2a7"), 1, 8))
	var icon_margin := _margin(12, 10, 12, 10)
	icon_card.add_child(icon_margin)
	var icon_texture := TextureRect.new()
	icon_texture.texture = _recipe_icon(recipe)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_margin.add_child(icon_texture)
	detail_box.add_child(icon_card)

	detail_box.add_child(_section("필요 재료"))
	var cost_box := VBoxContainer.new()
	cost_box.add_theme_constant_override("separation", 6)
	detail_box.add_child(cost_box)
	var effective_cost := _effective_cost(recipe)
	for key in effective_cost.keys():
		var needed := int(effective_cost[key])
		var owned := _owned_resource(str(key))
		var color := Color("#bde5c9") if owned >= needed else Color("#e68576")
		cost_box.add_child(_resource_row(str(key), owned, needed, color))
	var required_tier := int(recipe.get("required_tier", 1))
	if GameState.shelter_tier < required_tier:
		cost_box.add_child(_label("쉘터 Tier %d에서 해금" % required_tier, 17, Color("#e68576")))
	if bool((recipe.get("result", {}) as Dictionary).get("artisan", false)):
		cost_box.add_child(_label("확정 천장 %d / %d" % [GameState.artisan_pity, GameState.ARTISAN_PITY_LIMIT], 16, Color("#d9c579")))
	if bool((recipe.get("result", {}) as Dictionary).get("enhance", false)):
		var level := GameState.get_weapon_enhancement_level(GameState.equipped_weapon_id)
		cost_box.add_child(_label("%s  +%d → +%d" % [GameState.equipped_weapon_id.to_upper(), level, mini(99, level + 1)], 17, Color("#d9c579")))

	var result_label := _label("결과: %s" % _result_text(recipe), 17, Color("#d9c579"))
	detail_box.add_child(result_label)

	var craft := _button("제작", "craft")
	craft.custom_minimum_size = Vector2(240, 48)
	craft.disabled = not _can_craft(recipe)
	craft.pressed.connect(func() -> void:
		_craft(recipe)
	)
	detail_box.add_child(craft)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(spacer)
	detail_box.add_child(_label("총기 부착물 장착은 이제 가방에서 총을 클릭해 진행합니다.", 15, Color("#88b9a5")))


func _selected_recipe() -> Dictionary:
	for recipe_raw in _recipes_for_category(selected_category):
		var recipe: Dictionary = recipe_raw
		if str(recipe.get("id", "")) == selected_recipe_id:
			return recipe
	return {}


func _recipes_for_category(category: String) -> Array:
	var recipes: Array = (RECIPES.get(category, []) as Array).duplicate(true)
	if category != "enhance":
		return recipes
	for mod_id in GameState.equipped_weapon_mods:
		var definition := WeaponSystem.get_mod(mod_id)
		if definition.is_empty():
			continue
		recipes.append({
			"id": "enhance_mod_%s" % mod_id,
			"name": "%s 영구 강화" % str(definition.get("display_name", mod_id)),
			"desc": "장착 파츠의 고유 보정치를 +99까지 영구 강화합니다.",
			"cost": {},
			"result": {"enhance_mod": mod_id},
		})
	return recipes


func _can_craft(recipe: Dictionary) -> bool:
	if GameState.shelter_tier < int(recipe.get("required_tier", 1)):
		return false
	if GameState.shelter_workbench_level < int(recipe.get("required_workbench", 1)):
		return false
	for key in _effective_cost(recipe).keys():
		if _owned_resource(str(key)) < int(_effective_cost(recipe)[key]):
			return false
	var result := recipe.get("result", {}) as Dictionary
	if bool(result.get("enhance", false)):
		return GameState.get_weapon_enhancement_level(GameState.equipped_weapon_id) < GameState.MAX_WEAPON_ENHANCEMENT
	if result.has("enhance_mod"):
		var mod_id := str(result["enhance_mod"])
		return GameState.equipped_weapon_mods.has(mod_id) and GameState.get_mod_enhancement_level(mod_id) < GameState.MAX_WEAPON_ENHANCEMENT
	return true


func _craft(recipe: Dictionary) -> void:
	if not _can_craft(recipe):
		return
	var result: Dictionary = recipe.get("result", {})
	if bool(result.get("artisan", false)):
		var artisan_result := GameState.roll_artisan_weapon()
		if not artisan_result.is_empty():
			selected_recipe_id = "artisan_roll"
		_refresh_after_change()
		return
	if bool(result.get("enhance", false)):
		GameState.try_enhance_weapon(GameState.equipped_weapon_id)
		_refresh_after_change()
		return
	if result.has("enhance_mod"):
		GameState.try_enhance_mod(str(result["enhance_mod"]))
		_refresh_after_change()
		return
	var cost: Dictionary = _effective_cost(recipe)
	for key in cost.keys():
		_consume_resource(str(key), int(cost[key]))
	if result.has("component"):
		GameState.add_mod_component(str(result["component"]), int(result.get("amount", 1)))
	elif result.has("weapon_mod"):
		GameState.add_weapon_mod(str(result["weapon_mod"]), int(result.get("amount", 1)))
	elif result.has("ammo"):
		var ammo_id := str(result["ammo"])
		GameState.set_ammo_count(ammo_id, GameState.get_ammo_count(ammo_id) + int(result.get("amount", 1)))
	elif result.has("weapon"):
		GameState.add_weapon(str(result["weapon"]), int(result.get("amount", 1)))
	elif result.has("canned_food"):
		GameState.canned_food += int(result["canned_food"])
	elif result.has("repair"):
		GameState.weapon_durability = minf(100.0, GameState.weapon_durability + float(result["repair"]))
	GameState.save_persistent_state()
	_refresh_after_change()


func _effective_cost(recipe: Dictionary) -> Dictionary:
	var result := recipe.get("result", {}) as Dictionary
	if bool(result.get("artisan", false)):
		return GameState.get_artisan_roll_cost()
	if bool(result.get("enhance", false)):
		return {"scrap": GameState.get_weapon_enhancement_cost(GameState.equipped_weapon_id)}
	if result.has("enhance_mod"):
		return {"scrap": GameState.get_mod_enhancement_cost(str(result["enhance_mod"]))}
	return (recipe.get("cost", {}) as Dictionary).duplicate(true)


func _start_repair() -> void:
	GameState.workbench_repair_active = true
	GameState.workbench_repair_weapon_id = GameState.equipped_weapon_id
	_refresh_after_change()


func _upgrade_workbench() -> void:
	GameState.try_upgrade_workbench()
	_refresh_after_change()


func _refresh_after_change() -> void:
	if resource_label:
		resource_label.text = _resource_text()
	_refresh_recipe_list()
	_refresh_detail_panel()


func _owned_resource(key: String) -> int:
	match key:
		"scrap":
			return GameState.scrap
		"rubber_gasket", "scope_lens", "magazine_spring":
			return GameState.get_mod_component_count(key)
		"canned_food":
			return GameState.canned_food
	return 0


func _consume_resource(key: String, amount: int) -> void:
	match key:
		"scrap":
			GameState.scrap = maxi(0, GameState.scrap - amount)
		"rubber_gasket", "scope_lens", "magazine_spring":
			GameState.mod_component_inventory[key] = maxi(0, GameState.get_mod_component_count(key) - amount)
		"canned_food":
			GameState.canned_food = maxi(0, GameState.canned_food - amount)


func _resource_text() -> String:
	return "고철 %d · 렌즈 %d · 고무 %d · 스프링 %d · 통조림 %d" % [
		GameState.scrap,
		GameState.get_mod_component_count("scope_lens"),
		GameState.get_mod_component_count("rubber_gasket"),
		GameState.get_mod_component_count("magazine_spring"),
		GameState.canned_food,
	]


func _cost_short_text(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	for key in _effective_cost(recipe).keys():
		parts.append("%s %d" % [_resource_name(str(key)), int(_effective_cost(recipe)[key])])
	return " / ".join(parts)


func _result_text(recipe: Dictionary) -> String:
	var result: Dictionary = recipe.get("result", {})
	if result.has("component"):
		return "%s x%d" % [_resource_name(str(result["component"])), int(result.get("amount", 1))]
	if result.has("weapon_mod"):
		var mod_id := str(result["weapon_mod"])
		return "%s x%d" % [
			str(WeaponSystem.get_mod(mod_id).get("display_name", mod_id)),
			int(result.get("amount", 1)),
		]
	if result.has("ammo"):
		return "%s x%d" % [_resource_name(str(result["ammo"])), int(result.get("amount", 1))]
	if result.has("weapon"):
		return "%s x%d" % [_resource_name(str(result["weapon"])), int(result.get("amount", 1))]
	if result.has("canned_food"):
		return "통조림 x%d" % int(result["canned_food"])
	if result.has("repair"):
		return "내구도 +%d%%" % int(result["repair"])
	if result.has("artisan"):
		return "현재 Tier 무기 1정"
	if result.has("enhance"):
		return "%s +1" % GameState.equipped_weapon_id.to_upper()
	if result.has("enhance_mod"):
		var mod_id := str(result["enhance_mod"])
		return "%s +%d" % [str(WeaponSystem.get_mod(mod_id).get("display_name", mod_id)), GameState.get_mod_enhancement_level(mod_id) + 1]
	return "-"


func _recipe_icon(recipe: Dictionary) -> Texture2D:
	var result: Dictionary = recipe.get("result", {})
	if result.has("weapon"):
		var weapon_texture := WEAPON_VISUAL_CATALOG.get_weapon_texture(str(result["weapon"]))
		return weapon_texture if weapon_texture != null else UI_ICONS.get_icon("weapon", 72, Color("#d5ddd8"))
	if result.has("ammo"):
		return AMMO_TEXTURE
	if result.has("component"):
		return _resource_icon(str(result["component"]))
	if result.has("weapon_mod"):
		return UI_ICONS.get_icon("mod", 72, Color("#e2a962"))
	if result.has("canned_food"):
		return UI_ICONS.get_icon("food", 72, Color("#e6b65c"))
	if result.has("repair"):
		return UI_ICONS.get_icon("repair", 72, Color("#82c7ba"))
	if result.has("artisan"):
		return UI_ICONS.get_icon("craft", 72, Color("#e2c06b"))
	if result.has("enhance"):
		return UI_ICONS.get_icon("upgrade", 72, Color("#e2c06b"))
	if result.has("enhance_mod"):
		return UI_ICONS.get_icon("mod", 72, Color("#e2a962"))
	return UI_ICONS.get_icon("all", 72, Color("#8ca29a"))


func _resource_icon(key: String) -> Texture2D:
	match key:
		"scope_lens": return SCOPE_LENS_TEXTURE
		"rubber_gasket": return RUBBER_GASKET_TEXTURE
		"magazine_spring": return MAGAZINE_SPRING_TEXTURE
		"762_fmj", "9mm_fmj", "12g_buckshot": return AMMO_TEXTURE
		"scrap": return UI_ICONS.get_icon("scrap", 48, Color("#b9c4c2"))
		"canned_food": return UI_ICONS.get_icon("food", 48, Color("#e6b65c"))
		"churu": return UI_ICONS.get_icon("churu", 48, Color("#e9a66e"))
	return UI_ICONS.get_icon("resource", 48, Color("#9ab4aa"))


func _resource_row(key: String, owned: int, needed: int, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = _resource_icon(key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := _label("%s  %d / %d" % [_resource_name(key), owned, needed], 17, color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


func _resource_name(key: String) -> String:
	match key:
		"scrap":
			return "고철"
		"scope_lens":
			return "스코프 렌즈"
		"rubber_gasket":
			return "고무 패킹"
		"magazine_spring":
			return "탄창 스프링"
		"762_fmj":
			return "7.62mm 보통탄"
		"9mm_fmj":
			return "9mm 보통탄"
		"12g_buckshot":
			return "12게이지 벅샷"
		"m1911":
			return "M1911 솜방망이"
		"mp5":
			return "MP5 하악이"
		"ak47":
			return "AK-47 캣라시니코프"
		"double_barrel":
			return "더블배럴 참치 헌터"
		"canned_food":
			return "통조림"
	return key


func _button(text: String, icon_name := "") -> Button:
	var button := Button.new()
	button.text = text
	if not icon_name.is_empty():
		button.icon = UI_ICONS.get_icon(icon_name, 30, Color("#dce6df"))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#e5ebe5"))
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.74, 0.72, 0.42))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.06, 0.07, 0.076, 0.72), Color(0.62, 0.74, 0.69, 0.28), 1, 7))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.11, 0.105, 0.86), Color("#d9c579"), 1, 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.13, 0.11, 0.065, 0.92), Color("#e0b75f"), 1, 7))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.035, 0.04, 0.044, 0.5), Color(0.45, 0.48, 0.48, 0.18), 1, 7))
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _section(text: String) -> Label:
	var label := _label(text, 18, Color("#d9ded8"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 3)
	return label


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_top = 8
	style.content_margin_right = 9
	style.content_margin_bottom = 8
	return style
