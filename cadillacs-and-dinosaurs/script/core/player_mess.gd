extends "res://script/core/player.gd"
class_name MessPlayer


func animation_state_for_ref(ref: String) -> StringName:
	return StringName("mess_%s" % animation_clip_for_ref(ref))
