class_name Locations
## Static registry of every location's authored template, keyed by its
## ENUMS.LOCATIONS id. Mirrors Sublocations exactly, for the same reasons:
## the key is the whole identity (what LocationManager.location is, what
## WorldState keeps runtime story/knot state under), templates are immutable
## at runtime, and paths are loaded on first use to avoid cyclic loads.

const TEMPLATE_PATHS: Dictionary[int, String] = {
	ENUMS.LOCATIONS.MORLAKO: "res://locations/morlako.tres",
}

static var _templates: Dictionary[int, LocationData] = {}

## Every registered template by id, loading them the first time it's called.
static func all() -> Dictionary[int, LocationData]:
	if _templates.is_empty():
		for id in TEMPLATE_PATHS:
			var loaded := load(TEMPLATE_PATHS[id]) as LocationData
			if loaded:
				_templates[id] = loaded
			else:
				push_error("Locations: %s is not a LocationData" % TEMPLATE_PATHS[id])
	return _templates

## The template for `id`, or null (with an error) if none is registered.
static func template(id: int) -> LocationData:
	var found: LocationData = all().get(id)
	if not found:
		push_error("Locations: no template registered for %s" % key_name(id))
	return found

## Resolves an ink-facing name - an ENUMS.LOCATIONS key, case-insensitive,
## e.g. "morlako" - to its id, or -1 if unknown.
static func parse_key(name: String) -> int:
	var key := name.strip_edges().to_upper()
	if ENUMS.LOCATIONS.has(key):
		return ENUMS.LOCATIONS[key]
	return -1

## The ENUMS.LOCATIONS key for `id` (e.g. "MORLAKO"), for messages.
static func key_name(id: int) -> String:
	var key = ENUMS.LOCATIONS.find_key(id)
	return str(key) if key != null else "<unknown %d>" % id

## The authored display name for `id`, falling back to its key.
static func display_name(id: int) -> String:
	var found: LocationData = all().get(id)
	return found.location_name if found else key_name(id)
