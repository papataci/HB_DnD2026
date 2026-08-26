class_name ActionReturn extends DropAction

var previous_occupant: Area2D

func _init(p_previous_occupant: Area2D):
	previous_occupant = p_previous_occupant

func execute(zone: DropZone) -> void:
	DropUtils.clear_occupant_reference(zone, previous_occupant)

	var draggable = previous_occupant.get_meta("draggable")
	if draggable:
		draggable.return_home()
