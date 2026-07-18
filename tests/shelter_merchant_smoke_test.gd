extends Node

const SHELTER_SCENE := preload("res://scenes/shelter_interior.tscn")
const MERCHANT_TEXTURE_PATH := "res://assets/characters/merchant_cat/merchant_down_left_idle.png"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var tree_root := get_tree().root
	var game_state := tree_root.get_node("GameState")
	game_state.call("reset_run")
	game_state.call("register_shelter_return")
	assert(bool(game_state.call("roll_merchant_visit", 1.0)), "A forced merchant visit must enter the waiting state.")
	assert(str(game_state.get("merchant_status")) == "waiting")
	var rolled_serial := int(game_state.get("merchant_last_roll_serial"))
	game_state.call("roll_merchant_visit", 0.0)
	assert(int(game_state.get("merchant_last_roll_serial")) == rolled_serial, "The same shelter return must not roll twice.")

	var shelter := SHELTER_SCENE.instantiate() as Node3D
	tree_root.add_child(shelter)
	await get_tree().process_frame
	await get_tree().physics_frame
	var waiting_marker := shelter.get_node_or_null("MerchantWaitingBubble") as Node3D
	assert(waiting_marker != null, "A waiting merchant needs a sewer dialogue marker.")
	var face := waiting_marker.get_node("MerchantFace") as Sprite3D
	assert(face.texture is AtlasTexture)
	assert((face.texture as AtlasTexture).atlas.resource_path == MERCHANT_TEXTURE_PATH)
	assert((waiting_marker.get_node("MerchantKnockLine") as Label3D).text.contains("문 좀 열어"))

	shelter.call("_open_merchant_arrival_dialog")
	assert(tree_root.find_child("MerchantArrivalLayer", true, false) != null)
	shelter.call("_accept_merchant")
	await get_tree().process_frame
	assert(str(game_state.get("merchant_status")) == "inside")
	assert(get_tree().get_nodes_in_group("shelter_merchant").size() == 1)
	var merchant := get_tree().get_nodes_in_group("shelter_merchant")[0] as Node3D
	var sprite := merchant.get_node("MerchantSprite") as AnimatedSprite3D
	assert(sprite.sprite_frames.get_frame_count("idle_down_left") == 4)

	game_state.set("scrap", 500)
	var ammo_before := int(game_state.call("get_ammo_count", "762_fmj"))
	shelter.call("_open_merchant_shop")
	await get_tree().process_frame
	var shop_list := shelter.get("merchant_shop_list") as VBoxContainer
	var ammo_buy_button := shop_list.get_node("MerchantGood_762_fmj") as Button
	assert(ammo_buy_button != null and not ammo_buy_button.disabled)
	ammo_buy_button.pressed.emit()
	await get_tree().process_frame
	assert(int(game_state.call("get_ammo_count", "762_fmj")) == ammo_before + 30)
	assert(int(game_state.get("scrap")) == 458)

	shelter.call("_set_merchant_shop_mode", "sell")
	await get_tree().process_frame
	shop_list = shelter.get("merchant_shop_list") as VBoxContainer
	var ammo_sell_button := shop_list.get_node("MerchantGood_762_fmj") as Button
	ammo_sell_button.pressed.emit()
	await get_tree().process_frame
	assert(int(game_state.call("get_ammo_count", "762_fmj")) == ammo_before)
	assert(int(game_state.get("scrap")) == 474)

	print("SHELTER_MERCHANT_OK waiting=true accepted=true idle_frames=4 trade=true")
	get_tree().quit(0)
