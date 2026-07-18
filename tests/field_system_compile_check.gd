extends SceneTree


const SCRIPTS := [
	"res://scripts/main.gd",
	"res://scripts/game_state.gd",
	"res://scripts/inventory_ui.gd",
	"res://scripts/rescued_cat_follower.gd",
	"res://scripts/mod_chip_button.gd",
	"res://scripts/mod_slot_drop_panel.gd",
	"res://scripts/shelter_workbench_module.gd",
	"res://scripts/scratcher_bank_module.gd",
	"res://scripts/catnip_scraper_module.gd",
	"res://scripts/shelter_resident_cat.gd",
	"res://scripts/shelter_interior.gd",
	"res://scripts/tactical_map.gd",
]


func _initialize() -> void:
	for script_path in SCRIPTS:
		var script_resource := load(script_path) as Script
		if script_resource == null or not script_resource.can_instantiate():
			push_error("FIELD_SYSTEM_COMPILE: failed to load %s" % script_path)
			quit(1)
			return
	print("FIELD_SYSTEM_COMPILE: PASS")
	quit(0)
