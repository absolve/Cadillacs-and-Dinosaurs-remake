extends CharacterBody2D
class_name FightObject
## 战斗对象基类：血量 / 力量 / 朝向 / 伪 Z 轴跳跃 / 判定盒结算 / 可行走范围夹取。
##
## 玩家（[Player]）与敌人（[Enemy]）都继承本类，具体行为由 `$StateMachine`
## 子树上的 [FightState] 节点驱动。本类只提供**通用能力**，角色专属逻辑一律下沉子类。
##
## 场景必需的子节点结构（路径写死，与 `scene/actor/**.tscn` 一致）：
##
## ```
## <FightObject>              CharacterBody2D，y_sort 由父容器开启
## └── Body                   Node2D，伪 Z 轴靠它的 position.y 抬升
##     ├── Sprite             AnimatedSprite2D
##     ├── Hitbox             Area2D + CollisionShape2D（攻击判定）
##     └── Hurtbox            Area2D + CollisionShape2D（受击盒）
## └── StateMachine           StateMachine + 若干 FightState 子节点
## ```
##
## 计时约定：所有时间用**物理帧**计数（原版 59.6 Hz，doc/07 §三「1 帧 = 1 物理帧」），
## 不依赖动画结束信号，保证无头测试与掉帧时行为一致。

signal hp_changed(current_hp: int, max_hp: int)
signal damage_dealt(target: FightObject, amount: int)
signal died

enum FighterSide { PLAYER, ENEMY }

@export_group("身份")
## 阵营：决定判定层与「不打自己人」
@export var side: FighterSide = FighterSide.ENEMY
## 数值来源（[CharacterStats] / [EnemyStats]），由子类的 `_apply_stats` 读取
@export var stats: Resource

@export_group("战斗数值")
@export var max_hp: int = 100
@export var hp: int = 100
## 力量基准 32；最终伤害 = 基础 × 力量 / 32（doc/08 §2）
@export var power: int = 32
@export var can_be_knocked_down: bool = true
@export var can_be_grabbed: bool = true
## 同屏敌人槽位预算见 doc/07 §同屏敌人槽位预算（刷怪系统负责，这里只留字段）
@export var slots: int = 1
## 被击倒后的眩晕免疫窗口 `[ROMDATA]` 60 帧（doc/07 §三）
@export var knockdown_immune_frames: int = 60
## 招式表（玩家来自 [CharacterStats]，敌人来自 [EnemyStats]）
@export var moves: Array[MoveData] = []

@export_group("受击计时")
## 受击硬直帧数 `[推定]`（doc/07 §三）
@export var hurt_stun_frames: int = 12
## 倒地帧数 `[推定]`
@export var down_frames: int = 30
## 起身帧数 `[推定]`（起身期间无敌）
@export var rise_frames: int = 14
## 受击击退初速度 px/s `[推定]`
@export var knockback_speed: float = 220.0
## 击退衰减 px/s² `[推定]`
@export var knockback_decay: float = 1400.0

@export_group("移动")
@export var move_speed: float = 96.0
## 纵深（屏幕 Y）相对横向的速度系数
@export var depth_speed_factor: float = 0.6
@export var jump_speed: float = 330.0
## 空中操控系数（越小越「笨重」）`[推定]`
@export var air_control_factor: float = 0.7
@export var gravity: float = 980.0
## 可行走矩形（世界坐标）；`size` 为零表示不限制。关卡区域数据写入
@export var play_bounds: Rect2 = Rect2()

