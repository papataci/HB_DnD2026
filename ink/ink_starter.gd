extends Node2D
## Plays one compiled ink story for one sublocation: "Speaker: text" lines
## become dialogue balloons, "@COMMAND: args" lines become engine directives
## (grammar in ink/ink_commands.gd, reference in ink/_extra_commands.txt),
## anything else goes to the story label.

const ShellMessageScene := preload("res://ui/shell_message.tscn")
const DialogueBalloonScene := preload("res://ui/dialogue_balloon_autosize.tscn")
const CharIntroScene := preload("res://ui/char_intro.tscn")

@export var ink_file: Resource = preload("res://ink/example.ink.json")
## Knot/stitch to jump to before the story starts. Leave empty to start
## from the beginning of the ink file.
@export var start_knot: String = ""

## The sublocation this story belongs to, set by SublocManager, so that SELF
## in a command means this room no matter what navigation does meanwhile.
## WorldState.MAP when the story isn't attached to a sublocation.
var subloc_id: int = WorldState.MAP

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
	if not start_knot.is_empty():
		_ink_player.choose_path(start_knot)
	_advance()

func _advance() -> void:
	while _ink_player.can_continue:
		var line := _ink_player.continue_story()

		var command := InkCommands.parse(line)
		if command:
			await _run_command(command)
			continue

		var stripped := line.strip_edges()
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

## Validates and dispatches one directive. Commands that show something or
## move the player are awaited so the story pauses until they're done;
## @SET_KNOT is instantaneous.
func _run_command(command: InkCommands.Parsed) -> void:
	var error := InkCommands.validate(command)
	if not error.is_empty():
		push_error("Ink: %s" % error)
		return

	print("Ink: @%s %s" % [command.command, command.args])
	match command.command:
		"MCP":
			await _show_mcp_line(command.args[0])
		"CUTSCENE":
			await CutsceneManager.play_by_name(command.args[0])
		"TELEPORT":
			await _teleport(command.args[0])
		"INTRO":
			await _play_char_intro(command.args[0])
		"SET_KNOT":
			_set_knot(command.args)
		"CLOSE":
			_set_open(command.args[0], false)
		"OPEN":
			_set_open(command.args[0], true)
	print("Ink: @%s finished" % command.command)

## "@MCP: <text>" - shows the text in a ShellMessage panel, styled as a
## system/narrator message, and waits for the player to dismiss it.
func _show_mcp_line(text: String) -> void:
	var shell_message := ShellMessageScene.instantiate()
	shell_message.dialogue_data = {
		"character_name": "MCP",
		"message": text,
		"options": {},
	}
	add_child(shell_message)
	await shell_message.show_message_finished

## "@TELEPORT: <target>" - <target> is a key in ENUMS.LOCATIONS (back to the
## map) or ENUMS.SUBLOCATIONS, case-insensitive. Moves every playable
## character present there and plays the same fade as walking in.
func _teleport(target: String) -> void:
	var location_manager := _location_manager()
	if not location_manager:
		return
	if ENUMS.LOCATIONS.has(target.to_upper()):
		# Only one location exists today, so which one was named doesn't
		# matter yet - it's still required to be a real one.
		await location_manager.teleport_to_location()
		return
	await location_manager.teleport_to_subloc(Sublocations.parse_key(target))

## "@INTRO: <Character>" - <Character> is a key in ENUMS.CHARACTERS,
## case-insensitive. Plays ui/char_intro.tscn full-screen with that
## character's portrait, name and CharacterData.char_intro text, and waits
## for it to finish. Instantiated directly rather than through
## CutsceneManager since it's a parameterized panel, not a cutscene.
func _play_char_intro(character_name: String) -> void:
	var intro := CharIntroScene.instantiate()
	intro.character = ENUMS.CHARACTERS[character_name.to_upper()]
	get_tree().root.add_child(intro)
	intro.cutscene_play()
	await intro.cutscene_ended

## "@SET_KNOT: <knot>" or "@SET_KNOT: <sublocation> <ink_story> <knot>" -
## records in WorldState where a sublocation's story resumes from next time
## it's entered. The 1-argument form targets this story's own sublocation
## (SELF) and keeps its current ink story. In the 3-argument form
## <sublocation> is an ENUMS.SUBLOCATIONS key or SELF, <ink_story> a key in
## InkRegistry.INK_STORIES or "-" to keep the current one, and <knot> the
## knot name or "-" for InkCommands.DEFAULT_KNOT ("Start"). Since state lives in
## WorldState rather than on scene nodes, the target doesn't need to be
## loaded, and this works before or after a @TELEPORT alike.
func _set_knot(args: PackedStringArray) -> void:
	var subloc_name := "SELF"
	var story_name := "-"
	var knot := args[0]
	if args.size() == 3:
		subloc_name = args[0]
		story_name = args[1]
		knot = args[2]
	if knot == "-":
		knot = ""

	var id := _resolve_subloc(subloc_name)
	if id == WorldState.MAP:
		return

	var story: Resource = null if story_name == "-" else InkRegistry.INK_STORIES.get(story_name.to_lower())
	WorldState.set_story(id, knot, story)

## "@CLOSE: <sublocation>" / "@OPEN: <sublocation>" - sets whether
## <sublocation> is open in WorldState (e.g. room_door_open.gd reads this to
## show/hide a room's open-door sprite). <sublocation> is an
## ENUMS.SUBLOCATIONS key or SELF, same as @SET_KNOT's. Synchronous - doesn't
## pause the story.
func _set_open(subloc_name: String, open: bool) -> void:
	var id := _resolve_subloc(subloc_name)
	if id == WorldState.MAP:
		return
	WorldState.set_open(id, open)

## Resolves the shared "SELF or ENUMS.SUBLOCATIONS key" command argument to a
## sublocation id, or WorldState.MAP (with an error) if SELF was used in a
## story that isn't attached to one.
func _resolve_subloc(name: String) -> int:
	if name.to_upper() != "SELF":
		return Sublocations.parse_key(name)
	if subloc_id == WorldState.MAP:
		push_error("Ink: SELF used in a story that isn't attached to a sublocation")
	return subloc_id

func _location_manager() -> LocationManager:
	var location_manager := get_tree().get_first_node_in_group(LocationManager.GROUP_NAME) as LocationManager
	if not location_manager:
		push_error("Ink: no LocationManager in the scene")
	return location_manager

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
