extends Node

## Registry of playable cutscenes, keyed by the name used to trigger them
## (e.g. the "@CUTSCENE:" line prefix in ink/ink_starter.gd).
const CUTSCENES: Dictionary[String, PackedScene] = {
	"holly_awakes": preload("res://cutscenes/holly_awakes.tscn"),
	"cougars_arrive": preload("res://cutscenes/cougars_arrive.tscn"),
	"wom_cleans": preload("res://cutscenes/wom_cleans.tscn"),
}

## Instantiates and plays a cutscene scene, then waits for it to finish.
## The scene's root must expose cutscene_play() and emit cutscene_ended when
## done (see cutscenes/cougars_arrive.gd) - it's responsible for freeing itself.
func play(cutscene_scene: PackedScene) -> void:
	if not cutscene_scene:
		return
	var cutscene := cutscene_scene.instantiate()
	get_tree().root.add_child(cutscene)
	cutscene.cutscene_play()
	await cutscene.cutscene_ended

## Looks up a cutscene by its CUTSCENES key and plays it.
func play_by_name(cutscene_name: String) -> void:
	var scene: PackedScene = CUTSCENES.get(cutscene_name)
	if not scene:
		push_error("CutsceneManager: unknown cutscene \"%s\"" % cutscene_name)
		return
	await play(scene)
