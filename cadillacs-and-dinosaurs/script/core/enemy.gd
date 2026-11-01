extends "res://script/core/fight_object.gd"
class_name Enemy
## 敌人对象：在 [FightObject] 之上加「选目标 + 冷却」这两件笨事。
##
## AI 的**决策**放在状态里（`script/state/enemy/`），本类只提供查询与计时；
## 原版杂兵就是「成排走近、攻击欲望低」，不要在这里写聪明逻辑（doc/09 §M5）。

const GROUP: StringName = &"enemies"
## 目标重选间隔（帧）：不必每帧扫描全场
const TARGET_REFRESH_FRAMES: int = 20
## 死亡后停留多久再释放（帧），留出演出与掉落的时间
const CORPSE_FRAMES: int = 90

@export var enemy_stats: EnemyStats:
	set(value):
		enemy_stats = value
		if is_node_ready():
			_apply_stats()

## 追击 / 出招 / 对齐容差等（来自 [EnemyStats]，场景里可直接覆盖做实验）
@export var aggro_range: float = 260.0
@export var attack_range: float = 34.0
@export var align_tolerance: float = 12.0
@export var attack_cooldown_frames: int = 45
## 出招前摇（给玩家反应时间）
@export var attack_windup_frames: int = 18

## 当前追击目标（最近的存活玩家）
var target: FightObject
var cooldown_frames: int = 0
var _refresh_counter: int = 0


func _ready() -> void:
	side = FightObject.FighterSide.ENEMY
	add_to_group(GROUP)
	super._ready()
	_apply_stats()
	died.connect(_on_died)


func _apply_stats() -> void:
	if enemy_stats == null:
		return
	stats = enemy_stats
	max_hp = enemy_stats.max_hp
	hp = enemy_stats.max_hp
	move_speed = enemy_stats.move_speed
	depth_speed_factor = enemy_stats.depth_speed_factor
	jump_speed = enemy_stats.jump_speed
	gravity = enemy_stats.gravity
	aggro_range = enemy_stats.aggro_range
	attack_range = enemy_stats.attack_range
	align_tolerance = enemy_stats.align_tolerance
	attack_cooldown_frames = enemy_stats.attack_cooldown_frames
	attack_windup_frames = enemy_stats.attack_windup_frames
	can_be_grabbed = enemy_stats.can_be_grabbed
	can_be_knocked_down = enemy_stats.can_be_knocked_down
	moves = enemy_stats.moves


func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)
	cooldown_frames = maxi(cooldown_frames - 1, 0)
	_refresh_counter += 1
	if _refresh_counter >= TARGET_REFRESH_FRAMES or target == null or target.is_dead:
		_refresh_counter = 0
		target = nearest_player()


# ---------------------------------------------------------------- 目标与距离

func nearest_player() -> FightObject:
	var best: FightObject
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		var player := node as FightObject
		if player == null or player.is_dead:
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best


## 横向已进入攻击距离
func in_attack_range() -> bool:
	return target != null \
			and absf(target.global_position.x - global_position.x) <= attack_range


## 纵深已对齐（同一排），差太多就该先走位
func depth_aligned() -> bool:
	return target != null and depth_gap(target) <= align_tolerance


func target_in_aggro() -> bool:
	return target != null and not target.is_dead \
			and global_position.distance_to(target.global_position) <= aggro_range


## 指向目标的单位方向（横向 + 纵深）
func direction_to_target() -> Vector2:
	if target == null:
		return Vector2.ZERO
	var delta := target.global_position - global_position
	return Vector2(signf(delta.x), signf(delta.y))


# ---------------------------------------------------------------- 出招节奏

func can_attack() -> bool:
	return cooldown_frames == 0 and in_attack_range() and depth_aligned()


func on_attack_started() -> void:
	cooldown_frames = attack_cooldown_frames


## 敌人默认用招式表第一段；表为空时按 `damage` 合成一个，保证一定打得出去
func primary_attack() -> MoveData:
	if not moves.is_empty():
		return moves[0]
	var fallback := MoveData.new()
	fallback.id = &"enemy_attack"
	fallback.action = &"attack1"
	fallback.startup = attack_windup_frames
	fallback.active = 4
	fallback.recovery = 12
	fallback.damage = enemy_stats.damage if enemy_stats != null else 8
	return fallback


func _on_died() -> void:
	set_physics_process(false)
	state_machine.enabled = false
	hurtbox.set_deferred("monitorable", false)
	get_tree().create_timer(CORPSE_FRAMES / 60.0).timeout.connect(queue_free)
