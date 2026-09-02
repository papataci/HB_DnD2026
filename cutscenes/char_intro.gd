extends CanvasLayer

## Emitted once this panel has finished (or been skipped) and freed itself.
signal cutscene_ended

## Which character to introduce. Set by the caller (see "@INTRO:" in
## ink/ink_starter.gd) before calling cutscene_play().
@export var character: ENUMS.CHARACTERS = ENUMS.CHARACTERS.HOLLY

## How long to wait before the panel starts fading in.
@export var pause_before: float = 0.0
## How long the panel takes to fade in and out.
@export var fade_duration: float = 1.0
## How long the panel stays fully visible before fading out.
@export var hold_duration: float = 2.0
## How long to wait after the panel finishes fading out.
@export var pause_after: float = 0.0

@onready var fade_container: Panel = $FadeContainer
@onready var character_label: Label = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer2/VBoxContainer/Character
@onready var description_label: RichTextLabel = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer2/VBoxContainer/Description
@onready var portrait: TextureRect = $FadeContainer/VignetteCountainer/MarginContainer/Page1/MarginContainer/Portrait

func _ready() -> void:
	fade_container.modulate.a = 0.0

## Called once this panel is in the tree, with `character` already set.
func cutscene_play() -> void:
	var data := Character.get_data(character)
	if data:
		portrait.texture = data.bubble_texture
		character_label.text = data.character_name
		description_label.text = data.char_intro

	if pause_before > 0.0:
		await get_tree().create_timer(pause_before).timeout

	fade_container.visible = true
	await create_tween().tween_property(fade_container, "modulate:a", 1.0, fade_duration).finished

	await get_tree().create_timer(hold_duration).timeout

	cutscene_out()

func _on_skip_button_pressed() -> void:
	cutscene_out()

func cutscene_out() -> void:
	await create_tween().tween_property(fade_container, "modulate:a", 0.0, fade_duration).finished
	fade_container.visible = false

	if pause_after > 0.0:
		await get_tree().create_timer(pause_after).timeout

	cutscene_ended.emit()
	queue_free()
