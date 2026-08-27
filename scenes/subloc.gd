extends Node2D
class_name Subloc

var sublocation_data: SublocationData

func configure(data: SublocationData) -> void:
	sublocation_data = data
	if not data:
		return

	var title := get_node_or_null("Title") as Label
	if title:
		title.text = data.sublocation_name

	var quest := data.get_current_quest()
	var quest_label := get_node_or_null("QuestLabel") as Label
	if quest_label:
		quest_label.text = quest.quest_name if quest else ""

	_load_background(data.background_scene)

func _load_background(scene: PackedScene) -> void:
	var background := get_node_or_null("Background") as Node2D
	if not background:
		return

	for child in background.get_children():
		child.queue_free()

	if scene:
		background.add_child(scene.instantiate())
