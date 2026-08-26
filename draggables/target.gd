@tool
extends Node
class_name Target

const DATA: Array[TargetData] = [
	preload("res://draggables/targets/toshiro.tres"),
	preload("res://draggables/targets/ruperto.tres"),
	preload("res://draggables/targets/misterx.tres"),
	preload("res://draggables/targets/twins.tres"),
]

@export var target: ENUMS.TARGETS = ENUMS.TARGETS.TOSHIRO:
	set(value):
		target = value
		_update_display()

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var data := _get_data()
	if not data:
		return

	var label := get_node_or_null("Label") as Label
	if label:
		label.text = data.target_name

	var texture_node := get_node_or_null("Texture")
	if texture_node and "texture" in texture_node:
		texture_node.texture = data.texture

func get_display_name() -> String:
	var data := _get_data()
	return data.target_name if data else ""

func _get_data() -> TargetData:
	for data in DATA:
		if data.id == target:
			return data
	return null
