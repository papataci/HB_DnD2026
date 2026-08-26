extends CanvasLayer

signal task_completed
@onready var fade_container = $FadeContainer

@onready var character = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer2/VBoxContainer/Character
@onready var description = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer2/VBoxContainer/Description
@onready var portrait = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer/Portrait
@onready var animation_player = $AnimationPlayer

func show_intro(guest):
	
	portrait.texture = guest.portrait
	print("Character Intro")
	character.text = guest.name
	description.text = guest.description
	
	#animation rewind just in case
	animation_player.seek(0, true)

	fade_container.visible = true

	animation_player.queue("Fade In Out")
	await animation_player.animation_finished

	fade_container.visible = false
	
	task_completed.emit()


func _on_skip_button_pressed():
	print("SKIP!")
	task_completed.emit()
	
