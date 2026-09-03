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
@export var starting_knot: String = ""
@export var starting_open: bool = true
