extends CanvasLayer

## Emitted once this cutscene has finished (or been skipped) and freed
## itself. CutsceneManager.play() awaits this.
signal cutscene_ended

const IMAGES: Array[Texture2D] = [
	preload("res://assets/cutscenes/wom_cleans/vigna00.png"),
	preload("res://assets/cutscenes/wom_cleans/vigna01.png"),
	preload("res://assets/cutscenes/wom_cleans/vigna02.png"),
]

## How long to wait before the first image starts fading in.
@export var pause_before: float = 0.0
## How long each image takes to fade in and out.
@export var fade_duration: float = 0.6
## How long each image stays fully visible before moving to the next.
@export var hold_duration: float = 1.5
## How long to wait after the last image fades out.
@export var pause_after: float = 0.0

@onready var background: ColorRect = $Background
@onready var panel: TextureRect = $Panel

func _ready() -> void:
	background.modulate.a = 0.0
	panel.modulate.a = 0.0

## Called by CutsceneManager once this scene is in the tree.
func cutscene_play() -> void:
	if pause_before > 0.0:
		await get_tree().create_timer(pause_before).timeout

	await create_tween().tween_property(background, "modulate:a", 1.0, fade_duration).finished

	for i in IMAGES.size():
		panel.texture = IMAGES[i]
		await create_tween().tween_property(panel, "modulate:a", 1.0, fade_duration).finished
		await get_tree().create_timer(hold_duration).timeout
		if i < IMAGES.size() - 1:
			await create_tween().tween_property(panel, "modulate:a", 0.0, fade_duration).finished

	cutscene_out()

func _on_skip_button_pressed() -> void:
	cutscene_out()

func cutscene_out() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	tween.tween_property(background, "modulate:a", 0.0, fade_duration)
	await tween.finished

	if pause_after > 0.0:
		await get_tree().create_timer(pause_after).timeout

	cutscene_ended.emit()
	queue_free()
