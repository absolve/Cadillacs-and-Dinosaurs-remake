extends Node2D
class_name FighterShadow
## 贴地阴影：挂在根节点（脚底），**不随伪 Z 轴（Body 抬升）上升**；
## 高度越大越小、越淡，给跳跃提供地面参照（清版动作可读性件）。
## 样式为占位 `[推定]` TODO[实测]：ROM 影子帧未提取，先用黑色椭圆。

const BASE := Vector2(22, 6)
const FADE_HEIGHT := 140.0

var fighter: FightObject


func _ready() -> void:
	fighter = get_parent() as FightObject


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if fighter == null:
		return
	var k := clampf(1.0 - fighter.height() / FADE_HEIGHT, 0.5, 1.0)
	var half := BASE * 0.5 * k
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i) / 20.0
		points.append(Vector2(cos(angle) * half.x, sin(angle) * half.y))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.45 * k))
