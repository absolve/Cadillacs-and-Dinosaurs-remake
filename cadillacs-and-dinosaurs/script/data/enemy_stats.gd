extends Resource
class_name EnemyStats
## 一个敌人的数值与笨 AI 参数（doc/09 §M5：敌人 AI **不要写聪明**）。

@export var id: StringName = &"ferris"
@export var display_name: String = "Ferris"
## HP：投刀者 12 `[ROMDATA]`；其余 `[推定]` TODO[实测]
@export var max_hp: int = 8
@export var move_speed: float = 52.0
@export var depth_speed_factor: float = 0.6
@export var jump_speed: float = 300.0
@export var gravity: float = 980.0
## 单次攻击伤害 `[推定]` TODO[实测]（先按「连击 3~4 刀死杂兵」反推）
@export var damage: int = 8
## 进入该距离后开始追击（px）
@export var aggro_range: float = 260.0
## 该距离内才出招（px，横向）
@export var attack_range: float = 34.0
## 纵深对齐容差（px），两侧 Y 差在此之内才算「同一排」
@export var align_tolerance: float = 12.0
## 出招后的冷却帧数 `[推定]`
@export var attack_cooldown_frames: int = 45
## 攻击前摇帧数（笨 AI 的「给玩家反应时间」）
@export var attack_windup_frames: int = 18
## 可抓取（原版部分敌人不可抓）
@export var can_be_grabbed: bool = true
## 可被击倒
@export var can_be_knocked_down: bool = true
## 被击倒后的眩晕免疫窗口 `[ROMDATA]` 60 帧（doc/07 §三）
@export var knockdown_immune_frames: int = 60
## 同屏槽位预算（杂兵 1，见 doc/07 §同屏敌人槽位预算）
@export var slots: int = 1
## 分数占位（按稀有度递增，doc/09 §数据准备清单）
@export var score_value: int = 100
## 招式表（为空时基类用 `damage` 合成一个默认攻击）
@export var moves: Array[MoveData] = []
