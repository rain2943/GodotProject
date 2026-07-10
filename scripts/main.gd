extends Control

func _ready() -> void:
	var status := get_node("Center/Stack/Status") as Label
	status.text = "Godot Web preview is live | " + OS.get_name()
