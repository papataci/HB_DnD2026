extends Node
## Every piece of sublocation state that changes during play, keyed by
## ENUMS.SUBLOCATIONS id - which story/knot a room resumes from, who is in it,
## whether it's open - plus the roster of the top-level map itself (MAP).
##
## This is the *only* owner of that state. Scene nodes (portals, the
## SublocManager, room content) are disposable views: they read from here when
## they're built and write back through the methods below, and none of them
## keep a copy. That's what makes "re-enter the room later and it remembers"
## hold regardless of whether the room's nodes survived in between, and it's
## what a future save/load would serialize.
##
## Seeded from the authored templates (Sublocations.all() and
## _globals/init.tres) in _ready(); call reset() to start over.

## Pseudo-id for the top-level location's own roster (characters standing on
## the map, not inside any sublocation). Never a real ENUMS.SUBLOCATIONS value.
const MAP := -1

const INIT_DATA: InitData = preload("res://_globals/init.tres")

class SublocState:
	## Compiled ink (.ink.json) this sublocation plays, or null for none.
	var story: Resource
	## Knot to resume `story` from; "" means the start of the file.
	var knot: String = ""
	var characters: Array[ENUMS.CHARACTERS] = []
	var is_open: bool = true

var map_characters: Array[ENUMS.CHARACTERS] = []
var _sublocs: Dictionary[int, SublocState] = {}

func _ready() -> void:
	reset()

## Rebuilds all state from the authored templates.
func reset() -> void:
	map_characters = INIT_DATA.starting_characters.duplicate()
	_sublocs.clear()
	var templates := Sublocations.all()
	for id in templates:
		var template: SublocationData = templates[id]
		var state := SublocState.new()
		state.story = template.starting_ink_story
		state.knot = template.starting_knot
		state.characters = template.starting_characters.duplicate()
		state.is_open = template.starting_open
		_sublocs[id] = state

func get_state(id: int) -> SublocState:
	var state: SublocState = _sublocs.get(id)
	if not state:
		push_error("WorldState: no state for sublocation %s" % Sublocations.key_name(id))
	return state

## Points `id` at `knot` - of `story`, or of whatever story it already has
## when `story` is null - so the next time it's entered the ink resumes there.
func set_story(id: int, knot: String, story: Resource = null) -> void:
	var state := get_state(id)
	if not state:
		return
	if story:
		state.story = story
	state.knot = knot
	if not state.story and not knot.is_empty():
		push_warning("WorldState: %s now has knot \"%s\" but no ink story to play it from" % [Sublocations.key_name(id), knot])

func set_open(id: int, open: bool) -> void:
	var state := get_state(id)
	if state:
		state.is_open = open

## Roster helpers. `where` is a sublocation id or MAP. The returned array is
## the live roster, not a copy.
func characters_at(where: int) -> Array[ENUMS.CHARACTERS]:
	if where == MAP:
		return map_characters
	var state := get_state(where)
	if state:
		return state.characters
	var none: Array[ENUMS.CHARACTERS] = []
	return none

func is_character_at(where: int, character: ENUMS.CHARACTERS) -> bool:
	return character in characters_at(where)

func add_character(where: int, character: ENUMS.CHARACTERS) -> void:
	var roster := characters_at(where)
	if character not in roster:
		roster.append(character)

func remove_character(where: int, character: ENUMS.CHARACTERS) -> void:
	characters_at(where).erase(character)

func move_character(character: ENUMS.CHARACTERS, from: int, to: int) -> void:
	remove_character(from, character)
	add_character(to, character)

## Moves every *playable* character from `from` to `to`. Non-playable NPCs
## (a room's fixture, e.g. Toshiro) stay where they were authored.
func move_playable_characters(from: int, to: int) -> void:
	for character in characters_at(from).filter(Character.is_playable):
		move_character(character, from, to)
