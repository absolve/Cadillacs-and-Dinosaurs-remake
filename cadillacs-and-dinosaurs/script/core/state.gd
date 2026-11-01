extends Node
class_name FightState
## 状态基类：由 [StateMachine] 驱动，玩家与敌人状态共用同一套回调。
##
## 子类覆盖 [method enter] / [method exit] / [method physics_update]；
## 计时**一律用物理帧计数**（原版 59.6 Hz 以帧为单位，见 doc/07 §三），
## 不依赖动画结束信号，这样无头测试与低帧率下行为一致。
## 输入由宿主对象（[Player] / [Enemy]）提供缓冲后的查询接口，状态只轮询不接信号。

## 宿主战斗对象，[_ready] 时从 `owner` 取
var obj: FightObject
## 驱动本状态的状态机
var state_machine: StateMachine
## 进入本状态后已经过的物理帧数
var frames_in_state: int = 0


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	await owner.ready
	obj = owner as FightObject
	state_machine = get_parent() as StateMachine


func enter(_previous: StringName, _data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
