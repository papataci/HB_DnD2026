extends Node2D
class_name SublocManager

const InkScene := preload("res://ink/ink_example.tscn")

var subloc: DropSublocation
var sublocation_data: SublocationData
var _ink_instance: Node

func configure(drop_subloc: DropSublocation) -> void:
	subloc = drop_subloc
	sublocation_data = drop_subloc.sublocation_data if drop_subloc else null
	if not sublocation_data:
		return

	var title := get_node_or_null("Title") as Label
	if title:
		title.text = sublocation_data.sublocation_name

	_load_subloc_scene(sublocation_data.sublocation_scene)
	_start_ink_story(drop_subloc)

func _load_subloc_scene(scene: PackedScene) -> void:
	var subloc_scene := get_node_or_null("SublocScene") as Node2D
	if not subloc_scene:
		return

	for child in subloc_scene.get_children():
		child.queue_free()

	if scene:
		subloc_scene.add_child(scene.instantiate())

func _start_ink_story(drop_subloc: DropSublocation) -> void:
	if _ink_instance:
		_ink_instance.queue_free()
		_ink_instance = null

	if not drop_subloc.ink_story:
		return

	var ink := InkScene.instantiate()
	ink.ink_file = drop_subloc.ink_story
	ink.start_knot = drop_subloc.knot
	add_child(ink)
	_ink_instance = ink

	var execute := get_node_or_null("Sentence/Execute")
	if execute and "story_manager" in execute:
		execute.story_manager = ink
