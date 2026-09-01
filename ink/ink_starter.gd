extends Node2D

const ShellMessageScene := preload("res://ui/shell_message.tscn")

@export var ink_file: Resource = preload("res://ink/example.ink.json")
## Knot/stitch to jump to before the story starts. Leave empty to start
## from the beginning of the ink file.
@export var start_knot: String = ""

var _ink_player: InkPlayer

@onready var _story_label: Label = $StoryLabel
@onready var _choices_container: VBoxContainer = $ChoicesContainer

const MCP_PREFIX := "MCP:"

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
	if not start_knot.is_empty():
		_ink_player.choose_path(start_knot)
	_advance()

func _advance() -> void:
	while _ink_player.can_continue:
		var line := _ink_player.continue_story()
		if line.strip_edges().begins_with(MCP_PREFIX):
			await _show_mcp_line(line)
		else:
			_story_label.text += line

	if _ink_player.has_choices:
		_on_prompt_choices(_ink_player.current_choices)
	elif not _ink_player.can_continue:
		_on_ended()

## Shows a story line tagged as coming from "MCP" inside a ShellMessage
## panel instead of the plain story label, and waits for the player to
## dismiss it before the story continues.
func _show_mcp_line(line: String) -> void:
	var section := line.strip_edges().trim_prefix(MCP_PREFIX).strip_edges()

	var shell_message := ShellMessageScene.instantiate()
	shell_message.dialogue_data = {
		"character_name": "MCP",
		"message": section,
		"options": {},
	}
	add_child(shell_message)
	await shell_message.show_message_finished

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
