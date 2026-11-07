extends "res://script/core/player.gd"
class_name HannahPlayer


func animation_state_for_ref(ref: String) -> StringName:
	return StringName("hannah_%s" % animation_clip_for_ref(ref))
