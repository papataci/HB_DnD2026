extends CanvasLayer

@onready var closed = $Control/Closed
@onready var open = $Control/Open

#@onready var player_open = $Control/Closed/Player
#@onready var player_closed = $Control/Open/Player
#@onready var player_open = $Control/Open/Player
#@onready var player_closed = $Control/Closed/Player

#@onready var player_in = $Fader/RoomIN/Player
#@onready var player_ext = $Fader/RoomEXT/Player

#@onready var guest = $Control/Open/Guest


signal task_completed

# Called when the node enters the scene tree for the first time.
func setup(value):

	closed.visible = not value
	open.visible = value

	## Al momento carico la full figure solo se OPEN e con Guest
	#if guest != null and value == true:
		#guest.texture = Location.curr_guest.full_figure
#
	#player_open.texture = PlayerState.player_data.full_figure
	#player_closed.texture = PlayerState.player_data.full_figure
