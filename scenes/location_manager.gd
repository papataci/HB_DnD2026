extends Node
class_name LocationManager

const GROUP_NAME := &"location_manager"
const CHARACTER_SCENE := preload("res://draggables/character.tscn")
const CHARACTER_SPACING := 200.0

@export var fader: ColorRect
@export var container: Node
@export var characters_container: Node2D
@export var subloc_scene: PackedScene = preload("res://scenes/subloc.tscn")

var current_subloc: DropSublocation
var _current_subloc_instance: Node
## Sublocations we've swapped in from (nested drop_sublocation, e.g. a room's
## interior reached from its exterior), most recent last. Popped by
## go_location() to step back up one level instead of exiting to the map.
var _subloc_stack: Array[DropSublocation] = []

func _ready() -> void:
	add_to_group(GROUP_NAME)

func is_character_present(character: ENUMS.CHARACTERS) -> bool:
	return current_subloc != null and character in current_subloc.characters

## DropZone reparents a dropped Area2D onto itself before drop_applied even
## fires (see DropZone._attach()). When we're swapping subloc content in
## place instead of freeing the whole Subloc instance, that reparented node
## would otherwise keep rendering under the drop zone until its queue_free()
## is actually processed, so detach it immediately before freeing it.
func _discard_returning(returning: Character) -> void:
	var parent := returning.get_parent()
	if parent:
		parent.remove_child(returning)
	returning.queue_free()

## A nested DropSublocation (e.g. a door inside a room's own background
## scene, leading to that room's interior) lives inside the very content
## Subloc.configure() is about to replace with the target it points to.
## Detach it and park it here so it survives for as long as it's
## current_subloc/on the stack, instead of being freed out from under us.
func _keep_alive(subloc: DropSublocation) -> void:
	var parent := subloc.get_parent()
	if parent:
		parent.remove_child(subloc)
	add_child(subloc)
	subloc.visible = false

func go_subloc(subloc: DropSublocation, character: Node = null) -> void:
	await fader.fade_out().finished

	var dropped := character as Character
	if dropped:
		if dropped.character not in subloc.characters:
			subloc.characters.append(dropped.character)
		get_tree().call_group(GameInit.GROUP_NAME, "remove_character", dropped.character)
		_discard_returning(dropped)

	if _current_subloc_instance:
		# Already inside a sublocation: swap its data in place rather than
		# stacking a new Subloc scene on top of the current one, and remember
		# the one we're leaving so go_location() can step back up to it.
		_subloc_stack.push_back(current_subloc)
		current_subloc = subloc
		_keep_alive(subloc)
		if _current_subloc_instance.has_method("configure"):
			_current_subloc_instance.configure(subloc)
	else:
		var instance: Node = subloc_scene.instantiate()
		if instance.has_method("configure"):
			instance.configure(subloc)
		current_subloc = subloc
		_current_subloc_instance = instance
		container.add_child(instance)

	_refresh_subloc_characters(subloc)

	await fader.fade_in().finished

func _refresh_subloc_characters(subloc: DropSublocation) -> void:
	if not characters_container:
		return
	for child in characters_container.get_children():
		child.queue_free()
	for i in subloc.characters.size():
		var present_character := CHARACTER_SCENE.instantiate() as Character
		present_character.character = subloc.characters[i]
		present_character.position = Vector2(0, -i * CHARACTER_SPACING)
		characters_container.add_child(present_character)

func go_location(character: Node = null) -> void:
	if not _current_subloc_instance:
		return
	await fader.fade_out().finished

	var returning := character as Character

	if not _subloc_stack.is_empty():
		# Step back up to the parent sublocation instead of exiting to the map.
		var parent_subloc: DropSublocation = _subloc_stack.pop_back()
		var leaving_subloc := current_subloc
		if returning and leaving_subloc:
			leaving_subloc.characters.erase(returning.character)
			if returning.character not in parent_subloc.characters:
				parent_subloc.characters.append(returning.character)
			_discard_returning(returning)
		current_subloc = parent_subloc
		if _current_subloc_instance.has_method("configure"):
			_current_subloc_instance.configure(parent_subloc)
		_refresh_subloc_characters(parent_subloc)
		# The nested subloc we were kept alive for is gone the moment
		# configure() reloads the parent's own content anyway, so drop it now.
		if leaving_subloc:
			leaving_subloc.queue_free()
	else:
		if returning and current_subloc:
			current_subloc.characters.erase(returning.character)
			get_tree().call_group(GameInit.GROUP_NAME, "add_character", returning.character)
			_discard_returning(returning)
		else:
			get_tree().call_group(GameInit.GROUP_NAME, "refresh")

		_current_subloc_instance.queue_free()
		_current_subloc_instance = null
		current_subloc = null

	await fader.fade_in().finished
