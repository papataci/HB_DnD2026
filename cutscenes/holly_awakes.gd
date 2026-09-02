extends CanvasLayer

## Emitted once this cutscene has finished (or been skipped) and freed
## itself. CutsceneManager.play() awaits this.
signal cutscene_ended

const ShellMessageScene := preload("res://ui/shell_message.tscn")
const FADE_DURATION := 1.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false
	_set_children_alpha(0.0)

## Called by CutsceneManager once this scene is in the tree.
func cutscene_play() -> void:
	await get_tree().create_timer(1.0).timeout

	visible = true
	await _fade_children(1.0)

	await _show_message("Meantime in Holly's quarters...")

	animation_player.queue("HollyAwakes")
	await animation_player.animation_finished

	cutscene_out()

## Shows a plain narrator line in a ShellMessage panel and waits for the
## player to dismiss it, same as the "@MCP:" lines in ink/ink_starter.gd.
func _show_message(text: String) -> void:
	var message := ShellMessageScene.instantiate()
	message.dialogue_data = {
		"character_name": "",
		"message": text,
		"options": {},
	}
	add_child(message)
	await message.show_message_finished

func _on_skip_button_pressed() -> void:
	cutscene_out()

func cutscene_out() -> void:
	await _fade_children(0.0)
	cutscene_ended.emit()
	queue_free()

func _set_children_alpha(alpha: float) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = alpha

## CanvasLayer has no modulate of its own (it isn't a CanvasItem), so the
## whole-cutscene fade is done by tweening every direct CanvasItem child's
## modulate:a in parallel instead. None of them are directly animated by
## AnimationPlayer (its tracks target grandchildren, e.g.
## "VignetteContainer(.../Page1:modulate:a"), so this never runs at the same
## time as the cutscene's own animation.
func _fade_children(target_alpha: float) -> void:
	var tween := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", target_alpha, FADE_DURATION)
	await tween.finished
