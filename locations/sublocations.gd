class_name Sublocations
## Static registry of every sublocation's authored template, keyed by its
## ENUMS.SUBLOCATIONS id. The key *is* the identity: the same enum value is
## what a portal (drop_zones/drop_sublocation.gd) targets, what WorldState
## keeps runtime state under, and what ink names (e.g. "@TELEPORT: room01").
## Nothing else - no numeric id inside the .tres, no node name, no scene-tree
## search - so adding a room means adding one line here and nothing to keep
## in sync.
##
## Templates are immutable at runtime; anything that changes during play
## lives in WorldState. Plain static class (not an autoload) so @tool scripts
## like the portal can read it in the editor too.
##
## Paths rather than preload()s, loaded on first use: a template carries its
## PackedScene, whose content references scripts that reference this class
## again, so loading them while this script is still being parsed would be a
## cyclic load.

const TEMPLATE_PATHS: Dictionary[int, String] = {
	ENUMS.SUBLOCATIONS.RECEPTION: "res://sublocation/data/reception.tres",
	ENUMS.SUBLOCATIONS.ROOM01: "res://sublocation/data/room01.tres",
	ENUMS.SUBLOCATIONS.ROOM02: "res://sublocation/data/room02.tres",
	ENUMS.SUBLOCATIONS.ROOM05: "res://sublocation/data/room05.tres",
	ENUMS.SUBLOCATIONS.ROOM06: "res://sublocation/data/room06.tres",
	ENUMS.SUBLOCATIONS.ROOM07: "res://sublocation/data/room07.tres",
	ENUMS.SUBLOCATIONS.ROOM08: "res://sublocation/data/room08.tres",
	ENUMS.SUBLOCATIONS.ROOM09: "res://sublocation/data/room09.tres",
	ENUMS.SUBLOCATIONS.ROOMX: "res://sublocation/data/roomx.tres",
	ENUMS.SUBLOCATIONS.SHACK: "res://sublocation/data/shack.tres",
	ENUMS.SUBLOCATIONS.PHONEBOOT: "res://sublocation/data/phoneboot.tres",
	ENUMS.SUBLOCATIONS.DUMPSTER: "res://sublocation/data/dumpster.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_01: "res://sublocation/data/room_int_01.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_02: "res://sublocation/data/room_int_02.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_05: "res://sublocation/data/room_int_05.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_06: "res://sublocation/data/room_int_06.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_07: "res://sublocation/data/room_int_07.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_08: "res://sublocation/data/room_int_08.tres",
	ENUMS.SUBLOCATIONS.ROOM_INT_09: "res://sublocation/data/room_int_09.tres",
	ENUMS.SUBLOCATIONS.RECEPTION_INT: "res://sublocation/data/reception_int.tres",
}

static var _templates: Dictionary[int, SublocationData] = {}

## Every registered template by id, loading them the first time it's called.
static func all() -> Dictionary[int, SublocationData]:
	if _templates.is_empty():
		for id in TEMPLATE_PATHS:
			var loaded := load(TEMPLATE_PATHS[id]) as SublocationData
			if loaded:
				_templates[id] = loaded
			else:
				push_error("Sublocations: %s is not a SublocationData" % TEMPLATE_PATHS[id])
	return _templates

## The template for `id`, or null (with an error) if none is registered.
static func template(id: int) -> SublocationData:
	var found: SublocationData = all().get(id)
	if not found:
		push_error("Sublocations: no template registered for %s" % key_name(id))
	return found

## Resolves an ink-facing name - an ENUMS.SUBLOCATIONS key, case-insensitive,
## e.g. "room01" or "ROOM_INT_01" - to its id, or -1 if unknown.
static func parse_key(name: String) -> int:
	var key := name.strip_edges().to_upper()
	if ENUMS.SUBLOCATIONS.has(key):
		return ENUMS.SUBLOCATIONS[key]
	return -1

## The ENUMS.SUBLOCATIONS key for `id` (e.g. "ROOM01"), for messages.
static func key_name(id: int) -> String:
	var key = ENUMS.SUBLOCATIONS.find_key(id)
	return str(key) if key != null else "<unknown %d>" % id

## The authored display name for `id`, falling back to its key.
static func display_name(id: int) -> String:
	var found: SublocationData = all().get(id)
	return found.sublocation_name if found else key_name(id)

## Resolves `id` to the id that owns its WorldState roster: itself, unless
## `id` is the "interior" half of an ext/int pair, in which case it's the
## matching "exterior" half - inferred from the naming convention rather than
## authored anywhere, since the two are always paired. Two naming shapes are
## in use: numbered rooms infix it before the number (ROOM_INT_nn <-> ROOMnn),
## while unnumbered ones like Reception suffix it (RECEPTION_INT <->
## RECEPTION). A room's 1-character capacity is a property of the room as a
## whole, not of whichever of its two views is currently on screen: stepping
## through the door from ROOM01 to ROOM_INT_01 doesn't change who's "in the
## room" (same for RECEPTION / RECEPTION_INT).
static func room_group(id: int) -> int:
	var key := key_name(id)
	if key.begins_with("ROOM_INT_"):
		var ext_key := "ROOM" + key.trim_prefix("ROOM_INT_")
		if ENUMS.SUBLOCATIONS.has(ext_key):
			return ENUMS.SUBLOCATIONS[ext_key]
	if key.ends_with("_INT"):
		var ext_key := key.trim_suffix("_INT")
		if ENUMS.SUBLOCATIONS.has(ext_key):
			return ENUMS.SUBLOCATIONS[ext_key]
	return id
