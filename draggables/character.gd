@tool
extends Node
class_name Character

const DATA: Array[CharacterData] = [
	preload("res://draggables/characters/holly.tres"),
	preload("res://draggables/characters/wom.tres"),
	preload("res://draggables/characters/sandra.tres"),
	preload("res://draggables/characters/god.tres"),
]

const CARD_SCENE := preload("res://draggables/card.tscn")
const CARD_SPACING := 100.0

@export var character: ENUMS.CHARACTERS = ENUMS.CHARACTERS.HOLLY:
	set(value):
		character = value
		_update_display()

@export var cards: Array[CardData] = []:
	set(value):
		cards = value
		_update_cards()

func _ready() -> void:
	_update_display()
	_update_cards()

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

func _update_cards() -> void:
	var container := get_node_or_null("Cards") as Node2D
	if not container:
		return

	for child in container.get_children():
		child.queue_free()

	for i in cards.size():
		var card_data := cards[i]
		if not card_data:
			continue

		var card := CARD_SCENE.instantiate()
		card.position = Vector2(i * CARD_SPACING, 0)
		container.add_child(card)
		card.action = card_data.id

func get_display_name() -> String:
	var data := _get_data()
	return data.character_name if data else ""

func _get_data() -> CharacterData:
	for data in DATA:
		if data.id == character:
			return data
	return null
