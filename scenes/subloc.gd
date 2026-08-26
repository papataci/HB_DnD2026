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
