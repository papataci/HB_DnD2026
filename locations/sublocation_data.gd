extends Resource
class_name SublocationData

@export var id: ENUMS.SUBLOCATIONS
@export var sublocation_name: String = ""
@export var quests: Array[QuestData] = []

func get_current_quest() -> QuestData:
	for quest in quests:
		if not quest.completed:
			return quest
	return null
