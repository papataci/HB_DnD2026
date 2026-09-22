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
	## Knot to resume `story` from; "" resolves to InkCommands.DEFAULT_KNOT
	## ("Start") when the story is actually played (SublocManager).
	var knot: String = ""
	var characters: Array[ENUMS.CHARACTERS] = []
	var is_open: bool = true
	var is_unresolved: bool = false

class LocationState:
	## Compiled ink (.ink.json) this location plays, or null for none.
	var story: Resource
	## Knot to resume `story` from; "" resolves to InkCommands.DEFAULT_KNOT
	## ("Start") when the story is actually played (LocationManager).
	var knot: String = ""

## Fires whenever the roster at `where` (a sublocation id, or MAP) changes,
## so disposable views - e.g. a DropSublocation portal showing who's inside -
## can refresh without polling.
signal roster_changed(where: int)
## Fires whenever a room's "Unresolved" flag (id resolved through
## Sublocations.room_group()) changes.
signal unresolved_changed(where: int)

var map_characters: Array[ENUMS.CHARACTERS] = []
## Keyed by Sublocations.key_name(id) (e.g. "ROOM08"), not the raw
## ENUMS.SUBLOCATIONS int, purely so this dictionary reads as names instead
## of bare numbers when inspected live (Godot's remote debugger, a print of
## this node, etc.). Every method below still takes/returns the int id -
## that's the type-safe, typo-proof identity used everywhere else in the
## codebase (DropSublocation.target's Inspector dropdown, ink command
## resolution, LocationManager's nav path...) - this is purely an internal
## storage detail, not a second identity system.
var _sublocs: Dictionary[String, SublocState] = {}
## Keyed by Locations.key_name(id), same reasoning as _sublocs.
var _locations: Dictionary[String, LocationState] = {}

func _ready() -> void:
	reset()

## Rebuilds all state from the authored templates.
func reset() -> void:
	map_characters = INIT_DATA.starting_characters.duplicate()
	_sublocs.clear()

	_locations.clear()
	for id in Locations.all():
		var location_template: LocationData = Locations.all()[id]
		var location_state := LocationState.new()
		location_state.story = location_template.starting_ink_story
		location_state.knot = location_template.starting_knot
		_locations[Locations.key_name(id)] = location_state

	var templates := Sublocations.all()

	# Story/knot are per-exact-id, so every id gets its own state.
	for id in templates:
		_sublocs[Sublocations.key_name(id)] = SublocState.new()

	for id in templates:
		var template: SublocationData = templates[id]
		var state: SublocState = _sublocs[Sublocations.key_name(id)]
		state.story = template.starting_ink_story
		state.knot = template.starting_knot

		# Open/unresolved/characters are per room-group: seed into whichever
		# id owns the group, regardless of whether they were authored on the
		# exterior or interior template (e.g. Toshiro's starting_characters is
		# authored on room_int_01.tres, but should end up in ROOM01's group -
		# and "SELF" in a room's own ink, like toshiro_00.ink's @CLOSE:, is
		# that same interior id, so it needs to land in the same bucket the
		# exterior door sprite reads).
		var group_state: SublocState = _sublocs[Sublocations.key_name(Sublocations.room_group(id))]
		if not template.starting_open:
			group_state.is_open = false
		if template.starting_unresolved:
			group_state.is_unresolved = true
		for character in template.starting_characters:
			if character not in group_state.characters:
				group_state.characters.append(character)

func get_state(id: int) -> SublocState:
	var state: SublocState = _sublocs.get(Sublocations.key_name(id))
	if not state:
		push_error("WorldState: no state for sublocation %s" % Sublocations.key_name(id))
	return state

func get_location_state(id: int) -> LocationState:
	var state: LocationState = _locations.get(Locations.key_name(id))
	if not state:
		push_error("WorldState: no state for location %s" % Locations.key_name(id))
	return state

## Points `id` at `knot` - of `story`, or of whatever story it already has
## when `story` is null - same as set_story(), but for a location rather than
## a sublocation (see LocationManager, which plays it once all_resolved()).
func set_location_story(id: int, knot: String, story: Resource = null) -> void:
	var state := get_location_state(id)
	if not state:
		return
	if story:
		state.story = story
	state.knot = knot
	if not state.story and not knot.is_empty():
		push_warning("WorldState: %s now has knot \"%s\" but no ink story to play it from" % [Locations.key_name(id), knot])

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

## Whether the room `where` (resolved through Sublocations.room_group(), like
## the roster and the "Unresolved" flag) is open.
func is_open(where: int) -> bool:
	var state := get_state(Sublocations.room_group(where))
	return state.is_open if state else false

func set_open(where: int, open: bool) -> void:
	var state := get_state(Sublocations.room_group(where))
	if state:
		state.is_open = open

## Whether the room `where` (resolved through Sublocations.room_group(), like
## the roster) is flagged "Unresolved".
func is_unresolved(where: int) -> bool:
	var state := get_state(Sublocations.room_group(where))
	return state.is_unresolved if state else false

func set_unresolved(where: int, unresolved: bool) -> void:
	var group := Sublocations.room_group(where)
	var state := get_state(group)
	if state and state.is_unresolved != unresolved:
		state.is_unresolved = unresolved
		unresolved_changed.emit(group)

## True when no registered sublocation is flagged "Unresolved" - e.g. gates
## whole-map story beats like ink/time_scheduler.ink once every room's quest
## is done. Safe to scan every bucket directly (not just room-group leaders):
## the flag is only ever written into a group's own bucket (see reset() and
## set_unresolved()), so a non-leader id's bucket always reads false.
func all_resolved() -> bool:
	for key in _sublocs:
		if _sublocs[key].is_unresolved:
			return false
	return true

## Roster helpers. `where` is a sublocation id or MAP; a room's exterior and
## interior share one roster (see Sublocations.room_group()). The returned
## array is the live roster, not a copy.
func characters_at(where: int) -> Array[ENUMS.CHARACTERS]:
	var group := where if where == MAP else Sublocations.room_group(where)
	if group == MAP:
		return map_characters
	var state := get_state(group)
	if state:
		return state.characters
	var none: Array[ENUMS.CHARACTERS] = []
	return none

func is_character_at(where: int, character: ENUMS.CHARACTERS) -> bool:
	return character in characters_at(where)

func add_character(where: int, character: ENUMS.CHARACTERS) -> void:
	var group := where if where == MAP else Sublocations.room_group(where)
	var roster := characters_at(group)
	if character not in roster:
		roster.append(character)
		roster_changed.emit(group)

func remove_character(where: int, character: ENUMS.CHARACTERS) -> void:
	var group := where if where == MAP else Sublocations.room_group(where)
	var roster := characters_at(group)
	if roster.has(character):
		roster.erase(character)
		roster_changed.emit(group)

func move_character(character: ENUMS.CHARACTERS, from: int, to: int) -> void:
	remove_character(from, character)
	add_character(to, character)

## Moves every *playable* character from `from` to `to`. Non-playable NPCs
## (a room's fixture, e.g. Toshiro) stay where they were authored.
func move_playable_characters(from: int, to: int) -> void:
	for character in characters_at(from).filter(Character.is_playable):
		move_character(character, from, to)
