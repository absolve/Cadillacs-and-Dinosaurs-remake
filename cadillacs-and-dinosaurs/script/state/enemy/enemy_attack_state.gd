extends EnemyState
class_name EnemyAttackState
## 敌人出招：前摇（给玩家反应时间）→ 判定 → 收招，全程锁朝向。
##
## 冷却由 [Enemy.on_attack_started] 在起手时写入，所以打空也会进入冷却 —— 
## 这就是原版杂兵「攻击欲望低」的实现方式。


var move: MoveData


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	var monster := foe()
	move = monster.primary_attack() if monster != null else null
	obj.velocity = Vector2.ZERO
	obj.set_hitbox_enabled(false)
	if move == null:
		return
	monster.on_attack_started()
	obj.face_target(monster.target)
	obj.begin_attack(move)
	obj.play_move_start(move)


func physics_update(_delta: float) -> void:
	if move == null:
		state_machine.transition_to("Approach")
		return
	var frame := frames_in_state
	var active_first := move.startup - 1
	var active_last := move.startup + move.active - 1
	if frame == active_first:
		obj.set_hitbox_enabled(true)
		obj.play_move_hit(move)
	if frame >= active_first and frame <= active_last:
		obj.resolve_hits(move)
	elif frame == active_last + 1:
		obj.set_hitbox_enabled(false)
	if frame >= move.total_frames():
		state_machine.transition_to("Approach")


func exit() -> void:
	obj.set_hitbox_enabled(false)
