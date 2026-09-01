@tool
extends Area2D
class_name DropReturn

func _ready() -> void:
	if not Engine.is_editor_hint():
		$DropZone.drop_applied.connect(_on_drop_applied)

func _on_drop_applied(zone: DropZone, area: Area2D, _plan: DropPlan) -> void:
	DropUtils.clear_occupant_reference(zone, area)
	get_tree().call_group(LocationManager.GROUP_NAME, "go_location", area)
