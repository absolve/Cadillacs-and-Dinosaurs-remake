extends Resource
class_name AreaData
## 一个「房间」= 一个数据驱动锁屏段（doc/09 §关卡加载策略，2026-11-06 拍板）。
## 尺寸 / 可行走 Y 带 / 强制偏移照抄 doc/05 §边界机制的 ROM 表。

## ROM 区域名（level1A / level1B / level1C …）
@export var rom_name: StringName = &"level1A"
## 区域尺寸（像素）`[ROMDATA]`（doc/05 §关卡尺寸与规模）
@export var size: Vector2 = Vector2(2268, 300)
## 可行走 Y 带 (y_min, y_max)（区域内相对 Y）。
## ROM 的「上 / 下」相对屏幕还是区域原点 `[待核对]`，本实现按「区域原点相对 Y」解释 TODO[实测]
@export var walk_band_y: Vector2 = Vector2(100, 147)
## 强制偏移 `walkablePositionForceShift` `[ROMDATA]`，含义未逆向，仅登记（doc/05 §③）
@export var force_shift: int = 0
## 本区域的刷怪记录
@export var spawn_records: Array[SpawnRecord] = []
## 敌人组默认 / 最大数量（doc/05 示例：默认 11 / 最大 40），完整预算逻辑在 M5
@export var default_enemy_count: int = 11
@export var max_enemy_count: int = 40

@export_group("背景")
## 远景条图（`sprite/backgrounds/`）：原尺寸 1:1 平铺覆盖区域宽度，底边贴区域底。
## 「场景 S ↔ 区域 A/B/C」映射是 `[推定]` TODO[实测]（doc/09 §关卡加载策略）
@export var far_backgrounds: Array[Texture2D] = []
## 近景条图：渲染压在角色层之上（visibility_layer 5）
@export var near_backgrounds: Array[Texture2D] = []

## 高度超过一屏（224）即纵向卷轴（doc/05：分段高度 > 224 都要按纵向处理）
func vertical_scroll() -> bool:
	return size.y > 224.0
