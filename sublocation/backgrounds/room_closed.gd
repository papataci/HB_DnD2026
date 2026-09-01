extends Node

@export var odd_room_offset_x: float = 1500.0
@export var even_room_offset_x: float = 420.0

func _ready() -> void:
	var texture_node := get_parent() as Node2D
	if not texture_node:
		return

	var room_number := _find_room_number()
	var is_odd := room_number != -1 and room_number % 2 == 1
	texture_node.position.x = odd_room_offset_x if is_odd else even_room_offset_x

func _find_room_number() -> int:
	var node := get_parent()
	while node:
		if "sublocation_data" in node and node.sublocation_data:
			var regex := RegEx.new()
			regex.compile("\\d+")
			var result := regex.search(node.sublocation_data.sublocation_name)
			return result.get_string().to_int() if result else -1
		node = node.get_parent()
	return -1
