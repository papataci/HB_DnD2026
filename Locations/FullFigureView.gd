extends TextureRect

@export var my_char_name : String

func _ready():
	
	print("Morlako Room IN")
	visible = false

#	 If Room is closed position the player depending on room number

	var subloc = Location.curr_subloc
	if subloc.open == false:
		if subloc.subloc_name == "Room02" or subloc.subloc_name == "Room06" or subloc.subloc_name == "Room08" or subloc.subloc_name == "RoomX":
			position.x += 550

	if Location.curr_guest != null:

		# if it's a GUEST
		if Location.curr_guest.name == my_char_name:
			visible = true

	#if IS NOT a GUEST maybe it's a PLAYER
	if PlayerState.player_data.name == my_char_name:
		visible = true
