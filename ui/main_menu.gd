extends Node2D

func _ready():
	Fade.transition(0, 1)
	await Fade.on_transition_finished

	if GameState.DEBUG:
		Fade.transition(0, 0)
		await Fade.on_transition_finished
		GameState.new_game()
		queue_free()

func _on_new_game_pressed():
	if GameState.sound:
		Sfx.Accept.play()
	
	Fade.transition(0, 0)
	await Fade.on_transition_finished
	GameState.new_game()
	queue_free()

func _on_quit_pressed():
	if GameState.sound:
		Sfx.Cancel.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
