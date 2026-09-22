@tool
extends Area2D
class_name DropSublocation
## A portal: dropping a character on it enters `target`. It carries nothing
## but that id - the template comes from Sublocations.all() and the live
## state from WorldState - so a portal can sit anywhere (on the map, or inside
## another sublocation's scene as its door) and be freed and rebuilt at will
## without anything being lost.

@export var target: ENUMS.SUBLOCATIONS:
	set(value):
		target = value
		_update_display()

func _ready() -> void:
	_update_display()
	if not Engine.is_editor_hint():
		$DropZone.drop_applied.connect(_on_drop_applied)

## Walks up from `node` to the DropSublocation portal it's part of (e.g. a
## CharBubble or DroppableFeedback child of it), or null. Mirrors
## SublocManager.find_owner().
static func find_owner(node: Node) -> DropSublocation:
	var current := node
	while current:
		if current is DropSublocation:
			return current
		current = current.get_parent()
	return null

func _on_drop_applied(zone: DropZone, area: Area2D, _plan: DropPlan) -> void:
	DropUtils.clear_occupant_reference(zone, area)
	get_tree().call_group(LocationManager.GROUP_NAME, "go_subloc", target, area)

func _update_display() -> void:
	var label := get_node_or_null("Label") as Label
	if label:
		label.text = get_display_name()

func get_display_name() -> String:
	return Sublocations.display_name(target)
