extends Resource
class_name LocationData

@export var id: ENUMS.LOCATIONS
@export var location_name: String = ""
@export var background: Texture2D
@export var sublocations: Array[SublocationData] = []
## Compiled ink (.ink.json) this location plays, or null for none - e.g. a
## "time scheduler" story run once every room's quest is resolved. Same
## starting_story/starting_knot shape as SublocationData; resumable the same
## way via WorldState (see WorldState.set_location_story()).
@export var starting_ink_story: Resource
## Leave empty to start starting_ink_story from InkCommands.DEFAULT_KNOT
## ("Start"). Only set this when the location's story doesn't open there.
@export var starting_knot: String = ""
