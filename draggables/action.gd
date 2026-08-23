@tool
extends Node
class_name Action

const DATA: Array[ActionData] = [
	preload("res://draggables/actions/attack.tres"),
	preload("res://draggables/actions/seduce.tres"),
	preload("res://draggables/actions/give.tres"),
]

@export var action: ENUMS.ACTIONS = ENUMS.ACTIONS.ATTACK:
	set(value):
		action = value
		_update_display()

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var data := _get_data()
	if not data:
		return

	var label := get_node_or_null("Label") as Label
	if label:
		label.text = data.action_name

	var texture_node := get_node_or_null("Texture")
	if texture_node and "texture" in texture_node:
		texture_node.texture = data.texture

func _get_data() -> ActionData:
	for data in DATA:
		if data.id == action:
			return data
	return null
