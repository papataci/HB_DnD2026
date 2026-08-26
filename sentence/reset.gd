extends Node2D

@onready var button: Button = $Button

func _ready() -> void:
	button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	get_tree().call_group(DropZone.GROUP_NAME, "release_all")
	get_tree().call_group(Draggable.GROUP_NAME, "return_home")
