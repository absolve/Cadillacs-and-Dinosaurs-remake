extends PlayerState
class_name PlayerJumpState
## 跳跃与飞踢：起跳给伪 Z 轴初速度，空中按 `air_control_factor` 修正横向位置；
## 每次跳跃只允许一次空中攻击（原版飞踢），落地回待机。

var air_attack_used: bool = false
var kick_move: MoveData


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	obj.start_jump()
	air_attack_used = false
	kick_move = obj.move_of(&"kick")
	# 保留起跳瞬间的方向速度，跑跳不会立刻刹停
	obj.velocity = obj.velocity_from_input(move_dir())
	obj.play_action(&"jump")


func physics_update(delta: float) -> void:
	var input_dir := move_dir()
	if not air_attack_used:
		obj.set_face_dir(input_dir.x)
	obj.velocity = obj.velocity_from_input(input_dir, obj.air_control_factor)
	obj.move_and_slide()
	obj.clamp_to_bounds()
	if not air_attack_used and wants_attack() and kick_move != null:
		start_kick()
	if air_attack_used:
		# 飞踢的判定保持到落地（doc/07 §三：追踪踢「保持到落地」）
		obj.resolve_hits(kick_move)
	if not obj.apply_gravity(delta):
		obj.play_action(&"kick" if air_attack_used else (&"jump" if obj.z_velocity < 0.0 else &"fall"))
		return
	obj.velocity = Vector2.ZERO
	consume_attack()
	consume_jump()
	state_machine.transition_to("Idle")


func start_kick() -> void:
	air_attack_used = true
	consume_attack()
	obj.begin_attack(kick_move)
	obj.set_hitbox_enabled(true)
	obj.play_move_start(kick_move)


func exit() -> void:
	obj.velocity = Vector2.ZERO
	obj.set_hitbox_enabled(false)
