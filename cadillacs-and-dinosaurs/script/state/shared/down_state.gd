extends FightState
class_name DownState
## 倒地（玩家与敌人共用）：击倒类招式命中后进入，躺 `down_frames` 帧再起身。
## 原版击倒会弹「カタ」拟声标签，演出资源到位后在这里挂（doc/09 §M1）。

var push_dir: int = 0
var push_speed: float = 0.0


func enter(_previous: StringName, data: Dictionary = {}) -> void:
	push_dir = int(data.get("push_dir", 0))
	push_speed = obj.knockback_speed * 1.5 if push_dir != 0 else 0.0
	obj.velocity = Vector2.ZERO
	obj.set_face_dir(-float(push_dir))
	obj.set_hitbox_enabled(false)
	obj.play_action(&"down")


func physics_update(delta: float) -> void:
	if push_speed > 0.0:
		push_speed = maxf(push_speed - obj.knockback_decay * delta, 0.0)
		obj.velocity = Vector2(push_dir * push_speed, 0.0)
		obj.move_and_slide()
		obj.clamp_to_bounds()
	obj.apply_gravity(delta)
	if frames_in_state >= obj.down_frames:
		state_machine.transition_to("Rise")
