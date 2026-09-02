@tool
extends Node
class_name Character

const DATA: Array[CharacterData] = [
	preload("res://draggables/characters/holly.tres"),
	preload("res://draggables/characters/wom.tres"),
	preload("res://draggables/characters/sandra.tres"),
	preload("res://draggables/characters/god.tres"),
	preload("res://draggables/characters/toshiro.tres"),
	preload("res://draggables/characters/ruperto.tres"),
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
	_apply_initial_cards()
	_update_display()
	_update_cards()

func _apply_initial_cards() -> void:
	if not cards.is_empty():
		return
	var init_node := get_tree().get_first_node_in_group(CharacterInit.GROUP_NAME) as CharacterInit
	if init_node:
		cards = init_node.get_starting_cards(character)

func _update_display() -> void:
	var data := _get_data()
	if not data:
		return

	var label := get_node_or_null("Label") as Label
	if label:
		label.text = data.character_name

	var texture_node := get_node_or_null("Texture")
	if texture_node and "texture" in texture_node:
		texture_node.texture = data.bubble_texture

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
	return get_data(character)

static func get_data(character_id: ENUMS.CHARACTERS) -> CharacterData:
	for data in DATA:
		if data.id == character_id:
			return data
	return null

static func is_playable(character_id: ENUMS.CHARACTERS) -> bool:
	var data := get_data(character_id)
	return data != null and data.playable
