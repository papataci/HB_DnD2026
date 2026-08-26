extends CanvasLayer

@onready var night_filter = $NightFilter
@onready var morning_filter = $MorningFilter

func _ready():
	night_filter.visible = false
	morning_filter.visible = false
	

func on_broadcast_message(message):
	print("POST PRODUCTION received message: ", message)
#
	#if message == "on_location_ready":
#
		#update()
		
	if message == "Show":
		update()
		visible = true
	else:
		if message == "Hide":
			visible = false
		

func update():
	
	var current_timespan = GameState.current_timespan
	
	match current_timespan:
	
		# NIGHT
		Enums.Timespan.NIGHT:
			night_filter.visible = true	
			morning_filter.visible = false
		# MORNING
		Enums.Timespan.MORNING:
			night_filter.visible = false	
			morning_filter.visible = true
		# DAY
		Enums.Timespan.DAY:
			night_filter.visible = false	
			morning_filter.visible = false
	
