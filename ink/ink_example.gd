extends Node2D

@export var ink_file: Resource = preload("res://ink/example.ink.json")

var _ink_player: InkPlayer

@onready var _story_label: Label = $StoryLabel
@onready var _choices_container: VBoxContainer = $ChoicesContainer

func _ready() -> void:
	_ink_player = InkPlayerFactory.create()
	_ink_player.ink_file = ink_file
	add_child(_ink_player)

	_ink_player.loaded.connect(_on_loaded)

	_ink_player.create_story()

func _on_loaded(successfully: bool) -> void:
	if not successfully:
		_story_label.text = "Failed to load ink story."
		return
	_advance()

func _advance() -> void:
	while _ink_player.can_continue:
		_story_label.text += _ink_player.continue_story()

	if _ink_player.has_choices:
		_on_prompt_choices(_ink_player.current_choices)
	elif not _ink_player.can_continue:
		_on_ended()

func _on_prompt_choices(choices: Array) -> void:
	_clear_choices()
	for i in choices.size():
		var button := Button.new()
		button.text = choices[i].text
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choices_container.add_child(button)

func _on_choice_pressed(index: int) -> void:
	_clear_choices()
	_ink_player.choose_choice_index(index)
	_advance()

## Called externally (e.g. by the Execute button) with the player's composed
## sentence. If it matches the text of one of the story's currently offered
## choices, follows that path the same way clicking its button would.
## Returns true if a match was found.
func submit_sentence(sentence: String) -> bool:
	if not _ink_player or not _ink_player.has_choices:
		return false

	var normalized := sentence.strip_edges().to_lower()
	for i in _ink_player.current_choices.size():
		if _ink_player.current_choices[i].text.strip_edges().to_lower() == normalized:
			_on_choice_pressed(i)
			return true

	return false

func _on_ended() -> void:
	_story_label.text += "\n\n-- The End --"

func _clear_choices() -> void:
	for child in _choices_container.get_children():
		child.queue_free()
