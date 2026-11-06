extends Node
## StageDirector —— 关卡「房间驱动器」单例（doc/09 §关卡加载策略，2026-11-06 拍板）。
##
## 职责（对应 doc/05 §边界机制四层）：
## ① 摄像机 X 夹在 `[0, 区域宽 − 384]`（纵向段同理夹 Y）；
## ② 玩家 X 夹在当前视野内（边距 `[推定]`）；
## ③ 可行走 Y 带按区域写入所有战斗对象的 `play_bounds`；
## ④ 触发线进入 lock 组 → 摄像机冻结 → 「已生成敌人」全部打倒才解锁。
##
## 房间是数据单元（[AreaData]），不是独立场景；本关所有房间常驻根场景，
## 出视野的对象由刷怪器负责释放（视野 ±1 房间的流式加载，M5 完善）。

signal area_changed(index: int)
signal screen_locked(locked: bool)

## CPS-1 视野常量（doc/05 §四层机制表）
const VIEW := Vector2(384, 224)
## 玩家距视野左右边距 `[推定]` TODO[实测]（doc/05 §②「具体值待核对」）
const PLAYER_EDGE_MARGIN := 16.0

var stage: StageData
## 各区域在世界坐标的原点（本实现横向排列，Y = 0）
var area_offsets: Array[Vector2] = []
var current_area: int = 0
## 每条刷怪记录是否已触发（与 stage.areas[i].spawn_records 同形状）
var _fired: Array = []
## 生成节点容器（关卡场景注入）
var spawn_parent: Node

var locked: bool = false
## 锁屏时冻结的摄像机左缘
var lock_cam_left: float = 0.0
## 本批锁组生成的敌人（解锁判定 = 全部无效或已死）。
## 原版解锁口径是「已生成敌人数」计数器 `$FFB358`，生成未完即全灭等边角行为待实测 TODO[实测]
var _lock_batch: Array = []
## 摄像机单向推进记忆（清版卷轴不回头，按区域重置）
var _cam_min_left: float = 0.0


func load_stage(data: StageData, parent: Node) -> void:
	stage = data
	spawn_parent = parent
	area_offsets.clear()
	_fired.clear()
	var x := 0.0
	for area in stage.areas:
		area_offsets.append(Vector2(x, 0.0))
		var flags: Array[bool] = []
		flags.resize(area.spawn_records.size())
		flags.fill(false)
		_fired.append(flags)
		x += area.size.x
	set_area(0)
	set_unlocked()


## 关卡场景每物理帧调用：推进区域定位、触发刷怪、写边界。
func tick(reference: Node2D) -> void:
	if stage == null or reference == null:
		return
	var index := area_index_at(reference.global_position.x)
	if index != current_area:
		set_area(index)
	check_triggers()
	update_lock()
	apply_bounds()


func set_area(index: int) -> void:
	current_area = clampi(index, 0, stage.areas.size() - 1)
	_cam_min_left = area_origin(current_area).x
	area_changed.emit(current_area)


func area_origin(index: int = -1) -> Vector2:
	var i := current_area if index < 0 else index
	return area_offsets[i] if i < area_offsets.size() else Vector2.ZERO


func current_area_data() -> AreaData:
	return stage.areas[current_area] if stage != null else null


func area_index_at(world_x: float) -> int:
	var acc := 0.0
	for i in stage.areas.size():
		acc += stage.areas[i].size.x
		if world_x < acc:
			return i
	return stage.areas.size() - 1


# ---------------------------------------------------------------- ①②③④ 边界与锁屏

## 摄像机左上角的世界坐标夹取范围（区域内，含纵向卷轴）
func camera_left_bounds(index: int = -1) -> Rect2:
	var origin := area_origin(index)
	var area: AreaData = stage.areas[index if index >= 0 else current_area]
	var rect := Rect2(origin, Vector2(maxf(area.size.x - VIEW.x, 0.0), maxf(area.size.y - VIEW.y, 0.0)))
	if locked:
		# ④ 锁屏：摄像机冻结在触发线位置
		rect.position.x = lock_cam_left
		rect.size.x = 0.0
	return rect


