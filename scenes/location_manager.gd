extends Node
class_name LocationManager

const GROUP_NAME := &"location_manager"

@export var fader: ColorRect
@export var container: Node
@export var subloc_scene: PackedScene = preload("res://scenes/subloc.tscn")

var _current_subloc_instance: Node

func _ready() -> void:
	add_to_group(GROUP_NAME)

func go_subloc(subloc: DropSublocation) -> void:
	await fader.fade_out().finished
	var instance: Node = subloc_scene.instantiate()
	if instance.has_method("configure"):
		instance.configure(subloc.sublocation_data)
	_current_subloc_instance = instance
	container.add_child(instance)
	await fader.fade_in().finished

func go_location() -> void:
	if not _current_subloc_instance:
		return
	await fader.fade_out().finished
	_current_subloc_instance.queue_free()
	_current_subloc_instance = null
	await fader.fade_in().finished
