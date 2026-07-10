extends Control

func _ready() -> void:
	var status := get_node("Center/Stack/Status") as Label
	status.text = "Pipeline ready | " + OS.get_name()
