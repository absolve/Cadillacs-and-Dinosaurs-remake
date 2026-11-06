extends Camera2D
class_name StageCamera
## 关卡摄像机：跟随最前方玩家，位置夹取与锁屏冻结全部委托
## [StageDirector.camera_target_for]（doc/05 §①④）。

## 指定跟随目标（多人时留空自动取最前方玩家，同 test_room 口径）
@export var follow_target: NodePath


func _physics_process(_delta: float) -> void:
	if StageDirector.stage == null:
		return
	# 注意：get_node_or_null(NodePath("")) 返回节点自身，必须先判空
	var target: Node2D = null
	if not follow_target.is_empty():
		target = get_node_or_null(follow_target) as Node2D
	if target == null:
		target = _frontmost_player()
	if target == null:
		return
	position = StageDirector.camera_target_for(target, position)


func _frontmost_player() -> Node2D:
	var front: FightObject
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		if not is_instance_valid(node):
			continue  # queue_free 后同帧内仍可能留在组里
		var candidate := node as FightObject
		if candidate == null or candidate.is_dead:
			continue
		if front == null or candidate.global_position.y > front.global_position.y:
			front = candidate
	return front