@export_group("动画映射")
## 按 **ROM 动画组号** 索引的动画集：数组下标就是组号（组 0 = 基础组）。
## `[ROMDATA]` doc/10 §8.11 实测：玩家对象一轮对战同时用到组 0/1/3/5
## （Jack `set000/001/003/005`、Hannah `set012/013/015/017`），
## 所以「一个角色 = 一个动画集」的假设是错的；敌人只走 `0x120E`，一组即可。
@export var anim_groups: Array[DinoAnimSet] = []
## 动作键 → 动画引用 `"gN/actMM"`（N = 组号；MM = **十进制**段号，等于 ROM 里的 `D0`，
## 如 `D0=0x0d` → `act13`）。表值来自 doc/10 §8.11 实测状态表，
## 未实测到的键保留 `[推定]`（`down` / `rise` / `die`）。
@export var act_map: Dictionary = {
	"idle": "g0/act00", "walk": "g0/act01", "run": "g0/act09",
	"attack1": "g0/act03", "attack2": "g0/act06", "attack3": "g1/act12",
	"jump": "g1/act00", "fall": "g1/act02", "kick": "g1/act08",
	"hurt": "g0/act13", "stunned": "g0/act13",
	"down": "g0/act07", "rise": "g0/act07", "die": "g0/act12",
	# 以下为 doc/10 §8.7 看图判定 / §8.9 组语义的槽位（抓取 = §8.11 实测 g5:12），
	# 状态实现落地于 M3（抓取/投技/冲刺攻击）与 M6（胜利），未实测键仍为 `[推定]`
	"dash_attack": "g0/act27", "roll": "g0/act20", "thrown": "g0/act26",
	"grab": "g5/act12", "grab_hold": "g2/act00", "throw": "g2/act02",
	"victory": "g3/act03",
}

## 朝向：1 = 右，-1 = 左（对应 ROM `+0x24`，0=左 / 1=右）。
## 人物 / 敌人素材已按项目口径**朝右**存储（tools/flip_facing.gd 就地翻转），
## 因此 `face_dir=-1`（朝左）时运行时镜像
var face_dir: int = 1
var in_air: bool = false
## 伪 Z 轴（离地）速度 px/s，负值向上
var z_velocity: float = 0.0
var is_dead: bool = false
## 不吃伤害的剩余帧数（起身无敌、必杀后无敌）
var invincible_left: int = 0
## 不吃击倒 / 眩晕但仍吃伤害的剩余帧数
var knockdown_immune_left: int = 0
## 当前正在显示的动画集（= 某个 `anim_groups[i]`），供直接播放路径记录
var active_set: DinoAnimSet

@onready var body: Node2D = $Body
@onready var sprite: AnimatedSprite2D = $Body/Sprite
@onready var animation_tree: AnimationTree = get_node_or_null("AnimationTree") as AnimationTree
@onready var hitbox: Area2D = $Body/Hitbox
@onready var hurtbox: Area2D = $Body/Hurtbox
@onready var hitbox_shape: CollisionShape2D = $Body/Hitbox/Shape
@onready var hurtbox_shape: CollisionShape2D = $Body/Hurtbox/Shape
@onready var state_machine: StateMachine = $StateMachine

# 本次挥击的自增编号与已命中目标（doc/07：同一次挥击对同一目标只结算一次）
var _hit_id: int = 0
var _hit_targets: Array[FightObject] = []


func _ready() -> void:
	add_to_group("fighters")
	hurtbox.set_meta("fighter", self)
	hitbox.set_meta("fighter", self)
	# 受击盒只被检测；攻击盒常开监测，命中与否由招式在判定帧主动取重叠
	hurtbox.monitoring = false
	hitbox.monitoring = true
	hitbox.monitorable = false
	play_action(&"idle")


@export_group("慢放")
## 个体慢放步长：1 = 正常；N = 每 N 物理帧推进 1 有效帧（doc/09 §演出慢放设计）
var self_slow_step: int = 1
## 剩余有效帧数（按有效帧倒计时）
var _self_slow_left: int = 0
var _tick_acc: int = 0
var _is_local_tick: bool = false
## 已推进的有效帧计数（测试与调试用）
var local_ticks: int = 0


## 个体慢放 `[推定]` TODO[实测]（帧数待对照原版录像）
func start_self_slow(step: int, effective_frames: int) -> void:
	self_slow_step = clampi(step, 1, 8)
	_self_slow_left = maxi(_self_slow_left, effective_frames)


## 有效步长 = 个体 × 全屏（两者相乘，取值 1..16）
func local_step() -> int:
	var s := self_slow_step if _self_slow_left > 0 else 1
	return s * Game.world_step


