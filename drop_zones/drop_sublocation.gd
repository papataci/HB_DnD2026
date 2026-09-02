@tool
extends Area2D
class_name DropSublocation

## Lets LocationManager.find_subloc() locate a currently-instanced
## DropSublocation by its SublocationData id (e.g. for the "@TELEPORT:"
## ink command), regardless of where it's nested in the scene tree.
const GROUP_NAME := &"drop_sublocation"

@export var sublocation_data: SublocationData:
	set(value):
		sublocation_data = value
		_update_display()

@export var is_open: bool = true
@export var characters: Array[ENUMS.CHARACTERS] = []

## The Ink story/knot this sublocation currently starts from. Live, mutable
## state, seeded from SublocationData.starting_ink_story/starting_knot the
## first time this instance is ready (see _apply_initial_ink()) but held here
## per DropSublocation instance rather than on SublocationData, since this
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
	_apply_initial_characters()
	_apply_initial_ink()
	_update_display()
	if not Engine.is_editor_hint():
		add_to_group(GROUP_NAME)
		$DropZone.drop_applied.connect(_on_drop_applied)

## Seeds this instance's live characters list from the shared SublocationData
## template the first time it's ready, without touching `characters` again
## afterwards, so runtime drops/removals stay local to this instance instead
## of leaking into the shared resource (see the class-level comment on
## `ink_story`/`knot` above for why per-instance state can't live there).
func _apply_initial_characters() -> void:
	if not characters.is_empty():
		return
	if sublocation_data:
		characters = sublocation_data.starting_characters.duplicate()

## Seeds this instance's live ink_story/knot from the shared SublocationData
## template the first time it's ready, without touching them again afterwards
## (call set_knot() to move the story forward at runtime instead).
func _apply_initial_ink() -> void:
	if ink_story:
		return
	if sublocation_data and sublocation_data.starting_ink_story:
		ink_story = sublocation_data.starting_ink_story
		knot = sublocation_data.starting_knot

func _on_drop_applied(zone: DropZone, area: Area2D, _plan: DropPlan) -> void:
	DropUtils.clear_occupant_reference(zone, area)
	get_tree().call_group(LocationManager.GROUP_NAME, "go_subloc", self, area)

func _update_display() -> void:
	var label := get_node_or_null("Label") as Label
	if label:
		label.text = get_display_name()

func get_display_name() -> String:
	return sublocation_data.sublocation_name if sublocation_data else ""
