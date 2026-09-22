@tool
extends Node2D
class_name DroppableFeedback
## Sits under a room's DropSublocation portal (e.g. Morlako/Room01/
## DroppableFeedback) and shows its Polygon2D, in active_color, while any
## compatible draggable is being dragged, anywhere - not just when hovering
## this zone - so the player can see every valid drop target as soon as they
## pick one up. Hidden the rest of the time.

## Color/alpha the polygon takes while a compatible draggable is being dragged.
@export var active_color: Color = Color("2baeff8b")

var _polygon: Polygon2D
var _zone: DropZone

func _ready() -> void:
	set_process(false)
	_polygon = get_node_or_null("Polygon2D")
	if Engine.is_editor_hint():
		return
	if not _polygon:
		push_warning("DroppableFeedback (%s): no Polygon2D child found, nothing to highlight" % get_path())
		return
	_polygon.color = active_color
	_polygon.hide()

	var portal := DropSublocation.find_owner(self)
	_zone = portal.get_node_or_null("DropZone") if portal else null
	if not _zone:
		push_error("DroppableFeedback: no DropSublocation ancestor found")
		return
	set_process(true)

func _process(_delta: float) -> void:
	_polygon.visible = _compatible_drag_in_progress()

func _compatible_drag_in_progress() -> bool:
	for node in get_tree().get_nodes_in_group(Draggable.GROUP_NAME):
		var draggable := node as Draggable
		if draggable and draggable.state == Draggable.DRAGGABLE_STATE.DRAGGING \
				and DropUtils.is_area_type_accepted(_zone, draggable.a):
			return true
	return false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not has_node("Polygon2D"):
		warnings.append("This node has no Polygon2D child, so it has nothing to highlight.")
	return warnings
