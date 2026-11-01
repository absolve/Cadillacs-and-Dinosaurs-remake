extends FightState
class_name RiseState
## 起身（玩家与敌人共用）：起身期间无敌，起身结束后敌人进入「眩晕送打」窗口。
##
## 原版数据：起身 14 帧带无敌 `[推定]`；敌人被击倒后 **60 帧眩晕免疫** `[ROMDATA]`
## （doc/07 §三）。玩家起身直接回待机。


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	obj.velocity = Vector2.ZERO
	obj.make_invincible(obj.rise_frames)
	obj.play_action(&"rise")


func physics_update(delta: float) -> void:
	obj.apply_gravity(delta)
	if frames_in_state >= obj.rise_frames:
		if obj.side == FightObject.FighterSide.ENEMY:
			state_machine.transition_to("Stunned")
		else:
			state_machine.transition_to("Idle")


func exit() -> void:
	# 免疫窗口从起身结束开始算，覆盖「刚站起来又被连倒」的窗口
	obj.make_knockdown_immune()
