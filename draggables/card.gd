@tool
extends Node
class_name Card

const DATA: Array[CardData] = [
	preload("res://draggables/cards/attack.tres"),
	preload("res://draggables/cards/seduce.tres"),
	preload("res://draggables/cards/give.tres"),
	preload("res://draggables/cards/heal.tres"),
	preload("res://draggables/cards/hit.tres"),
	preload("res://draggables/cards/shoot.tres"),
	preload("res://draggables/cards/talk.tres"),
	preload("res://draggables/cards/turn.tres"),
]

@export var action: ENUMS.CARDS = ENUMS.CARDS.ATTACK:
	set(value):
		action = value
		_update_display()

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var data := _get_data()
	if not data:
		return

	var texture_node := get_node_or_null("Texture")
	if texture_node and "texture" in texture_node:
		texture_node.texture = data.texture

func get_display_name() -> String:
	var data := _get_data()
	return data.card_name if data else ""

func _get_data() -> CardData:
	for data in DATA:
		if data.id == action:
			return data
	return null
