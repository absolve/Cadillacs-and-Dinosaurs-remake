extends PlayerState
class_name PlayerIdleState
## 待机：无移动输入时播 `idle`。若因空中硬直结束等原因仍在浮空，本状态负责落回地面。


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	obj.velocity = Vector2.ZERO
	obj.play_action(&"idle")


func physics_update(delta: float) -> void:
	if obj.in_air:
		obj.play_action(&"jump")
		obj.apply_gravity(delta)
		return
	if wants_attack():
		consume_attack()
		state_machine.transition_to("Attack", { "hit": 1 })
		return
	if wants_jump():
		consume_jump()
		state_machine.transition_to("Jump")
		return
	var input_dir := move_dir()
	if input_dir != Vector2.ZERO:
		obj.set_face_dir(input_dir.x)
		state_machine.transition_to("Walk")
