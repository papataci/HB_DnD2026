extends Node

## Registry of ink stories, keyed by the name used to reference them from ink
## itself (e.g. the "@SET_KNOT:" line in ink/ink_starter.gd).
const INK_STORIES: Dictionary[String, Resource] = {
	"room_default": preload("res://ink/morlako/room_default.ink.json"),
	"toshiro_00": preload("res://ink/toshiro_00.ink.json"),
	"ruperto_00": preload("res://ink/ruperto_00.ink.json"),
	"trisha_00": preload("res://ink/trisha_00.ink.json"),
}