## 本物理帧是否推进逻辑（[StateMachine] 分发前查询）
func is_local_tick() -> bool:
	return _is_local_tick


func _physics_process(_delta: float) -> void:
	_tick_acc += 1
	var step := local_step()
	# 动画与逻辑同缩放（每物理帧刷新，保证慢放开始/结束即时生效）
	sprite.speed_scale = 1.0 / float(step)
	if _tick_acc < step:
		_is_local_tick = false
		return
	_tick_acc -= step
	_is_local_tick = true
	local_ticks += 1
	_self_slow_left = maxi(_self_slow_left - 1, 0)
	if _self_slow_left == 0:
		self_slow_step = 1
	invincible_left = maxi(invincible_left - 1, 0)
	knockdown_immune_left = maxi(knockdown_immune_left - 1, 0)


# ---------------------------------------------------------------- 动画

## `"gN/actMM"` 拆成 `[组号, 段名]`；没有 `gN/` 前缀的写法按组 0 处理
static func split_anim_ref(ref: String) -> Array:
	if ref.begins_with("g") and "/" in ref:
		var parts := ref.split("/")
		return [parts[0].substr(1).to_int(), parts[1]]
	return [0, ref]


## 组号 → 动画集；该组没挂上时返回 `null`
func set_of_group(group: int) -> DinoAnimSet:
	return anim_groups[group] if group >= 0 and group < anim_groups.size() else null


## 校验并规范化引用：段真的挂在本对象上时返回 `"gN/actMM"`，否则返回空串
func ref_or_empty(ref: String) -> String:
	var parts := split_anim_ref(ref)
	var anim_set := set_of_group(int(parts[0]))
	if anim_set == null or anim_set.sprite_frames == null \
			or not anim_set.sprite_frames.has_animation(String(parts[1])):
		return ""
	return "g%d/%s" % [int(parts[0]), String(parts[1])]


## 动作键（`idle` / `attack1` …）解析成可用的动画引用；
## `act_map` 落空时退回同名段，再退回任一可用组的首段
func ref_of(action: StringName) -> String:
	for candidate: String in [String(act_map.get(action, "")), String(action)]:
		var resolved := ref_or_empty(candidate)
		if resolved != "":
			return resolved
	for group: int in anim_groups.size():
		var anim_set := set_of_group(group)
		if anim_set != null and anim_set.sprite_frames != null:
			var names := anim_set.sprite_frames.get_animation_names()
			if names.size() > 0:
				return "g%d/%s" % [group, names[0]]
	return ""


## 当前正在播放的动画引用（调试与断言用）
func anim_ref() -> String:
	var combined_parts := sprite.animation.split("_", false, 1)
	if combined_parts.size() == 2 and combined_parts[0].begins_with("g") \
			and combined_parts[0].substr(1).is_valid_int():
		return "%s/%s" % [combined_parts[0], combined_parts[1]]
	for group: int in anim_groups.size():
		var set1 := set_of_group(group)
		if set1 != null and set1.sprite_frames == sprite.sprite_frames:
			return "g%d/%s" % [group, sprite.animation]
	return "g?/%s" % sprite.animation


func has_action(action: StringName) -> bool:
	return ref_of(action) != ""


func _animation_playback() -> AnimationNodeStateMachinePlayback:
	if animation_tree == null or not animation_tree.active:
		return null
	return animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


## 按动作键切换 AnimationTree 状态；没有动画树的对象（如敌人）沿用直接播放。
func play_action(action: StringName) -> StringName:
	var ref := ref_of(action)
	if ref == "":
		return &""
	var playback := _animation_playback()
	var state_machine_root: AnimationNodeStateMachine
	if animation_tree != null:
		state_machine_root = animation_tree.tree_root as AnimationNodeStateMachine
	if playback == null or state_machine_root == null or not state_machine_root.has_node(action):
		return _apply_anim_ref(ref)
	if playback.get_current_node() != action:
		playback.start(action, true)
	var parts := split_anim_ref(ref)
	return StringName(String(parts[1]))


