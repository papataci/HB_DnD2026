@tool
extends Area2D
class_name DropSublocation

@export var sublocation_data: SublocationData:
	set(value):
		sublocation_data = value
		_update_display()

@export var is_open: bool = true
@export var characters: Array[ENUMS.CHARACTERS] = []

## The Ink story/knot this sublocation currently starts from. Authored here
## (per DropSublocation instance) rather than on SublocationData, since this
## node is unique per sublocation and safe to mutate at runtime, unlike a
## shared Resource, which would leak changes to every reference to it.
@export var ink_story: Resource
@export var knot: String = ""

## Call this whenever gameplay should move this sublocation's story forward
## (e.g. after a quest step completes), so re-entering it resumes there.
func set_knot(new_knot: String, new_ink_story: Resource = null) -> void:
	knot = new_knot
	if new_ink_story:
		ink_story = new_ink_story

func _ready() -> void:
	_update_display()
	if not Engine.is_editor_hint():
		$DropZone.drop_applied.connect(_on_drop_applied)

func _on_drop_applied(zone: DropZone, area: Area2D, _plan: DropPlan) -> void:
	DropUtils.clear_occupant_reference(zone, area)
	get_tree().call_group(LocationManager.GROUP_NAME, "go_subloc", self, area)

func _update_display() -> void:
	var label := get_node_or_null("Label") as Label
	if label:
		label.text = get_display_name()

func get_display_name() -> String:
	return sublocation_data.sublocation_name if sublocation_data else ""
