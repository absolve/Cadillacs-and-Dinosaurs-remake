extends "res://script/core/player.gd"
class_name JackPlayer

func animation_state_for_ref(ref: String) -> StringName:
	return StringName("jack_%s" % animation_clip_for_ref(ref))
