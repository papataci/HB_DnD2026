@tool
extends Node2D
class_name FullFigure

@export var character: ENUMS.CHARACTERS:
	set(value):
		character = value
		_update_figure()

func _ready() -> void:
	_update_figure()
	if not Engine.is_editor_hint():
		_update_visibility()

func _update_visibility() -> void:
	var manager := get_tree().get_first_node_in_group(LocationManager.GROUP_NAME) as LocationManager
	visible = manager != null and manager.is_character_present(character)

func _update_figure() -> void:
	var existing := get_node_or_null("FullFigureTexture")
	if existing:
		remove_child(existing)
		existing.free()

	var figure_scene := _get_figure_scene()
	if not figure_scene:
		return

	var instance := figure_scene.instantiate()
	instance.name = "FullFigureTexture"
	add_child(instance)

func _get_figure_scene() -> PackedScene:
	for data in Character.DATA:
		if data.id == character:
			return data.full_figure_texture
	return null
