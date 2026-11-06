extends Node
class_name StateMachine
## 状态机驱动器：每物理帧把 [method FightState.physics_update] 与每渲染帧把
## [method FightState.update] 分发给当前状态。输入不走状态，由宿主对象
## （[Player] / [Enemy]）提供缓冲后的查询接口，状态只轮询。
##
## 通用框架，不含任何角色专属逻辑；具体行为由子树上的 [FightState] 节点实现。
## 状态切换用**节点名**（如 `Hurt`），子树顺序即状态清单。

## 切换时发出，供 HUD / 音效 / 测试观察
signal state_changed(previous: StringName, current: StringName)

@export var initial_state: NodePath
## 关闭后状态机不再跑 physics_update（调试冻结用）
@export var enabled: bool = true

var current_state: FightState
var frames_since_start: int = 0


func _ready() -> void:
	await owner.ready
	if initial_state.is_empty():
		push_error("%s/StateMachine: 未指定 initial_state" % owner.name)
		return
	current_state = get_node(initial_state) as FightState
	if current_state == null:
		push_error("%s/StateMachine: initial_state 不是 FightState" % owner.name)
		return
	current_state.frames_in_state = 0
	current_state.enter(&"")


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	if not enabled:
		return
	var next := get_node_or_null(String(state_name)) as FightState
	if next == null:
		push_error("%s: 状态节点不存在 %s" % [owner.name, state_name])
		return
	var previous := current_state.name if current_state != null else &""
	if current_state != null:
		current_state.exit()
	current_state = next
	next.frames_in_state = 0   # 每次进入都从零计帧，招式计时才可复现
	next.enter(previous, data)
	state_changed.emit(previous, StringName(next.name))


func current_name() -> StringName:
	return StringName(current_state.name) if current_state != null else &""


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	# 慢放门控：宿主 FightObject 决定本物理帧是否推进（doc/09 §演出慢放设计）
	var host := owner as FightObject
	if host != null and not host.is_local_tick():
		return
	frames_since_start += 1
	current_state.frames_in_state += 1
	current_state.physics_update(delta)
