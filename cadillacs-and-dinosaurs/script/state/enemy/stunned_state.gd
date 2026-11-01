extends EnemyState
class_name EnemyStunnedState
## 眩晕送打：起身后站立发呆若干帧，任人白打（doc/09 §M1）。
##
## 头顶「眩晕标签」与击倒时的「カタ」拟声标签属于演出资源，本阶段先不做。
## 眩晕期间不再主动出招，但已被标为击倒的招式仍可能把它再次打倒 ——
## 免疫窗口由 [RiseState] 通过 [method FightObject.make_knockdown_immune] 提供。

## 眩晕持续帧数 `[推定]` TODO[实测]
@export var stun_frames: int = 60


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	obj.velocity = Vector2.ZERO
	obj.set_hitbox_enabled(false)
	obj.play_action(&"stunned")


func physics_update(delta: float) -> void:
	obj.apply_gravity(delta)
	if frames_in_state >= stun_frames:
		state_machine.transition_to("Approach")
