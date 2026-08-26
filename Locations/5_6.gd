extends Control

func _ready() -> void:
	if Location.curr_subloc.subloc_name == "Room05" or Location.curr_subloc.subloc_name == "Room06":
		visible = true
	else:
		visible = false
