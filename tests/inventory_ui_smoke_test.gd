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
	assert(ui.z_index >= 4000, "Inventory must render above the rest of the HUD.")
	assert(ui.inventory_panel.custom_minimum_size.x <= 560.0, "The default inventory panel must remain compact.")
	assert(not ui.weapon_panel.visible, "Weapon detail must stay hidden until the weapon is selected.")
	assert(ui.equipped_grid.get_child_count() == 7, "Equipment must not include the sewer extraction objective.")
	for equipment in ui.equipped_grid.get_children():
		assert(not (equipment as Button).text.contains("하수구"), "Extraction objectives do not belong in equipment.")
	for bag_item in ui.bag_grid.get_children():
		if bag_item is Button:
			assert((bag_item as Button).text.is_empty(), "Bag slots must show only an icon and quantity badge.")

	ui._show_weapon_detail()
	assert(ui.weapon_panel.visible, "Selecting the equipped weapon must open its detail panel.")
	assert(ui.weapon_panel.get_node_or_null("OwnedModList") == null, "Weapon details must not duplicate the bag attachment list.")

	var equipped_mods: Array = state.get("equipped_weapon_mods")
	equipped_mods.clear()
	var components: Dictionary = state.get("mod_component_inventory")
	components["scope_lens"] = 1
	state.set("scrap", 0)
	ui._refresh_contents()
	var scope_card := ui.bag_grid.get_node("BagItem_scope_2x") as Button
	assert(scope_card != null, "Owned attachments must be represented in the bag grid.")
	scope_card.pressed.emit()
	assert(ui.item_detail_title.text.contains("스코프"), "Selecting a bag item must reveal its details outside the slot.")
	assert(ui._can_install_mod("scope_2x"), "Owned attachments must be installable without paying scrap again.")
	ui.item_action_button.pressed.emit()
	assert((state.get("equipped_weapon_mods") as Array).has("scope_2x"), "Clicking an owned attachment must equip it.")
	assert(int(state.call("get_mod_component_count", "scope_lens")) == 0, "Equipping must remove the attachment from the bag.")

	ui._unequip_mod("scope_2x")
	assert(not (state.get("equipped_weapon_mods") as Array).has("scope_2x"), "Clicking an equipped attachment must remove it.")
	assert(int(state.call("get_mod_component_count", "scope_lens")) == 1, "Unequipping must return the attachment to the bag.")

	print("INVENTORY_UI_SMOKE: PASS")
	get_tree().quit()
