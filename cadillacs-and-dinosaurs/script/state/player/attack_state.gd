extends PlayerState
class_name PlayerAttackState
## 三段连击：`startup` 无判定 → `active` 开盒结算 → `recovery` 收招。
##
## 接段条件与原版一致：**本段必须命中**（hit-confirm），且在可取消窗口之后
## 再按攻击才递进；第 3 段之后不再连（doc/07 §攻击判定、doc/09 §M1）。
## 判定盒按帧开关，不依赖动画结束信号。

const MAX_HIT: int = 3

var hit_index: int = 1
var move: MoveData
var hit_confirmed: bool = false
var chained: bool = false


func enter(_previous: StringName, data: Dictionary = {}) -> void:
	hit_index = clampi(int(data.get("hit", 1)), 1, MAX_HIT)
	move = obj.move_of(StringName("attack%d" % hit_index))
	if move == null:
		move = obj.move_of(&"attack1")
	hit_confirmed = false
	chained = false
	obj.velocity = Vector2.ZERO
	# 起手瞬间按当前输入转向；无输入则保持原朝向（走打保留前进方向）
	obj.set_face_dir(move_dir().x)
	obj.set_hitbox_enabled(false)
	if move == null:
		push_warning("%s: 招式表里没有 attack1" % obj.name)
		return
	obj.begin_attack(move)
	obj.play_move_start(move)


func physics_update(_delta: float) -> void:
	if move == null:
		state_machine.transition_to("Idle")
		return
	var frame := frames_in_state
	var active_first := move.startup - 1
	var active_last := move.startup + move.active - 1
	if frame == active_first:
		obj.set_hitbox_enabled(true)  # 延后一帧生效，判定窗口正好覆盖 active
		obj.play_move_hit(move)       # 切到命中段动画（doc/10 §8.11 两段式）
	if frame >= active_first and frame <= active_last:
		hit_confirmed = hit_confirmed or not obj.resolve_hits(move).is_empty()
	elif frame == active_last + 1:
		obj.set_hitbox_enabled(false)
	if can_chain() and frame >= move.cancel_from:
		chain()
		return
	if frame >= move.total_frames():
		consume_attack()  # 收招时清缓冲，避免「收招瞬间凭空接段」
		state_machine.transition_to("Idle")


func exit() -> void:
	obj.set_hitbox_enabled(false)


func can_chain() -> bool:
	return not chained and hit_confirmed and hit_index < MAX_HIT and wants_attack()


func chain() -> void:
	chained = true
	consume_attack()
	state_machine.transition_to("Attack", { "hit": hit_index + 1 })
