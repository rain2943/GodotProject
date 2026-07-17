extends Node

const INVENTORY_UI := preload("res://scripts/inventory_ui.gd")
const FONT := preload("res://assets/fonts/Pretendard-Regular.otf")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var tree_root := get_tree().root
	var state := tree_root.get_node_or_null("GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		tree_root.add_child(state)
	var ui := INVENTORY_UI.new()
	add_child(ui)
	ui.setup(FONT, null, null, {})
	ui.update_state(true, 30, 90, "AK-47 \"캣라시니코프\"", 30, 100.0)
	ui.set_open(true)
	assert(not ui.weapon_panel.visible, "Weapon detail must stay hidden until the weapon is selected.")

	ui._show_weapon_detail()
	assert(ui.weapon_panel.visible, "Selecting the equipped weapon must open its detail panel.")

	var equipped_mods: Array = state.get("equipped_weapon_mods")
	equipped_mods.clear()
	var components: Dictionary = state.get("mod_component_inventory")
	components["scope_lens"] = 1
	state.set("scrap", 0)
	assert(ui._can_install_mod("scope_2x"), "Owned attachments must be installable without paying scrap again.")
	ui._install_mod("scope_2x")
	assert((state.get("equipped_weapon_mods") as Array).has("scope_2x"), "Clicking an owned attachment must equip it.")
	assert(int(state.call("get_mod_component_count", "scope_lens")) == 0, "Equipping must remove the attachment from the bag.")

	ui._unequip_mod("scope_2x")
	assert(not (state.get("equipped_weapon_mods") as Array).has("scope_2x"), "Clicking an equipped attachment must remove it.")
	assert(int(state.call("get_mod_component_count", "scope_lens")) == 1, "Unequipping must return the attachment to the bag.")

	print("INVENTORY_UI_SMOKE: PASS")
	get_tree().quit()
