class_name InkCommands
## The "@COMMAND: args" directive grammar, shared by the runtime
## (ink/ink_starter.gd) and the boot-time content check
## (_globals/content_check.gd) so both agree on what's valid and a typo is
## reported at launch rather than when a player reaches the line.
## Keep res://ink/_extra_commands.txt in sync when adding a command.

const PREFIX := "@"

## The knot a room-attached story resumes from when its knot is "" - the
## convention every room-quest ink file in this project follows for its
## opening knot (see e.g. toshiro_00.ink, ruperto_00.ink). Applied where room
## data feeds into the ink runner (SublocManager._start_ink_story()), not by
## ink_starter.gd itself, since that scene is also used for ink files with no
## knots at all (e.g. ink/example.ink), where "" correctly means "just play
## from the top" and forcing this knot would break them.
const DEFAULT_KNOT := "Start"

## Commands whose argument is free text: everything after the colon is kept
## as a single argument instead of being split on spaces.
const FREE_TEXT: Array[String] = ["MCP"]

## Allowed argument counts per command.
const ARITY: Dictionary[String, Array] = {
	"MCP": [1],
	"CUTSCENE": [1],
	"TELEPORT": [1],
	"INTRO": [1],
	"SET_KNOT": [1, 3],
	"CLOSE": [1],
	"OPEN": [1],
}

class Parsed:
	var command: String
	var args: PackedStringArray
	var line: String

## Returns the parsed command, or null when `line` isn't a directive at all.
static func parse(line: String) -> Parsed:
	var stripped := line.strip_edges()
	if not stripped.begins_with(PREFIX):
		return null
	var colon := stripped.find(":")
	if colon == -1:
		return null
	var parsed := Parsed.new()
	parsed.line = stripped
	parsed.command = stripped.substr(1, colon - 1).strip_edges().to_upper()
	var rest := stripped.substr(colon + 1).strip_edges()
	if parsed.command in FREE_TEXT:
		parsed.args = PackedStringArray([rest])
	else:
		parsed.args = rest.split(" ", false)
	return parsed

## Static checks that don't need the game running: known command, argument
## count, and that names resolve in their registries. Returns "" when valid,
## otherwise the error message. Whether a knot exists is checked by the
## content check, since it needs the story's JSON.
static func validate(parsed: Parsed) -> String:
	if not ARITY.has(parsed.command):
		return "unknown command @%s in \"%s\"" % [parsed.command, parsed.line]
	if parsed.args.size() not in ARITY[parsed.command]:
		return "@%s expects %s argument(s), got %d in \"%s\"" % [
			parsed.command, str(ARITY[parsed.command]), parsed.args.size(), parsed.line,
		]
	match parsed.command:
		"CUTSCENE":
			if not CutsceneManager.CUTSCENES.has(parsed.args[0]):
				return "@CUTSCENE unknown cutscene \"%s\"" % parsed.args[0]
		"INTRO":
			if not ENUMS.CHARACTERS.has(parsed.args[0].to_upper()):
				return "@INTRO unknown character \"%s\"" % parsed.args[0]
		"TELEPORT":
			var target := parsed.args[0]
			if not ENUMS.LOCATIONS.has(target.to_upper()) and Sublocations.parse_key(target) == -1:
				return "@TELEPORT unknown target \"%s\"" % target
		"SET_KNOT":
			if parsed.args.size() == 3:
				if not _is_valid_subloc_arg(parsed.args[0]):
					return "@SET_KNOT unknown sublocation \"%s\"" % parsed.args[0]
				var story := parsed.args[1]
				if story != "-" and not InkRegistry.INK_STORIES.has(story.to_lower()):
					return "@SET_KNOT unknown ink story \"%s\"" % story
		"CLOSE", "OPEN":
			if not _is_valid_subloc_arg(parsed.args[0]):
				return "@%s unknown sublocation \"%s\"" % [parsed.command, parsed.args[0]]
	return ""

## True if `name` is the literal keyword SELF, or a key in
## ENUMS.SUBLOCATIONS (case-insensitive) - the shared "which sublocation"
## argument form used by @SET_KNOT's 3-argument form, @CLOSE and @OPEN.
static func _is_valid_subloc_arg(name: String) -> bool:
	return name.to_upper() == "SELF" or Sublocations.parse_key(name) != -1
