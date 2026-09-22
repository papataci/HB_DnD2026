extends Sprite2D
## The open-door sprite of a room's exterior: shown only while the
## sublocation this scene is rendering is open (WorldState).

func _ready() -> void:
	var manager := SublocManager.find_owner(self)
	if not manager or manager.subloc_id == WorldState.MAP:
		visible = false
		return
	visible = WorldState.is_open(manager.subloc_id)
