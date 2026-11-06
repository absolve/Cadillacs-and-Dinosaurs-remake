extends Node2D
## 关卡流程测试房：StageDirector + AreaData 的灰盒验证场景。
##
## 运行（仓库根目录）：
##   godot --headless --path ./cadillacs-and-dinosaurs res://scene/test/stage_flow_test.tscn
##   图形界面手动模式：p1_* 移动（第 1 关灰盒数据，橙色竖线 = 触发线）。
##
## 覆盖：区域排布 / Y 带夹取 / 摄像机区域夹取与单向推进 / 触发线刷怪 /
## 锁屏冻结与视野右缘墙 / 全灭解锁 / 人数标记过滤 / 切区域边界更新 / 玩家卡片 HUD。
##
## 推进方式：不传送（物理插值下协程改 position 会被快照盖回），
## 用真实行走（临时提高 move_speed + 按住方向）驱动摄像机与触发线。

const STAGE01: StageData = preload("res://script/data/stage01_data.tres")
const JACK: PackedScene = preload("res://scene/actor/player/jack.tscn")
## 测试推进速度 px/s（仅测试用，不影响正式数值）
const WALK_SPEED := 900.0

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $StageCamera

var player: Player
var checked: int = 0
var failed: int = 0


func _ready() -> void:
	if auto_mode():
		await run_tests()
		return
	reset_stage(0)
	print("关卡测试房就绪：p1_* 移动（第 1 关灰盒数据，橙色竖线 = 触发线）")


func _physics_process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		StageDirector.tick(player)


# ---------------------------------------------------------------- 测试骨架

func auto_mode() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	return "--auto" in OS.get_cmdline_user_args()


## 重载关卡数据并清场；spawn_index 指定出生区域。
## 出生位置在 add_child 之前写入，避免进树后被物理插值快照干扰
func reset_stage(spawn_index: int) -> void:
	# 同步 free（而非 queue_free）：避免旧实例当帧仍在 fighters/players 组里
	# 被摄像机 current 跟随、把触发线提前打光
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		node.free()
	if player != null and is_instance_valid(player):
		player.free()
	StageDirector.load_stage(STAGE01, actors)
	player = JACK.instantiate()
	var spawn: Vector2 = StageDirector.area_offsets[spawn_index] \
			+ Vector2(100.0, STAGE01.areas[spawn_index].walk_band_y.y)
	player.global_position = spawn
	actors.add_child(player)
	player.move_speed = WALK_SPEED  # _ready 里 _apply_stats 会先覆盖成正式值
	camera.position = spawn
	queue_redraw()


func frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = String(action)
	event.pressed = true
	Input.parse_input_event(event)


