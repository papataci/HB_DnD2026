extends Node2D
class_name CharBubble
## Sits under a room's DropSublocation portal (e.g. Morlako/Room01/CharBubble)
## and shows the bubble portrait of whoever WorldState currently has in that
## room's group. Hidden whenever the room is empty.

@onready var _sprite: Sprite2D = $CharSprite
@onready var _unresolved: Sprite2D = $Unresolved

var _room: int = -1

func _ready() -> void:
	var portal := DropSublocation.find_owner(self)
	if not portal:
		push_error("CharBubble: no DropSublocation ancestor found")
		return
	_room = portal.target
	WorldState.roster_changed.connect(_on_roster_changed)
	WorldState.unresolved_changed.connect(_on_unresolved_changed)
	_update_sprite()
	_update_unresolved()

func _on_roster_changed(where: int) -> void:
	if where == _room:
		_update_sprite()

func _on_unresolved_changed(where: int) -> void:
	if where == _room:
		_update_unresolved()

func _update_unresolved() -> void:
	_unresolved.visible = WorldState.is_unresolved(_room)

func _update_sprite() -> void:
	var roster := WorldState.characters_at(_room)
	var data: CharacterData = Character.get_data(roster[0]) if not roster.is_empty() else null
	if data and data.bubble_texture:
		_sprite.texture = data.bubble_texture
		_sprite.show()
	else:
		_sprite.hide()
