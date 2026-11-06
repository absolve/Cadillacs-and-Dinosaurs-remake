extends Resource
class_name StageData
## 一关 = 按顺序横向排列的房间（[AreaData]）序列（doc/09 §关卡加载策略）。
## 房间不是独立 `.tscn`：这里只是数据单元，演出 / 驾驶等房间类型后续扩展。

@export var stage_number: int = 1
@export var display_name: String = "City in the Sea"
## 区域序列，StageDirector 按此顺序累计排布 X 原点
@export var areas: Array[AreaData] = []
