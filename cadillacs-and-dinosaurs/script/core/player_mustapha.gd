extends "res://script/core/player.gd"
class_name MustaphaPlayer


func animation_state_for_ref(ref: String) -> StringName:
	return StringName("mustapha_%s" % animation_clip_for_ref(ref))
