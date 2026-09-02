extends Resource
class_name SublocationData

@export var id: ENUMS.SUBLOCATIONS
@export var sublocation_name: String = ""
@export var sublocation_scene: PackedScene
@export var starting_characters: Array[ENUMS.CHARACTERS] = []
@export var starting_ink_story: Resource
@export var starting_knot: String = ""
