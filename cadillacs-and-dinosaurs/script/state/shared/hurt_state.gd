extends FightState
class_name HurtState
## 受击硬直（玩家与敌人共用）：转身面向出手者、沿其出招方向被推开、播 `hurt`，
## 硬直结束回各自的本位状态。空中受击同样继续受重力，不会悬空。

var push_dir: int = 0
var push_speed: float = 0.0


func enter(_previous: StringName, data: Dictionary = {}) -> void:
	push_dir = int(data.get("push_dir", 0))
	push_speed = obj.knockback_speed if push_dir != 0 else 0.0
	obj.velocity = Vector2.ZERO
	obj.set_face_dir(-float(push_dir))
	obj.set_hitbox_enabled(false)
	obj.play_action(&"hurt")


func physics_update(delta: float) -> void:
	if push_speed > 0.0:
		push_speed = maxf(push_speed - obj.knockback_decay * delta, 0.0)
		obj.velocity = Vector2(push_dir * push_speed, 0.0)
		obj.move_and_slide()
		obj.clamp_to_bounds()
	obj.apply_gravity(delta)
	if frames_in_state >= obj.hurt_stun_frames:
		state_machine.transition_to(home_state())


## 各阵营的「平时」状态名
func home_state() -> StringName:
	return &"Idle" if obj.side == FightObject.FighterSide.PLAYER else &"Approach"
