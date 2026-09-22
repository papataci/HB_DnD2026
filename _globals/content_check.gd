extends Node
## Debug-build sanity check of authored content, run once at launch so that a
## missing scene, a knot that doesn't exist, or a typo in an ink command shows
## up in the Output panel immediately instead of when a player happens to
## reach it. Read-only: problems go through push_error/push_warning and never
## stop the game.

func _ready() -> void:
	if not OS.is_debug_build():
		return
	_check_templates()
	_check_ink_stories()

## Every ENUMS.SUBLOCATIONS value should have a template, every template a
## scene, and a starting knot must exist in its starting story.
func _check_templates() -> void:
	for key in ENUMS.SUBLOCATIONS:
		var id: int = ENUMS.SUBLOCATIONS[key]
		var template: SublocationData = Sublocations.all().get(id)
		if not template:
			push_warning("ContentCheck: ENUMS.SUBLOCATIONS.%s has no template in Sublocations.TEMPLATE_PATHS" % key)
			continue

		if not template.sublocation_scene:
			var message := "ContentCheck: %s (%s) has no sublocation_scene - entering it would show nothing" % [key, template.resource_path]
			# A bare placeholder (no story, nobody inside) is probably meant
			# to be a stub; a room that has content but no scene is a bug.
			if template.starting_ink_story or not template.starting_characters.is_empty():
				push_error(message)
			else:
				push_warning(message)

		if template.starting_ink_story:
			# "" resolves to InkCommands.DEFAULT_KNOT at play time (see
			# SublocManager._start_ink_story()) - check that instead.
			var knot := template.starting_knot if not template.starting_knot.is_empty() else InkCommands.DEFAULT_KNOT
			if not _has_knot(_knot_names(template.starting_ink_story), knot):
				push_error("ContentCheck: %s starting_knot \"%s\" doesn't exist in %s" % [key, knot, template.starting_ink_story.resource_path])
		elif not template.starting_knot.is_empty():
			push_error("ContentCheck: %s has starting_knot \"%s\" but no starting_ink_story" % [key, template.starting_knot])

## Every "@COMMAND:" line in every registered story must parse, resolve its
## names, and - for @SET_KNOT - point at a knot that exists.
func _check_ink_stories() -> void:
	for story_name in InkRegistry.INK_STORIES:
		var story: Resource = InkRegistry.INK_STORIES[story_name]
		var root := _parse(story)
		if root.is_empty():
			push_error("ContentCheck: ink story \"%s\" is not valid compiled ink JSON" % story_name)
			continue
		var own_knots := _knot_names_from(root)
		var lines: Array[String] = []
		_collect_command_lines(root.get("root"), lines)
		for line in lines:
			var parsed := InkCommands.parse(line)
			if parsed == null:
				continue
			var error := InkCommands.validate(parsed)
			if not error.is_empty():
				push_error("ContentCheck: %s: %s" % [story_name, error])
				continue
			if parsed.command == "SET_KNOT":
				_check_set_knot(story_name, own_knots, parsed)

func _check_set_knot(story_name: String, own_knots: PackedStringArray, parsed: InkCommands.Parsed) -> void:
	var knot: String
	var knots: PackedStringArray
	var where: String
	if parsed.args.size() == 1:
		knot = parsed.args[0]
		knots = own_knots
		where = story_name
	else:
		knot = parsed.args[2]
		var target_story := parsed.args[1]
		if target_story != "-":
			knots = _knot_names(InkRegistry.INK_STORIES[target_story.to_lower()])
			where = target_story
		elif parsed.args[0].to_upper() == "SELF":
			knots = own_knots
			where = story_name
		else:
			# "-" on another room/location means "whatever story it has by
			# then", which is runtime state; the best static guess is its
			# starting story.
			var starting_story: Resource = null
			var subloc_target := Sublocations.parse_key(parsed.args[0])
			if subloc_target != -1:
				var template: SublocationData = Sublocations.all().get(subloc_target)
				starting_story = template.starting_ink_story if template else null
			else:
				var location_target := Locations.parse_key(parsed.args[0])
				var location_template: LocationData = Locations.all().get(location_target)
				starting_story = location_template.starting_ink_story if location_template else null
			if not starting_story:
				return
			knots = _knot_names(starting_story)
			where = starting_story.resource_path
	if knot == "-":
		knot = ""
	# "" resolves to InkCommands.DEFAULT_KNOT at play time (see
	# SublocManager._start_ink_story()) - check that instead.
	if knot.is_empty():
		knot = InkCommands.DEFAULT_KNOT
	if not _has_knot(knots, knot):
		push_error("ContentCheck: %s: @SET_KNOT knot \"%s\" doesn't exist in %s" % [story_name, knot, where])

## Compiled ink layout: {"inkVersion", "root": [ ...content..., {"Knot": [...], ...} ], "listDefs"}.
## Knots are the named entries of the root container, i.e. the keys of the
## dictionary that ends the "root" array, minus "#"-prefixed metadata keys.
static func _parse(story: Resource) -> Dictionary:
	if not story:
		return {}
	var json = story.get("json")
	if not json is String:
		return {}
	var parsed = JSON.parse_string(json)
	return parsed if parsed is Dictionary else {}

static func _knot_names_from(root: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	var content = root.get("root")
	if content is Array and not content.is_empty() and content.back() is Dictionary:
		for key in content.back():
			if not str(key).begins_with("#"):
				names.append(str(key))
	return names

static func _knot_names(story: Resource) -> PackedStringArray:
	return _knot_names_from(_parse(story))

## A knot reference may be "Knot" or "Knot.stitch"; only the knot is checked.
static func _has_knot(knots: PackedStringArray, knot: String) -> bool:
	return knots.has(knot.get_slice(".", 0))

## Every text line that's an engine directive ("^@..." in compiled ink),
## anywhere in the container tree.
static func _collect_command_lines(node, out: Array[String]) -> void:
	if node is String:
		if node.begins_with("^" + InkCommands.PREFIX):
			out.append(node.substr(1))
	elif node is Array:
		for child in node:
			_collect_command_lines(child, out)
	elif node is Dictionary:
		for key in node:
			_collect_command_lines(node[key], out)
