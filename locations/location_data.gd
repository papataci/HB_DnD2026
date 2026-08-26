extends Resource
class_name LocationData

@export var id: ENUMS.LOCATIONS
@export var location_name: String = ""
@export var background: Texture2D
@export var sublocations: Array[SublocationData] = []
