extends Node2D

const ShellMessageScene := preload("res://ui/shell_message.tscn")
const DialogueBalloonScene := preload("res://ui/dialogue_balloon_autosize.tscn")
const CharIntroScene := preload("res://cutscenes/char_intro.tscn")

@export var ink_file: Resource = preload("res://ink/example.ink.json")
## Knot/stitch to jump to before the story starts. Leave empty to start
## from the beginning of the ink file.
@export var start_knot: String = ""

var _ink_player: InkPlayer

@onready var _story_label: Label = $StoryLabel
@onready var _choices_container: VBoxContainer = $ChoicesContainer

## Engine commands are authored as "@COMMAND: args", the "@" marking them as
## out-of-band directives rather than a character speaking (see
## _extract_speaker() below for the plain "Speaker: text" dialogue form).
## Keep res://ink/_extra_commands.txt in sync when adding a new one.
const MCP_PREFIX := "@MCP:"
const CUTSCENE_PREFIX := "@CUTSCENE:"
const TELEPORT_PREFIX := "@TELEPORT:"
const INTRO_PREFIX := "@INTRO:"
const SET_KNOT_PREFIX := "@SET_KNOT:"

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
		var stripped := line.strip_edges()
		if stripped.begins_with(MCP_PREFIX):
			await _show_mcp_line(stripped)
		elif stripped.begins_with(CUTSCENE_PREFIX):
			await _play_cutscene(stripped)
		elif stripped.begins_with(TELEPORT_PREFIX):
			await _teleport(stripped)
		elif stripped.begins_with(INTRO_PREFIX):
			await _play_char_intro(stripped)
		elif stripped.begins_with(SET_KNOT_PREFIX):
			_set_knot(stripped)
		else:
			var speaker := _extract_speaker(stripped)
			if not speaker.is_empty():
				var message := stripped.trim_prefix(speaker + ":").strip_edges()
				await _show_dialogue_line(speaker, message)
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
	var section := line.trim_prefix(MCP_PREFIX).strip_edges()

	var shell_message := ShellMessageScene.instantiate()
	shell_message.dialogue_data = {
		"character_name": "MCP",
		"message": section,
		"options": {},
	}
	add_child(shell_message)
	await shell_message.show_message_finished

## Ink authors a cutscene cue as "@CUTSCENE: name", where name is a key in
## CutsceneManager.CUTSCENES (e.g. "cougars_arrive"). Plays it full-screen and
## waits for it to finish before the story continues.
func _play_cutscene(line: String) -> void:
	var cutscene_name := line.trim_prefix(CUTSCENE_PREFIX).strip_edges()
	await CutsceneManager.play_by_name(cutscene_name)

## Ink authors a teleport cue as "@TELEPORT: <target>", where <target> is a
## key in ENUMS.LOCATIONS (e.g. "MORLAKO") or ENUMS.SUBLOCATIONS (e.g.
## "RECEPTION") - always the target's own name, never a magic keyword.
## Moves every playable character currently present - in the sublocation
## we're in, or the top-level location if we aren't in one - into the
## target, and plays the same fade/swap transition as dragging a character
## there. Waits for it to finish before the story continues.
func _teleport(line: String) -> void:
	var target_name := line.trim_prefix(TELEPORT_PREFIX).strip_edges()
	var location_manager := get_tree().get_first_node_in_group(LocationManager.GROUP_NAME) as LocationManager
	if not location_manager:
		push_error("Ink: @TELEPORT has no LocationManager in the scene")
		return

	var target_key := target_name.to_upper()

	if ENUMS.LOCATIONS.has(target_key):
		# Only "return to the top-level location" is supported today - there's
		# only one location, so which one was named doesn't matter yet.
		await location_manager.teleport_to_location()
		return

	if not ENUMS.SUBLOCATIONS.has(target_key):
		push_error("Ink: @TELEPORT unknown target \"%s\"" % target_name)
		return

	var target_subloc := location_manager.find_subloc(ENUMS.SUBLOCATIONS[target_key])
	if not target_subloc:
		push_error("Ink: @TELEPORT sublocation \"%s\" not found in the current scene" % target_name)
		return

	await location_manager.teleport_to_subloc(target_subloc)

## Ink authors a character-introduction cue as "@INTRO: <Character>", where
## <Character> is a key in ENUMS.CHARACTERS (e.g. "TOSHIRO"). Plays
## cutscenes/char_intro.tscn full-screen with that character's portrait,
## name, and CharacterData.char_intro text, and waits for it to finish
## before the story continues. Goes straight to its own scene rather than
## through CutsceneManager, since it's not really a "cutscene" - it's a
## dedicated, parameterized intro panel (see ShellMessage/DialogueBalloon
## above for the same direct-instantiation pattern).
func _play_char_intro(line: String) -> void:
	var character_key := line.trim_prefix(INTRO_PREFIX).strip_edges().to_upper()
	if not ENUMS.CHARACTERS.has(character_key):
		push_error("Ink: @INTRO unknown character \"%s\"" % character_key)
		return

	var intro := CharIntroScene.instantiate()
	intro.character = ENUMS.CHARACTERS[character_key]
	get_tree().root.add_child(intro)
	intro.cutscene_play()
	await intro.cutscene_ended

## Ink authors a "move the story forward" cue as "@SET_KNOT: <knot>", which
## calls DropSublocation.set_knot() on the current sublocation (see
## LocationManager.current_subloc) so that re-entering it later resumes from
## <knot> instead of wherever it started this time - e.g. after a quest step
## completes, so the room doesn't replay the same intro. Leave <knot> empty
## to reset back to the start of the ink file. Synchronous - doesn't pause
## the story.
func _set_knot(line: String) -> void:
	var knot_name := line.trim_prefix(SET_KNOT_PREFIX).strip_edges()
	var location_manager := get_tree().get_first_node_in_group(LocationManager.GROUP_NAME) as LocationManager
	if not location_manager or not location_manager.current_subloc:
		push_error("Ink: @SET_KNOT has no current sublocation to update")
		return
	location_manager.current_subloc.set_knot(knot_name)

## Ink authors character lines as "Speaker: text" (see e.g. ink/toshiro_00.ink).
## Returns "Speaker" when the line starts with that pattern, or "" for plain
## narration, so callers can tell the two apart.
func _extract_speaker(line: String) -> String:
	var colon_index := line.find(":")
	if colon_index <= 0:
		return ""
	var candidate := line.substr(0, colon_index)
	return candidate if candidate.is_valid_identifier() else ""

## Shows a "Speaker: text" story line in a DialogueBalloon instead of the
## plain story label. DialogueBalloon locates itself by searching the tree
## for a node named "<Speaker>_Balloon_Pos" (see e.g. the marker in
## full_chars/toshiro_full.tscn), so as long as the sublocation's loaded
## scene contains that character's full-figure instance, the balloon appears
## next to them with no extra wiring needed here.
func _show_dialogue_line(speaker: String, message: String) -> void:
	var balloon := DialogueBalloonScene.instantiate()
	balloon.dialogue_data = {
		"character_name": speaker,
		"message": message,
		"options": {},
	}
	add_child(balloon)
	await balloon.show_message_finished

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
