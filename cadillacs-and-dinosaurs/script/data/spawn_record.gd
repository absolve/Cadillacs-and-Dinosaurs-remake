extends Resource
class_name SpawnRecord
## 一条刷怪记录 —— 镜像 ROM 定长 16 字节结构（doc/05 §刷怪记录结构）。
## 灰盒阶段由 [StageDirector] 按「屏幕出现区间」直接触发；
## 完整刷怪器（默认 11 / 最大 40、槽位预算、`mustHaveSpawnDelayTime`）在 M5 接入。

@export_group("触发")
## 屏幕出现区间起点（区域内相对 X，[ROMDATA] 例：第 1 关第 1 组 = 920）。
## 摄像机左缘 + 视野宽 ≥ 该值时触发本条
@export var trigger_x: float = 0.0
## 锁组（lockGroup*）：触发后冻结摄像机，清完本批敌人才解锁（doc/05 §④）
@export var locks_screen: bool = false
## 延迟帧（TS：本条是锁时作为帧延迟）`[待核对]` TODO[实测]
@export var delay_frames: int = 0

@export_group("对象（16 字节字段）")
## 物件类型（B1 低位）：0 敌人 / 1 其他 / 3 木桶或宝物
@export_range(0, 3) var object_type: int = 0
## 人数标记（B1 高位）：0 总是生成 / 4 = 2 人以上 / 6 = 3 人（ROM 原值）；
## 8 = 4 人以上（**改版新档**：本项目 4 人同屏，doc/09 §改版拍板）
## ——「多人时敌人更多」就靠它过滤，不需要额外难度逻辑（doc/05）
@export var count_flag: int = 0
## 物件 / 敌人 ID（OI，对照 doc/08 §5）。M5 的 OI→场景映射表落地后以此为准
@export var object_id: StringName = &"ferris"
## 生成目标（灰盒直引；正式流程改为按 object_id 查表）
@export var scene: PackedScene
## 生成位置（PX / PY，相对区域原点）
@export var spawn_pos: Vector2 = Vector2.ZERO
## 动作 / 姿态（AI）
@export var pose: int = 0
## 子类型（SI）
@export var sub_type: int = 0
## 恐龙数量上限（DL）
@export var dino_limit: int = 0
## 掉落 ID（DI，查 doc/08 §8 掉落表；10~13 是原版崩溃项，**不复现**）
@export var drop_id: int = 0
## 智能 / 攻击性（IL）
@export var intelligence: int = 0
## 不参与边界夹取（对应原版 `noLevelLimits`，例：第 6 关恐龙脚，doc/05 §例外）
@export var no_level_limits: bool = false
