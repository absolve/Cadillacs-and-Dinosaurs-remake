extends Control
class_name PlayerCard
## HUD 玩家卡片：头像占位 + 血条 + 命数 + 分数（doc/09 §M5 HUD）。
## 尺寸 96 × 28（384 宽正好放 4 张）。头像素材 ROM 未提取 `[待核对]`，先用配色占位；
## 命数 / 分数在 M5 RunState 落地前是占位值。

const SIZE := Vector2(96, 28)
const FACE_COLORS := {
	"Jack": Color(0.25, 0.45, 0.85),
	"Hannah": Color(0.85, 0.35, 0.45),
	"Mustapha": Color(0.3, 0.7, 0.4),
	"Mess": Color(0.75, 0.6, 0.25),
}

var fighter: FightObject
var lives: int = 3          # `[推定]` TODO[实测]（原版初始 3 支）
var score: int = 0          # 占位分值（doc/09 §数据准备清单）
var hp_ratio := 1.0


func bind(new_fighter: FightObject) -> void:
	if fighter == new_fighter:
		return
	if fighter != null and fighter.hp_changed.is_connected(_on_hp_changed):
		fighter.hp_changed.disconnect(_on_hp_changed)
		fighter.tree_exiting.disconnect(_unbind)
	fighter = new_fighter
	if fighter == null:
		hp_ratio = 1.0
		queue_redraw()
		return
	hp_ratio = float(fighter.hp) / maxf(float(fighter.max_hp), 1.0)
	fighter.hp_changed.connect(_on_hp_changed)
	fighter.tree_exiting.connect(_unbind)
	if fighter.character_stats != null:
		pass  # 名称直接从 character_stats 读，无需缓存


func _unbind() -> void:
	bind(null)


func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_ratio = float(current_hp) / maxf(float(max_hp), 1.0)
	queue_redraw()


func _draw() -> void:
	var face: Color = FACE_COLORS.get(display_name(), Color(0.5, 0.5, 0.55))
	# 底板
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.08, 0.08, 0.1, 0.85))
	# 头像占位（20 × 20 左对齐）
	draw_rect(Rect2(Vector2(2, 4), Vector2(20, 20)), face)
	# 血条：白底 + 红黄渐变填充（原版血条为绿色分段，样式待对照录像 `[待核对]`）
	var bar := Rect2(25, 6, 66, 7)
	draw_rect(bar, Color(0.85, 0.85, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(hp_ratio, 0.0, 1.0), bar.size.y)),
			Color(0.25, 0.75, 0.3) if hp_ratio > 0.3 else Color(0.85, 0.3, 0.2))
	# 命数 / 分数（占位，小字号）
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(25, 20), "×%d" % lives, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.9, 0.9, 0.9))
	draw_string(font, Vector2(25, 26), "%06d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
			Color(0.7, 0.8, 0.9))
	# 死亡灰化
	if fighter != null and fighter.is_dead:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0, 0, 0, 0.6))


func display_name() -> String:
	var player := fighter as Player
	if player != null and player.character_stats != null:
		return player.character_stats.display_name
	return ""
