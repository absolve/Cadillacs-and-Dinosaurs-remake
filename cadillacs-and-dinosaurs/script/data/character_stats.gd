extends Resource
class_name CharacterStats
## 一名可操作角色的数值（doc/08 §1 的 ROM 实值 + doc/07 §三的 `[推定]` 帧数）。

## 原版存档槽 `+0x03` 的角色 ID：Jack 0 / Mustapha 1 / Hannah 2 / Mess 3
@export var rom_id: int = 0
@export var display_name: String = "Jack"
## 初始 / 最大 HP —— 四人都是 100 `[ROMDATA]`
@export var max_hp: int = 100
## 横向移速 px/s `[推定]` TODO[实测]（doc/07 §一：移速未提取）
@export var move_speed: float = 96.0
## 纵深（上下）速度系数，清版动作游戏的经典透视减速
@export var depth_speed_factor: float = 0.6
## 起跳初速度 px/s `[推定]` TODO[实测]
@export var jump_speed: float = 330.0
## 伪 Z 轴重力 px/s² `[推定]` TODO[实测]
@export var gravity: float = 980.0
## 力量基准 32 `[ROMDATA]`（doc/08 §2：被击中时重掷，伤害 × 力量/32）
@export var power: int = 32
## 三段连击与派生招式的帧数 / 伤害表
@export var moves: Array[MoveData] = []
## 必杀技伤害 `[ROMDATA]` 20/20/20/23
@export var special_damage: int = 20
## 必杀技自身消耗 `[ROMDATA]` 10 + 4 = 14，且命中才扣
@export var special_cost: int = 14
## 必杀技命中后的无敌帧数 `[ROMDATA]` 60
@export var special_invincible_frames: int = 60