## 播放「gN/actMM」引用：需要时换 sprite 数据源，并重置到首帧 + 按该段脚底锚点对齐
func play_anim_ref(ref: String) -> StringName:
	var parts := split_anim_ref(ref)
	var set1 := set_of_group(int(parts[0]))
	if set1 == null or set1.sprite_frames == null:
		return &""
	return _apply_anim_ref(ref)


func _apply_anim_ref(ref: String) -> StringName:
	var parts := split_anim_ref(ref)
	var set1 := set_of_group(int(parts[0]))
	if set1 == null or set1.sprite_frames == null:
		return &""
	var anim := String(parts[1])
	if sprite.sprite_frames != set1.sprite_frames:
		sprite.sprite_frames = set1.sprite_frames
	if active_set != set1 or sprite.animation != anim:
		sprite.animation = anim
		sprite.frame = 0
	active_set = set1
	sprite.centered = false
	if set1.acts.has(anim):
		sprite.offset = -set1.anchor_of(anim)
	sprite.flip_h = face_dir < 0
	sprite.play(anim)
	return StringName(anim)


## 招式起手动画：优先 `MoveData.start_anim`，否则回落到动作键 `[ROMDATA]` doc/10 §8.11
func play_move_start(move: MoveData) -> StringName:
	if move == null:
		return &""
	return play_anim_ref(move.start_anim) if move.start_anim != "" else play_action(move.action)


## 招式命中段动画：`hit_anim` 为空表示整招只有一段
func play_move_hit(move: MoveData) -> void:
	if move != null and move.hit_anim != "":
		play_anim_ref(move.hit_anim)


# ---------------------------------------------------------------- 朝向

func set_face_dir(direction: float) -> void:
	if is_zero_approx(direction):
		return
	var next := 1 if direction > 0.0 else -1
	if next == face_dir:
		return
	face_dir = next
	# 素材已按项目口径就地翻成朝右存储（tools/flip_facing.gd）：朝左时才镜像
	sprite.flip_h = face_dir < 0
	# 攻击盒翻到身体另一侧
	hitbox_shape.position.x = absf(hitbox_shape.position.x) * face_dir


func face_target(target: Node2D) -> void:
	if target != null:
		set_face_dir(target.global_position.x - global_position.x)


# ---------------------------------------------------------------- 移动

## 把方向输入换算成速度：纵深方向按系数减速
func velocity_from_input(input_dir: Vector2, control: float = 1.0) -> Vector2:
	return Vector2(input_dir.x * move_speed, input_dir.y * move_speed * depth_speed_factor) * control


func move_by(input_dir: Vector2, control: float = 1.0) -> void:
	velocity = velocity_from_input(input_dir, control)
	if not is_zero_approx(input_dir.x):
		set_face_dir(input_dir.x)
	move_and_slide()
	clamp_to_bounds()


func clamp_to_bounds() -> void:
	if play_bounds.size == Vector2.ZERO:
		return
	global_position.x = clampf(global_position.x, play_bounds.position.x, play_bounds.end.x)
	global_position.y = clampf(global_position.y, play_bounds.position.y, play_bounds.end.y)


# ---------------------------------------------------------------- 伪 Z 轴（跳跃）

## 起跳：只给竖直（屏幕外）速度，横向惯性由调用方保留
func start_jump() -> void:
	in_air = true
	z_velocity = -jump_speed


## 推进浮空偏移并施加；落地时归零并返回 true
func apply_gravity(delta: float) -> bool:
	if not in_air:
		return false
	z_velocity += gravity * delta
	body.position.y = minf(body.position.y + z_velocity * delta, 0.0)
	if body.position.y >= 0.0:
		body.position.y = 0.0
		z_velocity = 0.0
		in_air = false
		return true
	return false


## 当前离地高度（px，正数表示在空中）
func height() -> float:
	return -body.position.y


# ---------------------------------------------------------------- 判定盒

## 开始一次挥击：重置命中记录、按招式摆好攻击盒
func begin_attack(move: MoveData) -> void:
	_hit_id += 1
	_hit_targets.clear()
	configure_hitbox(move)


