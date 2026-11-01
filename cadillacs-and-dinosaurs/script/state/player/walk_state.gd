extends PlayerState
class_name PlayerWalkState
## 行走：八向移动（纵深方向按 `depth_speed_factor` 减速），受可行走范围夹取；
## 可接跳跃与出拳。


func physics_update(_delta: float) -> void:
	var input_dir := move_dir()
	if input_dir == Vector2.ZERO:
		state_machine.transition_to("Idle")
		return
	if wants_attack():
		consume_attack()
		state_machine.transition_to("Attack", { "hit": 1 })
		return
	if wants_jump():
		consume_jump()
		state_machine.transition_to("Jump")
		return
	obj.play_action(&"walk")
	obj.move_by(input_dir)


func exit() -> void:
	obj.velocity = Vector2.ZERO
