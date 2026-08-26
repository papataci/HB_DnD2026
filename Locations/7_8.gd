extends Control

func _ready() -> void:
	if Location.curr_subloc.subloc_name == "Room07" or Location.curr_subloc.subloc_name == "Room08":
		visible = true
	else:
		visible = false
