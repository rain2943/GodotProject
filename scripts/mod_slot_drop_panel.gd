class_name ModSlotDropPanel
extends PanelContainer

var slot_name := ""
var workbench: Node


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var drop := data as Dictionary
	return (
		str(drop.get("kind", "")) == "weapon_mod"
		and str(drop.get("slot", "")) == slot_name
		and is_instance_valid(workbench)
		and workbench.has_method("can_install_mod")
		and bool(workbench.call("can_install_mod", str(drop.get("mod_id", ""))))
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var drop := data as Dictionary
	if is_instance_valid(workbench) and workbench.has_method("install_mod_from_drop"):
		workbench.call("install_mod_from_drop", str(drop.get("mod_id", "")))
