@tool
extends CanvasLayer
## Adjustable per-instance version of the black-and-white screen effect,
## live in the editor as well as at runtime (@tool + setters below, same
## pattern as drop_zones/drop_sublocation.gd and full_chars/full_figure.gd).
## $ColorRect's embedded ShaderMaterial is shared by every instance of this
## scene by default (Godot doesn't duplicate embedded sub-resources per
## placement), so _ready() gives this instance its own copy and the setters
## keep it in sync as you tune brightness/contrast/saturation directly on
## this node in the Inspector - same place "visible" is already overridden
## per room - letting each room this is placed in (e.g.
## sublocation/room_ext_01.tscn) have its own look without affecting others.

@export var brightness: float = 1.0:
	set(value):
		brightness = value
		_apply()
@export var contrast: float = 1.0:
	set(value):
		contrast = value
		_apply()
@export var saturation: float = 0.0:
	set(value):
		saturation = value
		_apply()

@onready var _rect: ColorRect = $ColorRect
## Null until _ready() runs - property setters fire as soon as the scene's
## saved values are applied, which happens before _ready()/@onready, so
## _apply() has to tolerate being called before there's a material to set.
var _material: ShaderMaterial

func _ready() -> void:
	_material = _rect.material.duplicate()
	_rect.material = _material
	_apply()

func _apply() -> void:
	if not _material:
		return
	_material.set_shader_parameter("brightness", brightness)
	_material.set_shader_parameter("contrast", contrast)
	_material.set_shader_parameter("saturation", saturation)
