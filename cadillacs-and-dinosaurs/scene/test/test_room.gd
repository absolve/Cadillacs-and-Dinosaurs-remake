extends Node2D
class_name TestRoom
## 测试房：灰盒街道 + Y 排序 + 摄像机跟随最前玩家 + 状态 HUD。
##
## 两种用法：
## - **手动**：编辑器里运行本场景，用 `p1_*` 键操作，HUD 实时显示状态 / HP / 力量；
## - **自动**：无头或带 `--auto` 运行时，`AutoTest` 子节点跑一遍断言并退出。

const FRONT_MARGIN := Vector2(0, -24)
## 可切换的角色场景（`1` / `2` 键），用来肉眼确认每个角色的动画
const ROSTER: Array[PackedScene] = [
	preload("res://scene/actor/player/jack.tscn"),
	preload("res://scene/actor/player/hannah.tscn"),
	preload("res://scene/actor/player/mustapha.tscn"),
	preload("res://scene/actor/player/mess.tscn"),
]

## 可行走带（世界坐标），对应原版第 1 关 A 段的 Y 区间 147/100 的灰盒版
@export var walk_band: Rect2 = Rect2(40, 120, 300, 80)

@onready var actors: Node2D = $Actors
@onready var player: Player = $Actors/Player
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $HUD/StatusLabel

var _swapping_enabled := true


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("fighters"):
		var fighter := node as FightObject
		if fighter != null:
			fighter.play_bounds = walk_band
	camera.make_current()
	# 无头跑断言时不响应换角色，避免把测试对象换掉
	_swapping_enabled = DisplayServer.get_name() != "headless"
	print("测试房就绪：p1_left/right/up/down 移动，p1_attack 出拳，p1_jump 跳跃 / 飞踢")
	print("换角色：1 = Jack，2 = Hannah，3 = Mustapha，4 = Mess")


func _unhandled_input(event: InputEvent) -> void:
	if not _swapping_enabled or not (event is InputEventKey) or event.echo or not event.pressed:
		return
	match event.keycode:
		KEY_1:
			swap_player(0)
		KEY_2:
			swap_player(1)
		KEY_3:
			swap_player(2)
		KEY_4:
			swap_player(3)


## 就地替换玩家场景：位置与可行走带保持不变
func swap_player(index: int) -> void:
	if index >= ROSTER.size() or player == null:
		return
	var where := player.global_position
	var bounds := player.play_bounds
	var next: Player = ROSTER[index].instantiate()
	player.queue_free()
	actors.add_child(next)
	next.name = "Player"
	next.global_position = where
	next.play_bounds = bounds
	player = next
	status_label.text = "已切换：%s" % next.character_stats.display_name


func _physics_process(_delta: float) -> void:
	follow_frontmost_player()
	status_label.text = hud_text()


## doc/07 §摄像机：跟随「最靠前」的玩家（Y 最大 = 离镜头最近）
func follow_frontmost_player() -> void:
	var front: FightObject
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		if not is_instance_valid(node):
			continue
		var candidate := node as FightObject
		if candidate == null or candidate.is_dead:
			continue
		if front == null or candidate.global_position.y > front.global_position.y:
			front = candidate
	if front == null:
		return
	camera.position = (front.global_position + FRONT_MARGIN).round()


func hud_text() -> String:
	var lines: Array[String] = []
	if player != null:
		lines.append("P1 %s  hp %d/%d  力量 %d  状态 %s%s" % [
			player.character_stats.display_name if player.character_stats != null else "?",
			player.hp, player.max_hp, player.power, player.state_machine.current_name(),
			"  [无敌]" if player.is_invincible() else "",
		])
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var monster := node as Enemy
		if monster == null:
			continue
		lines.append("敌 %s  hp %d/%d  状态 %s%s%s" % [
			monster.enemy_stats.display_name if monster.enemy_stats != null else "?",
			monster.hp, monster.max_hp, monster.state_machine.current_name(),
			"  [眩晕免疫]" if monster.is_knockdown_immune() else "",
			"  [死]" if monster.is_dead else "",
		])
	return "\n".join(lines)