## 供 [StageCamera] 使用：跟随目标 → 夹取 + 单向推进 + 锁屏冻结。
## 返回值是摄像机**中心**（Camera2D.position 语义），内部全程用左上角口径。
func camera_target_for(target: Node2D, current: Vector2) -> Vector2:
	if stage == null or target == null:
		return current
	var index := area_index_at(target.global_position.x)
	var bounds := camera_left_bounds(index)
	var left := target.global_position - VIEW * 0.5
	left.x = clampf(left.x, bounds.position.x, bounds.end.x)
	left.y = clampf(left.y, bounds.position.y, bounds.end.y)
	if locked:
		left.x = lock_cam_left
	else:
		# 卷轴只进不退（换区域时 _cam_min_left 已在 set_area 重置）
		left.x = maxf(left.x, _cam_min_left)
	_cam_min_left = left.x
	return left + VIEW * 0.5


## ②③：把「视野 X 夹取 + 区域 Y 带」写进所有战斗对象的 play_bounds，
## 实际夹取仍走 FightObject.clamp_to_bounds()（单一夹取入口）。
func apply_bounds() -> void:
	var area := current_area_data()
	if stage == null or area == null:
		return
	# 锁屏时照常写边界：摄像机已冻结，视野右缘就是事实上的墙（doc/05 §④）
	var origin := area_origin(current_area)
	var cam_left := camera_left()
	var x_min := maxf(cam_left + PLAYER_EDGE_MARGIN, origin.x)
	var x_max := minf(cam_left + VIEW.x - PLAYER_EDGE_MARGIN, origin.x + area.size.x)
	var band := Rect2(x_min, origin.y + area.walk_band_y.x,
			maxf(x_max - x_min, 0.0), area.walk_band_y.y - area.walk_band_y.x)
	for node in get_tree().get_nodes_in_group("fighters"):
		if not is_instance_valid(node):
			continue  # queue_free 当帧仍可能在组里
		var fighter := node as FightObject
		if fighter != null and not fighter.is_dead:
			fighter.play_bounds = band


# ---------------------------------------------------------------- 刷怪与解锁

func check_triggers() -> void:
	if locked or stage == null:
		return
	var area := current_area_data()
	var origin := area_origin(current_area)
	# 触发判定基于摄像机右缘到达 trigger_x（「屏幕出现区间」口径）
	var cam_left := camera_left()
	var lock_this_batch := false
	for i in area.spawn_records.size():
		var record := area.spawn_records[i]
		if _fired[current_area][i]:
			continue
		if cam_left + VIEW.x < origin.x + record.trigger_x:
			break  # 记录按 trigger_x 升序排列，后面的更晚
		_fired[current_area][i] = true
		spawn_record(record, origin)
		lock_this_batch = lock_this_batch or record.locks_screen
	if lock_this_batch:
		set_locked(cam_left)


## 摄像机左上角世界 X（无摄像机时退化为区域原点）
func camera_left() -> float:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return area_origin().x
	return camera.global_position.x - VIEW.x * 0.5


func spawn_record(record: SpawnRecord, origin: Vector2) -> void:
	# 人数标记过滤（B1 高位：4 = 2 人以上 / 6 = 3 人，ROM 原值）；
	# 8 = 4 人以上为改版新档（本项目 4 人同屏改版，doc/09 §改版拍板）
	if record.count_flag >= 8 and player_count() < 4:
		return
	if record.count_flag == 6 and player_count() < 3:
		return
	if record.count_flag == 4 and player_count() < 2:
		return
	if record.scene == null or spawn_parent == null:
		return
	var unit: Node2D = record.scene.instantiate()
	spawn_parent.add_child(unit)
	unit.global_position = origin + record.spawn_pos
	unit.reset_physics_interpolation()  # 传送式生成必须 snap 插值
	# 只有锁组批次参与解锁判定（非锁记录刷的人流不拦路）
	if record.locks_screen and unit is FightObject:
		_lock_batch.append(unit)


func update_lock() -> void:
	if not locked:
		return
	var alive := 0
	for unit in _lock_batch:
		if is_instance_valid(unit) and not unit.is_dead:
			alive += 1
	if alive == 0:
		set_unlocked()


func set_locked(cam_left: float) -> void:
	locked = true
	lock_cam_left = cam_left
	screen_locked.emit(true)


func set_unlocked() -> void:
	locked = false
	_lock_batch.clear()
	screen_locked.emit(false)


func player_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		if node is FightObject and is_instance_valid(node) and not node.is_dead:
			count += 1
	return count
