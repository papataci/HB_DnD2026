@tool
extends Area2D
class_name DropSublocation

@export var sublocation_data: SublocationData:
	set(value):
		sublocation_data = value
		_update_display()

func _ready() -> void:
	_update_display()
	if not Engine.is_editor_hint():
		$DropZone.drop_applied.connect(_on_drop_applied)

func _on_drop_applied(_zone: DropZone, _area: Area2D, _plan: DropPlan) -> void:
	get_tree().call_group(LocationManager.GROUP_NAME, "go_subloc", self)

func _update_display() -> void:
	var label := get_node_or_null("Label") as Label
	if label:
		label.text = get_display_name()

func get_display_name() -> String:
	return sublocation_data.sublocation_name if sublocation_data else ""
