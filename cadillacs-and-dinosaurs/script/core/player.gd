extends "res://script/core/fight_object.gd"
class_name Player
## 玩家对象：在 [FightObject] 之上接输入与「力量」重掷。
##
## 输入用 `p1_*` / `p2_*` / `p3_*` 前缀（project.godot 已配好），
## 状态里只通过 [method axis] / [method pressed] / [method buffered_attack] 读取，
## 不直接碰 `Input`，方便无头测试注入事件、以后接手柄与 AI 代打。

const GROUP: StringName = &"players"
## 输入缓冲窗口（帧）`[推定]`，见 doc/07 §输入缓冲
const BUFFER_FRAMES: int = 12

## 第几位玩家（0 基），决定按键前缀
@export var player_index: int = 0
## 难度块 1~4：决定力量重掷能取到的范围（doc/08 §2）
@export var power_block: int = 3
@export var character_stats: CharacterStats:
	set(value):
		character_stats = value
		if is_node_ready():
			_apply_stats()

var _attack_buffer: int = 0
var _jump_buffer: int = 0


func _ready() -> void:
	side = FightObject.FighterSide.PLAYER
	add_to_group(GROUP)
	super._ready()
	_apply_stats()
	Game.player_registered.emit(self)


func _apply_stats() -> void:
	if character_stats == null:
		return
	stats = character_stats
	max_hp = character_stats.max_hp
	hp = character_stats.max_hp
	move_speed = character_stats.move_speed
	depth_speed_factor = character_stats.depth_speed_factor
	jump_speed = character_stats.jump_speed
	gravity = character_stats.gravity
	power = character_stats.power
	moves = character_stats.moves


func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)
	_attack_buffer = maxi(_attack_buffer - 1, 0)
	_jump_buffer = maxi(_jump_buffer - 1, 0)


func key_prefix() -> String:
	return "p%d" % (player_index + 1)


# ---------------------------------------------------------------- 输入

## 八向输入原始轴值（未归一化，斜向为 (±1, ±1)）
func axis() -> Vector2:
	return Vector2(
			Input.get_axis("%s_left" % key_prefix(), "%s_right" % key_prefix()),
			Input.get_axis("%s_up" % key_prefix(), "%s_down" % key_prefix()))


func pressed(action: StringName) -> bool:
	return Input.is_action_pressed("%s_%s" % [key_prefix(), action])


func attack_action() -> StringName:
	return StringName("%s_attack" % key_prefix())


func jump_action() -> StringName:
	return StringName("%s_jump" % key_prefix())


## 攻击键在缓冲窗口内被按下过（消费后清空）
func buffered_attack() -> bool:
	return _attack_buffer > 0


func consume_attack() -> void:
	_attack_buffer = 0


func buffered_jump() -> bool:
	return _jump_buffer > 0


func consume_jump() -> void:
	_jump_buffer = 0


## 清空输入缓冲（受击、关卡演出、测试复位时用）
func clear_buffers() -> void:
	_attack_buffer = 0
	_jump_buffer = 0


# 把 just_pressed 转成缓冲计数：状态机在 _physics_process 里判定，
# 一帧内可能错过 just_pressed，记进缓冲就不会丢输入。
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(attack_action()):
		_attack_buffer = BUFFER_FRAMES
	elif event.is_action_pressed(jump_action()):
		_jump_buffer = BUFFER_FRAMES


# ---------------------------------------------------------------- 力量

## 被击中后重掷力量（doc/08 §2）：满血几乎不变，残血大概率变
func _after_take_damage() -> void:
	if character_stats == null:
		return
	var lost_ratio := float(max_hp - hp) / maxf(max_hp, 1.0)
	power = PowerTable.roll(power_block, power, lost_ratio)
