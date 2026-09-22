extends Resource
class_name SublocationData
## Authored, immutable description of one sublocation. Its identity is the
## ENUMS.SUBLOCATIONS key it's registered under in Sublocations.TEMPLATE_PATHS -
## there's deliberately no id field here to keep in sync. Everything that
## changes during play (current story/knot, who's inside, open/closed) is
## seeded from the starting_* fields into WorldState and lives there.

@export var sublocation_name: String = ""
@export var sublocation_scene: PackedScene
@export var starting_characters: Array[ENUMS.CHARACTERS] = []
@export var starting_ink_story: Resource
## Leave empty to start starting_ink_story from InkCommands.DEFAULT_KNOT
## ("Start") - the convention every room-quest ink file uses for its opening
## knot. Only set this when resuming somewhere other than the beginning.
@export var starting_knot: String = ""
@export var starting_open: bool = true
## Shown as the CharBubble's red "Unresolved" sprite when true. Shared across
## a room's ext/int pair like starting_characters - authoring it on either
## template flags the room.
@export var starting_unresolved: bool = false
