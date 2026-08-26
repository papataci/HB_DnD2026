extends Node2D

@export var char_zone: DropZone
@export var action_zone: DropZone
@export var target_zone: DropZone
@export var output_label: Label
@export var story_manager: Node

@onready var button: Button = $Button

func _ready() -> void:
	button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not output_label:
		return
	var sentence := "%s %s %s" % [
		_display_name(char_zone),
		_display_name(action_zone),
		_display_name(target_zone),
	]
	output_label.text = sentence

	if story_manager and story_manager.has_method("submit_sentence"):
		story_manager.submit_sentence(sentence)

func _display_name(zone: DropZone) -> String:
	if not zone or zone.snapping_points.is_empty():
		return ""
	var occupant := zone.snapping_points[0].occupant
	if not occupant or not occupant.has_method("get_display_name"):
		return ""
	return occupant.get_display_name()