func release(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = String(action)
	event.pressed = false
	Input.parse_input_event(event)


## 按住右走，最多 max_frames 帧或到达 until_x
func walk_right(until_x: float, max_frames: int) -> void:
	press(&"p1_right")
	var n := 0
	while n < max_frames and player.global_position.x < until_x - 0.5:
		await frames(1)
		n += 1
	release(&"p1_right")
	await frames(4)


## 按住左走固定帧数（验证单向卷轴 / 左边界）
func walk_left(frame_count: int) -> void:
	press(&"p1_left")
	await frames(frame_count)
	release(&"p1_left")
	await frames(4)


## 一路向右清怪推进到目标 X（锁屏 → 全灭 → 继续）
func advance_to(x_target: float, max_rounds: int) -> void:
	for _r in max_rounds:
		if not is_instance_valid(player) or player.global_position.x >= x_target - 0.5:
			return
		# 每轮最多走 40 帧；被墙挡住（锁屏）则清怪解锁后继续
		await walk_right(x_target, 40)
		if StageDirector.locked:
			await kill_all_enemies()
	await frames(2)


func kill_all_enemies() -> void:
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if not is_instance_valid(node):
			continue
		var foe := node as FightObject
		if foe != null and not foe.is_dead:
			foe.die()
	await frames(6)


func alive_enemies() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if not is_instance_valid(node):
			continue
		var foe := node as FightObject
		if foe != null and not foe.is_dead:
			count += 1
	return count


func check(condition: bool, label: String) -> void:
	checked += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed += 1
		printerr("  [FAIL] %s" % label)


# ---------------------------------------------------------------- 用例

func run_tests() -> void:
	print("============ 关卡加载（StageDirector / AreaData）测试 ============")
	await test_layout()
	await test_walk_band()
	await test_camera_bounds()
	await test_trigger_locks_and_spawn()
	await test_edge_wall_while_locked()
	await test_unlock_after_wipe()
	await test_count_flag_filter()
	await test_four_player_hack()
	await test_area_switch()
	await test_one_way_scroll()
	await test_hud_cards()
	await test_stage01_scene()
	print("===================================================")
	if failed == 0:
		print("✅ 全部 %d 项断言通过" % checked)
	else:
		printerr("❌ %d/%d 项断言失败" % [failed, checked])
	get_tree().quit(1 if failed > 0 else 0)


func test_layout() -> void:
	reset_stage(0)
	await frames(4)
	var want := [Vector2.ZERO, Vector2(2268, 0), Vector2(3796, 0)]
	var ok := StageDirector.area_offsets.size() == 3
	for i in 3:
		ok = ok and StageDirector.area_offsets[i] == want[i]
	check(ok, "三段按 ROM 尺寸横向排布（2268/1528/1560）")
	check(StageDirector.area_index_at(2300.0) == 1 and StageDirector.area_index_at(3900.0) == 2,
			"世界 X → 区域定位正确")
	check(STAGE01.areas[0].vertical_scroll() and not STAGE01.areas[1].vertical_scroll(),
			"1A 高 300 判为纵向卷轴，1B 不是（doc/05 §尺寸）")


func test_walk_band() -> void:
	reset_stage(0)
	await frames(4)
	var band: Vector2 = STAGE01.areas[0].walk_band_y
	# 直接验证夹取入口（同 move_by 每帧走的路径）
	player.play_bounds = Rect2(0, band.x, 3000, band.y - band.x)
	player.global_position.y = 220.0
	player.clamp_to_bounds()
	check(player.global_position.y <= band.y + 0.5, "Y 越过下缘被夹回 1A 可行带上限 %f" % band.y)
	player.global_position.y = 40.0
	player.clamp_to_bounds()
	check(player.global_position.y >= band.x - 0.5, "Y 越过上缘被夹回 1A 可行写下限 %f" % band.x)


func test_camera_bounds() -> void:
	reset_stage(0)
	await frames(4)
	await advance_to(2100.0, 8)
	check(camera.position.x <= 2268.0 - 192.0 + 0.5,
			"摄像机右缘不越过区域宽 − 384（doc/05 §①）")
	check(StageDirector.camera_left() > 1000.0, "推进后摄像机确实到了右段")
	await walk_left(40)
	check(camera.position.x >= 2268.0 - 192.0 - 0.5 or StageDirector.camera_left() >= 1884.0 - 0.5,
			"玩家往回走，摄像机不后退（单向卷轴 + 左边界=视野缘）")


func test_trigger_locks_and_spawn() -> void:
	reset_stage(0)
	await frames(4)
	check(StageDirector.camera_left() + 384.0 < 920.0, "出生点未达第 1 组触发线")
	check(alive_enemies() == 0 and not StageDirector.locked, "开局无敌人、未锁屏")
	await walk_right(760.0, 120)
	check(StageDirector.locked, "到达屏幕出现区间进 lock 组（第 1 组 trigger 920）")
	check(alive_enemies() == 2, "同 trigger 的多条记录一起生成（2 名 Ferris）")


func test_edge_wall_while_locked() -> void:
	# 承接上一用例：锁屏中继续往右，应被视野右缘墙挡住
	await walk_right(1600.0, 80)
	var wall := StageDirector.lock_cam_left + 384.0 - StageDirector.PLAYER_EDGE_MARGIN
	check(absf(camera.position.x - (StageDirector.lock_cam_left + 192.0)) < 0.5,
			"锁屏期间摄像机冻结")
	check(player.global_position.x <= wall + 1.0,
			"锁屏时视野右缘就是墙（推进停在 %f 前）" % wall)


func test_unlock_after_wipe() -> void:
	var prev_lock := StageDirector.lock_cam_left
	await kill_all_enemies()
	check(not StageDirector.locked, "锁组敌人全灭 → 解锁（口径待实测 $FFB358）")
	await walk_right(1100.0, 60)
	check(camera.position.x > prev_lock + 192.0 + 0.5, "解锁后摄像机继续推进")


func test_count_flag_filter() -> void:
	# 1300 记录（count_flag=4）在右缘过 1300 时触发但单人被过滤；
	# 1600 锁组此时还没到触发线，所以场上应恰好为 0
	await kill_all_enemies()
	await walk_right(1150.0, 60)
	check(StageDirector.camera_left() + 384.0 >= 1300.0,
			"右缘已越过 1300 记录触发线")
	check(alive_enemies() == 0,
			"count_flag=4 记录单人时被过滤（人数标记 = 多人更多敌）")
	await walk_right(1700.0, 120)
	check(StageDirector.locked and alive_enemies() == 1,
			"继续推进到 1600 锁组：生成 1 名并锁屏")


## 4 人同屏改版（doc/09 §改版拍板）：p4 输入映射 + count_flag=8 新档过滤
func test_four_player_hack() -> void:
	var p4_ok := true
	for action in ["p4_up", "p4_down", "p4_left", "p4_right", "p4_attack", "p4_jump"]:
		p4_ok = p4_ok and InputMap.has_action(action)
	check(p4_ok, "p4_* 全套输入映射存在（改版 4 人同屏）")
	reset_stage(0)
	await advance_to(2240.0, 12)
	await kill_all_enemies()
	check(StageDirector.camera_left() + 384.0 >= 2100.0, "右缘已过 count_flag=8 记录触发线")
	check(alive_enemies() == 0, "count_flag=8（4 人以上，改版新档）单人时被过滤")


func test_area_switch() -> void:
	reset_stage(1)
	await frames(4)
	var band: Vector2 = STAGE01.areas[1].walk_band_y
	check(StageDirector.current_area == 1, "出生到 1B 即定位区域 1")
	await walk_right(2500.0, 120)
	check(player.global_position.y <= band.y + 1.0,
			"1B 内行走被夹在 Y 带 [%.0f, %.0f]（doc/05 §③ ROM 表）" % [band.x, band.y])
	check(StageDirector.locked, "1B 第 1 组锁屏生效（trigger 200）")


func test_one_way_scroll() -> void:
	# 承接上一用例：解锁后回退，摄像机不后退
	await kill_all_enemies()
	var cam_x := camera.position.x
	await walk_left(40)
	check(camera.position.x >= cam_x - 0.5, "换区域后依旧只进不退（清版动作惯例）")


## 玩家卡片 HUD：注册绑卡、受击更新、4 槽上限、离场释放
func test_hud_cards() -> void:
	reset_stage(0)
	await frames(4)
	var hud := get_node_or_null("PlayerHud") as Hud
	check(hud != null, "场景挂上 HUD")
	if hud == null:
		return
	check(hud.card_count() == 1, "出生后只挂 1 张玩家卡")
	player.take_damage(30, 0, false, null)
	await frames(1)
	check(absf(hud.card_at(0).hp_ratio - 0.7) < 0.01, "受击后卡片血条同步（30/100 → 0.7）")
	var extras: Array = []
	for i in 3:
		var extra: Player = JACK.instantiate()
		extra.global_position = player.global_position + Vector2(10 + i, 0)
		actors.add_child(extra)
		extras.append(extra)
	await frames(2)
	check(hud.card_count() == 4, "4 名玩家排满 4 张卡片（96 × 4 = 384 正好放下）")
	var fifth: Player = JACK.instantiate()
	actors.add_child(fifth)
	await frames(2)
	check(hud.card_count() == 4, "第 5 名玩家不占卡片（MAX_CARDS = 4）")
	for extra in extras:
		extra.free()
	fifth.free()
	await frames(2)
	check(hud.card_count() == 1, "额外玩家离场后卡片槽释放")


## 第 1 关正式场景 v1（房间 + 背景）冒烟：可实例化、条图按区域铺满、远/近层通道正确
func test_stage01_scene() -> void:
	var scene: Node = load("res://scene/stage/stage01/stage01.tscn").instantiate()
	add_child(scene)
	await frames(8)
	var bg := scene.get_node_or_null("Backgrounds") as StageBackground
	check(bg != null, "stage01 可实例化，含 Backgrounds")
	var far := 0
	var near := 0
	if bg != null:
		for child in bg.get_children():
			var spr := child as Sprite2D
			if spr == null or not is_instance_valid(spr):
				continue
			far += int(spr.visibility_layer == StageBackground.FAR_LAYER)
			near += int(spr.visibility_layer == StageBackground.NEAR_LAYER)
	# 条图宽度 1792/1024/3840 对区域宽 2268/1528/1560：远景 2+2+1，近景 1C 铺 2 张
	check(far == 5, "远景条图平铺 5 张覆盖三段区域宽度")
	check(near == 2, "1C 街道近景条图 2 张压在角色层之上")
	check(scene.get_node("Actors/Player") is Player, "出生玩家在场")
	check(StageDirector.stage == scene.get_node(".").STAGE01, "场景接管了 StageDirector 数据")
	scene.free()


# ---------------------------------------------------------------- 灰盒可视化（手动模式）

func _draw() -> void:
	if StageDirector.stage == null:
		return
	for i in StageDirector.stage.areas.size():
		var area := StageDirector.stage.areas[i]
		var origin: Vector2 = StageDirector.area_offsets[i]
		draw_rect(Rect2(origin, area.size), Color(0.12, 0.13, 0.16))
		draw_rect(Rect2(origin + Vector2(0, area.walk_band_y.x),
				Vector2(area.size.x, area.walk_band_y.y - area.walk_band_y.x)),
				Color(0.2, 0.35, 0.2, 0.5))
		for record in area.spawn_records:
			var x := origin.x + record.trigger_x
			draw_line(Vector2(x, origin.y), Vector2(x, origin.y + area.size.y),
					Color(0.9, 0.4, 0.1, 0.6))
