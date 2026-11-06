extends Node
## Game —— 全局单例：全局信号、共用函数、共用类型。
##
## 已落地：演出慢放的**全屏层**（设计见 doc/09 §演出慢放设计）。
## 个体层慢放在 [FightObject.start_self_slow]，两层相乘成有效步长。
##
## 规划职责（随里程碑填入）：暂停、分数与命数信号；
## 游戏流程枚举（标题 / 选人 / 关卡 / 结算，M6 `GameFlow` 的底座）。

signal dilation_changed(step: int, real_frames_left: int)
## 玩家对象进树时广播（[Hud] 据此挂卡片；出生顺序 = 卡片槽位）
signal player_registered(player: Player)

## 全屏慢放步长 N：所有 [FightObject] 每 N 物理帧只推进 1 有效帧。
## 摄像机 / 输入缓冲不受影响（保持真实速率）
var world_step: int = 1
var _world_left: int = 0


## 触发全屏慢放 `1/step`，持续 `real_frames` 个物理帧后自动恢复
func set_world_slow(step: int, real_frames: int) -> void:
	world_step = clampi(step, 1, 8)
	_world_left = maxi(real_frames, 0)
	dilation_changed.emit(world_step, _world_left)


func is_world_slow() -> bool:
	return world_step > 1


func _physics_process(_delta: float) -> void:
	if _world_left <= 0:
		return
	_world_left -= 1
	if _world_left == 0 and world_step != 1:
		world_step = 1
		dilation_changed.emit(1, 0)
