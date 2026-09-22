extends Node
class_name LocationManager
## Navigation between the map and its sublocations. The only state here is
## `_path`: the ids we've entered, outermost first - empty means "on the map",
## [ROOM01, ROOM_INT_01] means "inside Room 01's interior". Every transition
## edits the path and re-renders whatever is on top. All scene nodes involved
## are disposable; everything that must survive (rosters, story progress)
## lives in WorldState.

const GROUP_NAME := &"location_manager"
const CHARACTER_SCENE := preload("res://draggables/character.tscn")
const CHARACTER_SPACING := 200.0
const InkScene := preload("res://ink/ink_example.tscn")

## Which ENUMS.LOCATIONS this manager navigates - the same role subloc_id
## plays for SublocManager. Used to look up this location's own story/knot in
## WorldState (see teleport_to_location()).
@export var location: ENUMS.LOCATIONS = ENUMS.LOCATIONS.MORLAKO

@export var fader: ColorRect
@export var container: Node
@export var characters_container: Node2D
@export var subloc_scene: PackedScene = preload("res://scenes/subloc_manager.tscn")

var _path: Array[int] = []
var _subloc_instance: SublocManager

func _ready() -> void:
	add_to_group(GROUP_NAME)
	# Deferred so sibling nodes the spawned characters look up (CharacterInit)
	# have had their own _ready() first.
	_render.call_deferred()

## The sublocation currently shown, or WorldState.MAP when on the map.
func current_subloc() -> int:
	return _path.back() if not _path.is_empty() else WorldState.MAP

func is_character_present(character: ENUMS.CHARACTERS) -> bool:
	return WorldState.is_character_at(current_subloc(), character)

## Enters `target` from wherever we are (a character dropped on a portal, see
## DropSublocation). `character` is the dropped Character node, if any; it
## moves from the current roster into `target`'s.
func go_subloc(target: int, character: Node = null) -> void:
	await fader.fade_out().finished

	var dropped := character as Character
	if dropped:
		WorldState.move_character(dropped.character, current_subloc(), target)
		_discard_dropped(dropped)

	_path.push_back(target)
	_render()

	await fader.fade_in().finished

## Steps back out one level (the back arrow, see DropReturn): to the
## enclosing sublocation, or to the map from a top-level one.
func go_location(character: Node = null) -> void:
	if _path.is_empty():
		return
	await fader.fade_out().finished

	var leaving: int = _path.pop_back()
	var returning := character as Character
	if returning:
		WorldState.move_character(returning.character, leaving, current_subloc())
		_discard_dropped(returning)

	_render()

	await fader.fade_in().finished

## "@TELEPORT: <sublocation>": moves every playable character present into
## `target` and shows it as a fresh top-level entry, so the back arrow leads
## to the map.
func teleport_to_subloc(target: int) -> void:
	await fader.fade_out().finished

	WorldState.move_playable_characters(current_subloc(), target)
	_path.clear()
	_path.push_back(target)
	_render()

	await fader.fade_in().finished

## "@TELEPORT: <location>": every playable character back to the map, fully
## exiting however deep we are. If that was the last unresolved room, plays
## this location's own story (WorldState.get_location_state(location)) once
## the map is back on screen.
func teleport_to_location() -> void:
	if _path.is_empty():
		return
	await fader.fade_out().finished

	WorldState.move_playable_characters(current_subloc(), WorldState.MAP)
	_path.clear()
	_render()

	await fader.fade_in().finished

	if WorldState.all_resolved():
		await _play_location_story()

## Plays this location's story from wherever WorldState says it should
## resume (a no-op if it has none), on top of whatever's on screen, and frees
## itself when the story ends. SELF in a command it contains resolves to this
## location (see ink_starter.gd's location_id).
func _play_location_story() -> void:
	var state := WorldState.get_location_state(location)
	if not state or not state.story:
		return

	var ink := InkScene.instantiate()
	ink.ink_file = state.story
	ink.location_id = location
	# "" (never set) means resume from InkCommands.DEFAULT_KNOT - same
	# convention as SublocManager._start_ink_story().
	ink.start_knot = state.knot if not state.knot.is_empty() else InkCommands.DEFAULT_KNOT
	get_tree().root.add_child(ink)
	await ink.story_ended
	ink.queue_free()

## Rebuilds the view for the top of `_path`: the map's roster, or a
## SublocManager configured for the current sublocation plus its roster.
func _render() -> void:
	if _path.is_empty():
		if _subloc_instance:
			_subloc_instance.queue_free()
			_subloc_instance = null
		_render_characters(WorldState.characters_at(WorldState.MAP))
		return

	if not _subloc_instance:
		_subloc_instance = subloc_scene.instantiate()
		container.add_child(_subloc_instance)
	_subloc_instance.configure(_path.back())
	_render_characters(WorldState.characters_at(_path.back()))

func _render_characters(roster: Array[ENUMS.CHARACTERS]) -> void:
	if not characters_container:
		return
	for child in characters_container.get_children():
		child.queue_free()
	var playable := roster.filter(Character.is_playable)
	for i in playable.size():
		var present_character := CHARACTER_SCENE.instantiate() as Character
		present_character.character = playable[i]
		present_character.position = Vector2(0, -i * CHARACTER_SPACING)
		characters_container.add_child(present_character)

## DropZone reparents a dropped Area2D onto itself before drop_applied even
## fires (see DropZone._attach()), so the node would keep rendering under the
## portal until its queue_free() is processed: detach it now. The roster it
## belongs to is re-rendered from WorldState by _render() anyway.
func _discard_dropped(dropped: Character) -> void:
	var parent := dropped.get_parent()
	if parent:
		parent.remove_child(dropped)
	dropped.queue_free()
