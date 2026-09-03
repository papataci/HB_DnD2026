extends Node
## Headless smoke test of the story/sublocation system: drives the map ->
## Room 01 -> its interior -> @SET_KNOT -> @TELEPORT -> re-enter loop that
## the runtime state has to survive, without needing a player to click
## through the dialogue. Run from the project folder:
##
##   godot --headless res://_tests/story_system_smoke.tscn
##
## (a scene rather than `-s`, so the autoloads are up.) Prints one line per
## check and exits with code 1 if any failed.

const MAIN_SCENE := "res://scenes/main.tscn"

var _failures := 0

func _ready() -> void:
	_run()

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	add_child(main)
	# LocationManager renders the initial roster deferred; let that happen.
	await get_tree().process_frame
	await get_tree().process_frame

	var manager := get_tree().get_first_node_in_group(LocationManager.GROUP_NAME) as LocationManager
	_check(manager != null, "LocationManager is in the tree")
	if not manager:
		return _finish()

	# --- Initial state comes from the templates -----------------------------
	_check(manager.current_subloc() == WorldState.MAP, "starts on the map")
	_check(WorldState.is_character_at(WorldState.MAP, ENUMS.CHARACTERS.WOM), "WOM starts on the map (init.tres)")
	_check(WorldState.is_character_at(ENUMS.SUBLOCATIONS.ROOM_INT_01, ENUMS.CHARACTERS.TOSHIRO), "Toshiro is seeded into Room Int 01 (starting_characters)")
	var interior := WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_01)
	_check(interior.knot == "Start", "Room Int 01 starts at knot \"Start\"")
	_check(interior.story == InkRegistry.INK_STORIES["toshiro_00"], "Room Int 01 starts with toshiro_00")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM01).story == null, "Room 01 (exterior) starts with no story")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM02).knot == "EmptyRoom", "Room 02 starts at \"EmptyRoom\" (moved from location.tscn into its template)")

	# --- Map -> Room 01 (exterior) ------------------------------------------
	WorldState.move_character(ENUMS.CHARACTERS.WOM, WorldState.MAP, ENUMS.SUBLOCATIONS.ROOM01)
	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM01)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM01, "entered Room 01")
	var shown := _subloc_manager(manager)
	_check(shown != null and shown.subloc_id == ENUMS.SUBLOCATIONS.ROOM01, "SublocManager shows Room 01")
	_check(shown != null and shown._ink_instance == null, "Room 01 exterior plays no ink")
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomExt01") != null, "Room 01 exterior scene loaded")
	var door := _find_portal(shown, ENUMS.SUBLOCATIONS.ROOM_INT_01)
	_check(door != null, "exterior contains the door portal targeting Room Int 01")
	_check(manager.is_character_present(ENUMS.CHARACTERS.WOM), "WOM is present in Room 01")

	# --- Room 01 -> interior ------------------------------------------------
	WorldState.move_character(ENUMS.CHARACTERS.WOM, ENUMS.SUBLOCATIONS.ROOM01, ENUMS.SUBLOCATIONS.ROOM_INT_01)
	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM_INT_01)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM_INT_01, "entered Room Int 01")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.subloc_id == ENUMS.SUBLOCATIONS.ROOM_INT_01, "SublocManager swapped to Room Int 01 in place")
	var ink: Node = shown._ink_instance if shown else null
	_check(ink != null, "Room Int 01 started an ink story")
	_check(ink != null and ink.start_knot == "Start", "...at knot \"Start\"")
	_check(ink != null and ink.subloc_id == ENUMS.SUBLOCATIONS.ROOM_INT_01, "...attached to Room Int 01 (SELF)")
	_check(manager.is_character_present(ENUMS.CHARACTERS.TOSHIRO), "Toshiro is present in the interior")

	# --- What the Start knot does, minus the clicking -----------------------
	# Same code path as the "@SET_KNOT: ..." lines in ink/toshiro_00.ink.
	if ink:
		ink._set_knot(PackedStringArray(["LeaveMeAlone"]))
		ink._set_knot(PackedStringArray(["room01", "room_default", "RoomAlreadyClean"]))
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_01).knot == "LeaveMeAlone", "@SET_KNOT LeaveMeAlone updated Room Int 01 in WorldState")
	var exterior := WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM01)
	_check(exterior.knot == "RoomAlreadyClean", "@SET_KNOT room01 ... updated Room 01's knot")
	_check(exterior.story == InkRegistry.INK_STORIES["room_default"], "...and its story")

	# --- @TELEPORT: Morlako -------------------------------------------------
	await manager.teleport_to_location()
	_check(manager.current_subloc() == WorldState.MAP, "teleport_to_location() returns to the map")
	_check(_subloc_manager(manager) == null, "SublocManager freed on the map")
	_check(WorldState.is_character_at(WorldState.MAP, ENUMS.CHARACTERS.WOM), "WOM (playable) came back to the map")
	_check(WorldState.is_character_at(ENUMS.SUBLOCATIONS.ROOM_INT_01, ENUMS.CHARACTERS.TOSHIRO), "Toshiro (NPC) stayed in the interior")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_01).knot == "LeaveMeAlone", "interior knot survived leaving")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM01).knot == "RoomAlreadyClean", "exterior knot survived leaving")
	var portal := _find_portal(main, ENUMS.SUBLOCATIONS.ROOM01)
	_check(portal != null and is_instance_valid(portal), "the Room 01 portal on the map is still there")

	# --- Second visit resumes where the story left off ----------------------
	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM01)
	shown = _subloc_manager(manager)
	ink = shown._ink_instance if shown else null
	_check(ink != null and ink.ink_file == InkRegistry.INK_STORIES["room_default"], "re-entering Room 01 now plays room_default")
	_check(ink != null and ink.start_knot == "RoomAlreadyClean", "...from \"RoomAlreadyClean\"")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM_INT_01)
	shown = _subloc_manager(manager)
	ink = shown._ink_instance if shown else null
	_check(ink != null and ink.start_knot == "LeaveMeAlone", "re-entering Room Int 01 resumes from \"LeaveMeAlone\"")

	# --- Back arrow steps out one level at a time ---------------------------
	await manager.go_location()
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM01, "go_location() from the interior returns to Room 01")
	await manager.go_location()
	_check(manager.current_subloc() == WorldState.MAP, "go_location() from Room 01 returns to the map")

	# --- Command grammar ----------------------------------------------------
	var parsed := InkCommands.parse("@SET_KNOT: room01 room_default RoomAlreadyClean")
	_check(parsed != null and parsed.command == "SET_KNOT" and parsed.args.size() == 3, "InkCommands.parse splits arguments")
	_check(parsed != null and InkCommands.validate(parsed).is_empty(), "...and validates a correct line")
	var mcp := InkCommands.parse("@MCP: This room is empty, go back to work!")
	_check(mcp != null and mcp.args.size() == 1 and mcp.args[0].begins_with("This room"), "@MCP keeps its text as one argument")
	_check(InkCommands.parse("Toshiro: hello") == null, "dialogue lines are not commands")
	var bad := InkCommands.parse("@SET_KNOT: room_01 room_default X")
	_check(bad != null and InkCommands.validate(bad).contains("unknown sublocation"), "validate() catches an unknown sublocation key")
	var bad_story := InkCommands.parse("@SET_KNOT: room01 nope X")
	_check(bad_story != null and InkCommands.validate(bad_story).contains("unknown ink story"), "validate() catches an unknown ink story")
	var bad_arity := InkCommands.parse("@SET_KNOT: a b")
	_check(bad_arity != null and InkCommands.validate(bad_arity).contains("argument"), "validate() catches a wrong argument count")

	_finish()

func _subloc_manager(manager: LocationManager) -> SublocManager:
	var instance := manager._subloc_instance
	return instance if instance and is_instance_valid(instance) else null

func _find_portal(from: Node, target: int) -> DropSublocation:
	for node in from.find_children("*", "DropSublocation", true, false):
		if node.target == target:
			return node
	return null

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_failures += 1
		printerr("  FAIL ", what)

func _finish() -> void:
	if _failures == 0:
		print("story_system_smoke: all checks passed")
	else:
		printerr("story_system_smoke: %d check(s) failed" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
