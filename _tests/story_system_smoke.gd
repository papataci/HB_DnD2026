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

	# --- Room 08 / Ruperto: same ext -> door -> interior shape as Room 01 ---
	_check(WorldState.is_character_at(ENUMS.SUBLOCATIONS.ROOM_INT_08, ENUMS.CHARACTERS.RUPERTO), "Ruperto is seeded into Room Int 08 (starting_characters)")
	var ruperto_room := WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_08)
	_check(ruperto_room.knot == "Start", "Room Int 08 starts at knot \"Start\"")
	_check(ruperto_room.story == InkRegistry.INK_STORIES["ruperto_00"], "Room Int 08 starts with ruperto_00")
	# NOTE: room08.tres (the exterior) was since given the same story/knot as
	# room_int_08.tres, so Ruperto's Start knot now plays both on entering
	# Room 08 directly *and* again through its door - flagged to the user
	# rather than asserted against here, since it's an active choice on their
	# side, not (yet) a settled design.

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM08)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM08, "entered Room 08")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomExt08") != null, "Room 08 exterior scene loaded")
	var ruperto_door := _find_portal(shown, ENUMS.SUBLOCATIONS.ROOM_INT_08)
	_check(ruperto_door != null, "Room 08 exterior contains the door portal targeting Room Int 08")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM_INT_08)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM_INT_08, "entered Room Int 08")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt08") != null, "Room Int 08 interior scene loaded")
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt08/RupertoFull") != null, "Ruperto's figure is in the interior scene")
	ink = shown._ink_instance if shown else null
	_check(ink != null and ink.ink_file == InkRegistry.INK_STORIES["ruperto_00"], "Room Int 08 started ruperto_00")
	_check(ink != null and ink.start_knot == "Start", "...at knot \"Start\"")
	_check(manager.is_character_present(ENUMS.CHARACTERS.RUPERTO), "Ruperto is present in his interior")

	# --- @CLOSE / @OPEN, dispatched through the running ink instance --------
	_check(WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "Room Int 08 starts open")
	if ink:
		ink._set_open(PackedStringArray(["SELF"]), false)
	_check(not WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "ink._set_open(SELF, false) closes Room Int 08 in WorldState")
	_check(not WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM08), "...and it's shared with Room 08's exterior (the door sprite room_door_open.gd reads)")
	if ink:
		ink._set_open(PackedStringArray(["SELF"]), true)
	_check(WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "ink._set_open(SELF, true) reopens it")

	await manager.go_location()
	await manager.go_location()
	_check(manager.current_subloc() == WorldState.MAP, "stepped back out of Room Int 08 / Room 08 to the map")

	# --- Room 07 / Traficante: same shape, but no ink story yet ---------------
	_check(WorldState.is_character_at(ENUMS.SUBLOCATIONS.ROOM_INT_07, ENUMS.CHARACTERS.TRAFICANTE), "Traficante is seeded into Room Int 07 (starting_characters)")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_07).story == null, "Room Int 07 has no ink story yet (none authored)")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM07).story == null, "Room 07 (exterior) starts with no story, so it doesn't auto-eject before the door")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM07)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM07, "entered Room 07")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomExt07") != null, "Room 07 exterior scene loaded")
	var traficante_door := _find_portal(shown, ENUMS.SUBLOCATIONS.ROOM_INT_07)
	_check(traficante_door != null, "Room 07 exterior contains the door portal targeting Room Int 07")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM_INT_07)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM_INT_07, "entered Room Int 07")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt07") != null, "Room Int 07 interior scene loaded")
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt07/TraficanteFull") != null, "Traficante's figure is in the interior scene")
	_check(shown != null and shown._ink_instance == null, "Room Int 07 plays no ink (none authored yet)")
	_check(manager.is_character_present(ENUMS.CHARACTERS.TRAFICANTE), "Traficante is present in his interior")

	await manager.go_location()
	await manager.go_location()
	_check(manager.current_subloc() == WorldState.MAP, "stepped back out of Room Int 07 / Room 07 to the map")

	# --- Room 05 / Trisha: same ext -> door -> interior shape as Room 01 -----
	_check(WorldState.is_character_at(ENUMS.SUBLOCATIONS.ROOM_INT_05, ENUMS.CHARACTERS.TRISHA), "Trisha is seeded into Room Int 05 (starting_characters)")
	var trisha_room := WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM_INT_05)
	_check(trisha_room.knot == "Start", "Room Int 05 starts at knot \"Start\"")
	_check(trisha_room.story == InkRegistry.INK_STORIES["trisha_00"], "Room Int 05 starts with trisha_00")
	_check(WorldState.get_state(ENUMS.SUBLOCATIONS.ROOM05).story == null, "Room 05 (exterior) starts with no story, so it doesn't auto-eject before the door")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM05)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM05, "entered Room 05")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomExt05") != null, "Room 05 exterior scene loaded")
	var trisha_door := _find_portal(shown, ENUMS.SUBLOCATIONS.ROOM_INT_05)
	_check(trisha_door != null, "Room 05 exterior contains the door portal targeting Room Int 05")

	await manager.go_subloc(ENUMS.SUBLOCATIONS.ROOM_INT_05)
	_check(manager.current_subloc() == ENUMS.SUBLOCATIONS.ROOM_INT_05, "entered Room Int 05")
	shown = _subloc_manager(manager)
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt05") != null, "Room Int 05 interior scene loaded")
	_check(shown != null and shown.get_node_or_null("SublocScene/RoomInt05/TrishaFull") != null, "Trisha's figure is in the interior scene")
	ink = shown._ink_instance if shown else null
	_check(ink != null and ink.ink_file == InkRegistry.INK_STORIES["trisha_00"], "Room Int 05 started trisha_00")
	_check(ink != null and ink.start_knot == "Start", "...at knot \"Start\"")
	_check(manager.is_character_present(ENUMS.CHARACTERS.TRISHA), "Trisha is present in her interior")

	await manager.go_location()
	await manager.go_location()
	_check(manager.current_subloc() == WorldState.MAP, "stepped back out of Room Int 05 / Room 05 to the map")

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

	# --- @CLOSE / @OPEN -------------------------------------------------------
	_check(WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "Room Int 08 starts open (SublocationData.starting_open default)")
	var close_cmd := InkCommands.parse("@CLOSE: room_int_08")
	_check(close_cmd != null and close_cmd.command == "CLOSE" and InkCommands.validate(close_cmd).is_empty(), "@CLOSE parses and validates")
	var bare_close := InkCommands.parse("@CLOSE:")
	_check(bare_close != null and bare_close.args.is_empty() and InkCommands.validate(bare_close).is_empty(), "@CLOSE with no argument (defaults to SELF) parses and validates")
	WorldState.set_open(ENUMS.SUBLOCATIONS.ROOM_INT_08, false)
	_check(not WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "WorldState.set_open(false) closes it")
	_check(not WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM08), "...and it's shared with Room 08's exterior")
	WorldState.set_open(ENUMS.SUBLOCATIONS.ROOM_INT_08, true)
	_check(WorldState.is_open(ENUMS.SUBLOCATIONS.ROOM_INT_08), "WorldState.set_open(true) reopens it")
	var bad_close := InkCommands.parse("@CLOSE: room_01")
	_check(bad_close != null and InkCommands.validate(bad_close).contains("unknown sublocation"), "@CLOSE validate() catches an unknown sublocation key")

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
