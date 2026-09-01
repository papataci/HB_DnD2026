extends Sprite2D

func _ready() -> void:
	var subloc_node := _find_subloc_node()
	visible = subloc_node != null and "subloc" in subloc_node and subloc_node.subloc and subloc_node.subloc.is_open

## Walks up the tree looking for the Subloc node (identified by having a
## sublocation_data property), which is where the DropSublocation's is_open
## state can be read from.
func _find_subloc_node() -> Node:
	var node := get_parent()
	while node:
		if "sublocation_data" in node and node.sublocation_data:
			return node
		node = node.get_parent()
	return null