func configure_hitbox(move: MoveData) -> void:
	if move == null:
		return
	var rect := move.hitbox_rect
	# 复用场景里的矩形形状，只改尺寸与偏移（朝向翻转时 x 取反，与 ROM 判定一致）
	var shape := hitbox_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		hitbox_shape.shape = shape
	shape.size = rect.size
	hitbox_shape.position = Vector2(
			(rect.position.x + rect.size.x * 0.5) * face_dir,
			rect.position.y + rect.size.y * 0.5)


func set_hitbox_enabled(enabled: bool) -> void:
	hitbox_shape.set_deferred("disabled", not enabled)


## 在判定帧调用：取当前重叠的可伤害目标并结算，返回本次真正命中的目标
func resolve_hits(move: MoveData, source_damage: int = -1) -> Array[FightObject]:
	var landed: Array[FightObject] = []
	if move == null or is_dead:
		return landed
	var base_damage := source_damage if source_damage >= 0 else move.damage
	var scaled := PowerTable.scale(base_damage, power)
	for area in hitbox.get_overlapping_areas():
		var target := area.get_meta("fighter") as FightObject
		if target == null or target == self or target.side == side:
			continue
		if target in _hit_targets:
			continue
		# 高度轴：从头顶掠过不该命中（ROM 的三轴相交，见 doc/10 §1.4）
		if absf(target.height() - height()) > move.height_tolerance:
			continue
		_hit_targets.append(target)
		target.take_damage(scaled, face_dir, move.knockdown, self)
		landed.append(target)
		damage_dealt.emit(target, scaled)
	return landed


# ---------------------------------------------------------------- 受击

func take_damage(amount: int, from_dir: int = 0, knockdown: bool = false, _source: FightObject = null) -> void:
	if is_dead or invincible_left > 0:
		return
	# 眩晕免疫窗口内仍吃伤害，只是不再被击倒 / 眩晕
	if knockdown_immune_left > 0:
		knockdown = false
	hp = clampi(hp - amount, 0, max_hp)
	hp_changed.emit(hp, max_hp)
	_after_take_damage()
	if hp <= 0:
		# 击杀慢放：死者 1/3 × 18 有效帧，凶手 1/3 × 6 有效帧 `[推定]` TODO[实测]
		if _source != null:
			_source.start_self_slow(3, 6)
		start_self_slow(3, 18)
		die()
		return
	var data := { "damage": amount, "push_dir": from_dir, "knockdown": knockdown }
	if knockdown and can_be_knocked_down:
		state_machine.transition_to("Down", data)
	else:
		state_machine.transition_to("Hurt", data)


## 子类钩子：玩家在这里重掷力量（doc/08 §2「被击中时重掷」）
func _after_take_damage() -> void:
	pass


func die() -> void:
	if is_dead:
		return
	is_dead = true
	hp = 0
	hp_changed.emit(hp, max_hp)
	set_hitbox_enabled(false)
	velocity = Vector2.ZERO
	play_action(&"die")
	# 玩家死亡：全屏慢放 1/4 × 45 物理帧 `[推定]` TODO[实测]
	if side == FighterSide.PLAYER:
		Game.set_world_slow(4, 45)
	died.emit()


# ---------------------------------------------------------------- 查询

## 按动作键取招式数据（找不到返回 null）
func move_of(action: StringName) -> MoveData:
	for move in moves:
		if move.action == action:
			return move
	return null


func distance_to(other: Node2D) -> float:
	return global_position.distance_to(other.global_position) if other != null else INF


## 纵深（屏幕 Y）差值，用于「是否站在同一排」
func depth_gap(other: Node2D) -> float:
	return absf(global_position.y - other.global_position.y) if other != null else INF


## 进入不吃伤害的无敌（起身、必杀后等）
func make_invincible(frames: int) -> void:
	invincible_left = maxi(invincible_left, frames)


## 进入「可被打但不再被击倒」的免疫窗口（原版击倒后 60 帧）
func make_knockdown_immune() -> void:
	knockdown_immune_left = maxi(knockdown_immune_left, knockdown_immune_frames)


func is_invincible() -> bool:
	return invincible_left > 0


func is_knockdown_immune() -> bool:
	return knockdown_immune_left > 0
