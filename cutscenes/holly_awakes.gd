extends CanvasLayer
#
#const center_message = preload("res://Cutscenes/center_message.tscn")

@onready var animation_player : AnimationPlayer = $AnimationPlayer
var anim_speed: float = 1

signal cutscene_ended

func _ready():
	
	visible = false
	print("Holly Awakes Cutscene Full")


func cutscene_play():

	await get_tree().create_timer(1.0).timeout 

	# To WHITE 2s
	Fade.transition(1, 0, 1.0)
	await Fade.on_transition_finished
	
	visible = true	
	
	Fade.transition(1, 1, 1.0)
	await Fade.on_transition_finished

	# TODO: qui appare lo sfondo bianco ???

	CenterMessage.show_message("Meantime in Holly's quarters...", 2.0)
	await CenterMessage.on_center_message_finished
	
	print("On with the animation.")

	animation_player.queue("HollyAwakes")
	await animation_player.animation_finished
	
	cutscene_out()
	
func _on_skip_button_pressed():
	print("SKIP!")
	cutscene_out()

func cutscene_out():
	Fade.transition(0, 0)
	await Fade.on_transition_finished
	#Background.black()
	cutscene_ended.emit()
	queue_free()
