extends Node
class_name GameInit

const GROUP_NAME := &"game_init"
const CHARACTER_SCENE := preload("res://draggables/character.tscn")
const CHARACTER_SPACING := 200.0

@export var data: InitData = preload("res://_globals/init.tres")
@export var location: Location
@export var characters_container: Node2D

func _ready() -> void:
	add_to_group(GROUP_NAME)
	if location and data and location.characters.is_empty():
		location.characters = data.starting_characters.duplicate()
	refresh()

func add_character(character_id: ENUMS.CHARACTERS) -> void:
	if not location:
		return
	if character_id not in location.characters:
		location.characters.append(character_id)
	refresh()

func remove_character(character_id: ENUMS.CHARACTERS) -> void:
	if not location:
		return
	location.characters.erase(character_id)
	refresh()

func refresh() -> void:
	if not characters_container or not location:
		return
	for child in characters_container.get_children():
		child.queue_free()
	var playable_characters := location.characters.filter(Character.is_playable)
	for i in playable_characters.size():
		var character := CHARACTER_SCENE.instantiate() as Character
		character.character = playable_characters[i]
		character.position = Vector2(0, -i * CHARACTER_SPACING)
		characters_container.add_child(character)
