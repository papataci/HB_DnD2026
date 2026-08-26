extends Control

func _ready() -> void:
	if Location.curr_subloc.subloc_name == "Room01" or Location.curr_subloc.subloc_name == "Room02":
		visible = true
	else:
		visible = false
