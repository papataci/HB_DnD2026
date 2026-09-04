extends Node2D
class_name SublocManager
## Renders one sublocation: swaps its scene content in and starts its ink
## story from wherever WorldState says it should resume. Owns nothing
## persistent - LocationManager tells it which id to show and it rebuilds
## from the template + WorldState every time, so re-showing a room is always
## a clean rebuild.

const InkScene := preload("res://ink/ink_example.tscn")

## The sublocation being shown (WorldState.MAP until configure() is called).
var subloc_id: int = WorldState.MAP
var template: SublocationData
var _ink_instance: Node

## Walks up from `node` to the SublocManager rendering it, or null. For room
## content that needs to know which sublocation it's part of (see
## sublocation/backgrounds/room_door_open.gd).
static func find_owner(node: Node) -> SublocManager:
	var current := node
	while current:
		if current is SublocManager:
			return current
		current = current.get_parent()
	return null

func configure(id: int) -> void:
	subloc_id = id
	template = Sublocations.template(id)
	if not template:
		return
	print("SublocManager: showing %s" % Sublocations.key_name(id))

	var title := get_node_or_null("DEBUG/Title") as Label
	if title:
		title.text = template.sublocation_name

	_load_subloc_scene(template.sublocation_scene)
	_start_ink_story(id)

func _load_subloc_scene(scene: PackedScene) -> void:
	var subloc_scene := get_node_or_null("SublocScene") as Node2D
	if not subloc_scene:
		return

	for child in subloc_scene.get_children():
		child.queue_free()

	if scene:
		subloc_scene.add_child(scene.instantiate())

func _start_ink_story(id: int) -> void:
	if _ink_instance:
		_ink_instance.queue_free()
		_ink_instance = null

	var state := WorldState.get_state(id)
	if not state or not state.story:
		return

	var ink := InkScene.instantiate()
	ink.ink_file = state.story
	# "" (never set, or explicitly reset via "@SET_KNOT: ... -") means resume
	# from InkCommands.DEFAULT_KNOT - see its doc comment for why that
	# fallback lives here and not in ink_starter.gd.
	ink.start_knot = state.knot if not state.knot.is_empty() else InkCommands.DEFAULT_KNOT
	ink.subloc_id = id
	add_child(ink)
	_ink_instance = ink

	var execute := get_node_or_null("Sentence/Execute")
	if execute and "story_manager" in execute:
		execute.story_manager = ink
