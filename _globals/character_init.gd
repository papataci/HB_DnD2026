extends Node
class_name CharacterInit

const GROUP_NAME := &"character_init"

@export var data: CharacterInitData = preload("res://_globals/char_init.tres")

func _ready() -> void:
	add_to_group(GROUP_NAME)

func get_starting_cards(character_id: ENUMS.CHARACTERS) -> Array[CardData]:
	for start in data.starting_characters:
		if start.character == character_id:
			return start.cards
	return []
