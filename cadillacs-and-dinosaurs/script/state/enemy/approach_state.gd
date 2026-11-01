extends EnemyState
class_name EnemyApproachState
## 追击（敌人的「平时」）：目标进入 aggro 范围就成排走近，先对齐纵深再前进；
## 距离与纵深都对齐且冷却结束就出招。原版杂兵的攻击欲望很低，别在这里加花活。


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	obj.velocity = Vector2.ZERO
	obj.play_action(&"idle")


func physics_update(_delta: float) -> void:
	var monster := foe()
	if monster == null or monster.is_dead:
		return
	if monster.target == null:
		monster.target = monster.nearest_player()
	if not monster.target_in_aggro():
		obj.play_action(&"idle")
		return
	if monster.can_attack():
		state_machine.transition_to("Attack")
		return
	var direction := monster.direction_to_target()
	# 横向已到位、纵深没对齐时只调纵深，避免贴着人来回蹭
	if monster.in_attack_range():
		direction.x = 0.0
	if direction == Vector2.ZERO:
		obj.play_action(&"idle")
		return
	obj.play_action(&"walk")
	obj.move_by(direction)
