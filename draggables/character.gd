@tool
extends Node
class_name Character

const DATA: Array[CharacterData] = [
	preload("res://draggables/characters/holly.tres"),
	preload("res://draggables/characters/wom.tres"),
	preload("res://draggables/characters/sandra.tres"),
]

@export var character: ENUMS.CHARACTERS = ENUMS.CHARACTERS.HOLLY:
	set(value):
		character = value
		_update_display()

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var data := _get_data()
	if not data:
		return

	var label := get_node_or_null("Label") as Label
	if label:
		label.text = data.character_name

	var texture_node := get_node_or_null("Texture")
	if texture_node and "texture" in texture_node:
		texture_node.texture = data.texture

func _get_data() -> CharacterData:
	for data in DATA:
		if data.id == character:
			return data
	return null
