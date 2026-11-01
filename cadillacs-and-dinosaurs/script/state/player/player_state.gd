extends FightState
class_name PlayerState
## 玩家状态基类：把宿主转成 [Player] 并封装输入查询。
##
## 输入只在物理帧里轮询「缓冲后的结果」，不接 `_input` 信号，
## 这样无头测试注入的事件与真机手感走同一条路径。


func player() -> Player:
	return obj as Player


func wants_attack() -> bool:
	return player() != null and player().buffered_attack()


func wants_jump() -> bool:
	return player() != null and player().buffered_jump()


func consume_attack() -> void:
	if player() != null:
		player().consume_attack()


func consume_jump() -> void:
	if player() != null:
		player().consume_jump()


func move_dir() -> Vector2:
	return player().axis() if player() != null else Vector2.ZERO


func holding(action: StringName) -> bool:
	return player() != null and player().pressed(action)
