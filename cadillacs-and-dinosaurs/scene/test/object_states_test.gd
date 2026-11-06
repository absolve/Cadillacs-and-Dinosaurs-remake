extends Node
## 玩家 / 敌人状态与功能的回归测试，跑在 `test_room.tscn` 里。
##
## 运行（仓库根目录）：
##   godot --headless --path ./cadillacs-and-dinosaurs res://scene/test/test_room.tscn
##   图形界面下想跑自动测试：godot --path ./cadillacs-and-dinosaurs res://scene/test/test_room.tscn -- --auto
##
## 覆盖：动画组挂载与 act_map / 招式两段式动画引用校验 /
## 待机 / 八向走 / 纵深减速 / 可行走带夹取 / 跳跃与落地 / 空中飞踢命中 /
## 三段连击（hit-confirm + 可取消窗口）/ 打空不连段 / 一次挥击只结算一次 /
## 力量缩放 / 击倒→起身→眩晕送打 / 60 帧击倒免疫 / 敌人追击与出招冷却 /
## 高度轴容差 / 玩家受击转身与击退 / 敌人死亡 /
## 慢放 tick 门控与 speed_scale / 击杀双方慢放 / 玩家死亡全屏慢放与恢复 / i18n 双语切换。

const ENEMY_SCENE: PackedScene = preload("res://scene/actor/enemy/enemy.tscn")
const ROOM: GDScript = preload("res://scene/test/test_room.gd")

const KEYS: Array[StringName] = [
	&"p1_left", &"p1_right", &"p1_up", &"p1_down", &"p1_attack", &"p1_jump",
]
const PLAYER_START := Vector2(120, 160)
const ENEMY_NEAR := Vector2(146, 160)   # 已在攻击距离内（attack_range 34）
const ENEMY_FAR := Vector2(300, 160)    # 在 aggro(260) 内、攻击距离外

var room: Node2D
var actors: Node2D
var player: Player
var foe: Enemy
var checked: int = 0
var failed: int = 0


func _ready() -> void:
	if not auto_mode():
		set_process(false)
		return  # 手动模式：只当沙盒用
	room = get_parent() as Node2D
	actors = room.get_node("Actors") as Node2D
	player = room.get_node("Actors/Player") as Player
	# 场景里的沙盒敌人交给测试自己管，避免多余敌人污染断言
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		node.queue_free()
	await frames(3)
	print("============ 玩家 / 敌人状态与功能测试 ============")
	await test_roster_animations()
	await test_idle_and_walk()
	await test_depth_speed()
	await test_walk_band_clamp()
	await test_jump_and_land()
	await test_air_kick_hits()
	await test_combo_chains()
	await test_whiff_does_not_chain()
	await test_one_hit_per_swing()
	await test_power_scaling()
	await test_knockdown_rise_stun()
	await test_knockdown_immune_window()
	await test_enemy_approaches_and_attacks()
	await test_enemy_cooldown_starts()
	await test_height_axis_tolerance()
	await test_player_hurt_knockback()
	await test_enemy_death()
	await test_slow_motion()
	await test_i18n()
	print("===================================================")
	if failed == 0:
		print("✅ 全部 %d 项断言通过" % checked)
	else:
		printerr("❌ %d/%d 项断言失败" % [failed, checked])
	get_tree().quit(1 if failed > 0 else 0)


func auto_mode() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	return "--auto" in OS.get_cmdline_user_args()


# ---------------------------------------------------------------- 用例

## 每个角色的 act_map 与招式动画引用必须真的指到「对应组」里存在的段
func test_roster_animations() -> void:
	for scene in ROOM.ROSTER:
		var unit: Player = scene.instantiate()
		actors.add_child(unit)
		await frames(2)
		var name := unit.character_stats.display_name
		check(unit.sprite.sprite_frames != null, "%s 挂上了动画集（%s）" % [name, unit.set_of_group(0).sheet_dir])
		check(unit.anim_groups.size() >= 6, "%s 按组挂了 6 个动画集（组 0..5）" % name)
		check(unit.set_of_group(1) != null and unit.set_of_group(5) != null,
				"%s 的攻击组（组 1）与单帧姿态组（组 5）都在位" % name)
		var missing: Array[String] = []
		for action in unit.act_map.keys():
			if unit.ref_of(StringName(action)) == "":
				missing.append("%s->%s" % [action, unit.act_map[action]])
		check(missing.is_empty(),
				"%s 的 act_map 全部命中（%d 个键，缺 %s）" % [name, unit.act_map.size(), ", ".join(missing)])
		# 招式两段式：起手与命中分属不同动画组（doc/10 §8.11 结论 3）
		var phase_missing: Array[String] = []
		for move in unit.character_stats.moves:
			for ref: String in [move.start_anim, move.hit_anim]:
				if ref != "" and unit.ref_or_empty(ref) == "":
					phase_missing.append("%s:%s" % [move.id, ref])
		check(phase_missing.is_empty(),
				"%s 的招式起手段 / 命中段全部存在（缺 %s）" % [name, ", ".join(phase_missing)])
		var first := unit.move_of(&"attack1")
		check(first != null and first.start_anim != "" and first.hit_anim != ""
				and FightObject.split_anim_ref(first.start_anim)[0] != FightObject.split_anim_ref(first.hit_anim)[0],
				"%s attack1 的起手 / 命中两段跨动画组（%s → %s）" % [name, first.start_anim, first.hit_anim])
		check(unit.set_of_group(0).rom_addr != "", "%s 记录了组 0 的 ROM 动画表地址 %s"
				% [name, unit.set_of_group(0).rom_addr])
		unit.queue_free()
		await frames(2)


func test_idle_and_walk() -> void:
	await reset()
	check(state(player) == &"Idle", "玩家初始进入 Idle")
	check(anim(player) == act(player, "idle"), "待机播放 idle 映射的动画段")

	var x0 := player.global_position.x
	press(&"p1_right")
	# 20 帧 ≈ 32 px 位移（96 px/s）：roster 实例变多后无头模式状态切换会吃掉头几帧，
	# 12 帧时余量不足，断言时过时挂
	await frames(20)
	check(state(player) == &"Walk", "按住右进入 Walk")
	check(player.face_dir == 1 and not player.sprite.flip_h,
			"朝右：face_dir=1 不镜像（素材已按项目口径存成朝右）")
	check(player.global_position.x > x0 + 10.0, "向右有位移")
	check(anim(player) == act(player, "walk"), "移动播放 walk 段")
	release(&"p1_right")
	await frames(2)
	check(state(player) == &"Idle", "松手回 Idle")

	press(&"p1_left")
	await frames(10)
	check(player.face_dir == -1 and player.sprite.flip_h, "朝左：face_dir=-1 且贴图运行时镜像")
	release(&"p1_left")
	await frames(2)


func test_depth_speed() -> void:
	await reset()
	var x0 := player.global_position.x
	press(&"p1_right")
	await frames(12)
	var dx := absf(player.global_position.x - x0)
	release(&"p1_right")
	await frames(2)

	var y0 := player.global_position.y
	press(&"p1_down")
	await frames(12)
	var dy := absf(player.global_position.y - y0)
	release(&"p1_down")
	await frames(2)
	check(dy > 4.0, "纵深方向可以走")
	check(dy < dx, "纵深比横向慢（depth_speed_factor 生效）")


func test_walk_band_clamp() -> void:
	await reset()
	press(&"p1_right")
	await frames(200)
	release(&"p1_right")
	await frames(2)
	var right_edge: float = room.walk_band.end.x
	check(player.global_position.x <= right_edge + 0.5, "横向被可行走带右界夹住")
	check(player.global_position.x > right_edge - 6.0, "确实走到了右界而不是卡在半路")


func test_jump_and_land() -> void:
	await reset()
	tap(&"p1_jump")
	await frames(3)
	check(state(player) == &"Jump", "按跳进入 Jump")
	check(player.in_air and player.body.position.y < 0.0, "起跳后浮空（伪 Z 轴）")
	var shadow := player.get_node_or_null("Shadow") as Node2D
	check(shadow != null and shadow.global_position == player.global_position,
			"影子贴脚底，不随伪 Z 抬升（Body 已上升，影子在根节点）")
	check(foe.get_node_or_null("Shadow") != null, "敌人同样挂贴地影子")
	check(anim(player) == act(player, "jump") and act(player, "jump").begins_with("g1/"),
			"跳跃段在组 1（doc/10 §8.11：跳跃 / 攻击段不在基础组）")
	var guard := 0
	while player.in_air and guard < 240:
		await frames(1)
		guard += 1
	check(not player.in_air, "会落回地面")
	check(is_zero_approx(player.body.position.y), "落地后浮空偏移归零")
	check(state(player) == &"Idle", "落地回 Idle")


func test_air_kick_hits() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	make_durable(foe)
	var hp0 := foe.hp
	tap(&"p1_jump")
	await frames(3)  # 起跳早期，高度还在 height_tolerance 之内
	tap(&"p1_attack")
	await frames(6)
	check(foe.hp < hp0, "空中按攻击出飞踢并命中敌人")
	check(anim(player) == act(player, "kick"), "飞踢播放 kick 段")
	# 每次跳跃只允许一次空中攻击：空中再按拳不该换段、也不该进地面连击
	var kick_anim := anim(player)
	tap(&"p1_attack")
	await frames(3)
	check(player.in_air, "第二次按拳时仍在空中")
	check(anim(player) == kick_anim, "空中第二次按拳不换段（每跳仅一次）")
	var guard := 0
	while player.in_air and guard < 240:
		await frames(1)
		guard += 1
	check(state(player) == &"Idle", "飞踢后正常落地回 Idle")


func test_combo_chains() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	make_durable(foe)
	var hp0 := foe.hp
	tap(&"p1_attack")
	await frames(2)
	check(state(player) == &"Attack", "出拳进入 Attack")
	check(anim(player) == move_ref(player, &"attack1", false),
			"第一段起手播放起手段 %s" % move_ref(player, &"attack1", false))
	await frames(6)
	check(anim(player) == move_ref(player, &"attack1", true),
			"进判定窗口切到命中段 %s（两段跨组 [ROMDATA] doc/10 §8.11）" % move_ref(player, &"attack1", true))
	check(foe.hp == hp0 - 20, "第一段伤害 20（力量 32 基准），实际 %d / 状态 %s / 段 %s" % [hp0 - foe.hp, state(foe), anim(player)])
	tap(&"p1_attack")
	await frames(6)
	check(state(player) == &"Attack" and in_move(player, &"attack2"),
			"命中后再按拳递进第二段（当前段 %s 属于 attack2）" % anim(player))
	await frames(4)
	check(anim(player) == move_ref(player, &"attack2", true),
			"第二段进判定窗口切到命中段 %s" % move_ref(player, &"attack2", true))
	tap(&"p1_attack")
	await frames(10)
	check(in_move(player, &"attack3"), "继续按拳递进第三段，实际段 %s / 状态 %s / 敌血 %d" % [anim(player), state(player), foe.hp])
	await frames(10)
	check(foe.state_machine.current_name() == &"Down", "第三段带击倒，敌人进入 Down")
	check(foe.hp == hp0 - 20 - 22 - 26, "三段合计伤害 68 = Jack 连击伤害 [ROMDATA]")


func test_whiff_does_not_chain() -> void:
	await reset()
	place(foe, ENEMY_FAR)
	make_durable(foe)
	var first_hit := move_ref(player, &"attack1", true)
	tap(&"p1_attack")
	await frames(10)
	tap(&"p1_attack")   # 打空：即使再按拳也不该递进
	await frames(4)
	check(state(player) == &"Attack" and anim(player) == first_hit,
			"打空时不递进连段（hit-confirm），实际段 %s / 状态 %s" % [anim(player), state(player)])
	await frames(20)
	check(state(player) == &"Idle", "打空收招后回 Idle")


func test_one_hit_per_swing() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	make_durable(foe)
	var hp0 := foe.hp
	tap(&"p1_attack")
	await frames(10)
	var mid := foe.hp
	await frames(30)  # 覆盖整段 active + recovery
	check(mid == hp0 - 20 and foe.hp == mid,
			"同一次挥击只结算一次（一次 20，之后不再掉血）实际 %d -> %d -> %d 玩家=%s 敌=%s"
			% [hp0, mid, foe.hp, state(player), state(foe)])


func test_power_scaling() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	make_durable(foe)
	player.power = 64  # 最高难度「终极暴击」×2.0
	var hp0 := foe.hp
	tap(&"p1_attack")
	await frames(12)
	check(foe.hp == hp0 - 40, "力量 64 时伤害翻倍（基础 × 力量 >> 5），实际扣 %d" % (hp0 - foe.hp))
	player.power = 32


func test_knockdown_rise_stun() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	foe.take_damage(1, 1, true, player)
	check(state(foe) == &"Down", "击倒伤害让敌人进入 Down")
	await frames(30)
	check(state(foe) == &"Rise", "倒地结束进入 Rise")
	check(foe.is_invincible(), "起身期间无敌")
	await frames(16)
	check(state(foe) == &"Stunned", "敌人起身后进入眩晕送打窗口")
	check(foe.is_knockdown_immune(), "起身后带 60 帧击倒免疫")
	await frames(60)
	check(state(foe) == &"Approach", "眩晕结束回到追击")


func test_knockdown_immune_window() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	foe.make_knockdown_immune()
	var hp0 := foe.hp
	foe.take_damage(2, 1, true, player)
	check(state(foe) == &"Hurt", "免疫窗口内只吃硬直，不再被击倒")
	check(foe.hp == hp0 - 2, "免疫窗口内伤害照常结算")


func test_enemy_approaches_and_attacks() -> void:
	await reset()
	place(foe, ENEMY_FAR)
	var x0 := foe.global_position.x
	await frames(40)
	check(foe.global_position.x < x0 - 10.0, "敌人在 aggro 内走向玩家")
	check(state(foe) != &"Attack" or foe.global_position.x > player.global_position.x, "敌人从右侧接近")
	var guard := 0
	while state(foe) != &"Attack" and guard < 240:
		await frames(1)
		guard += 1
	check(state(foe) == &"Attack", "进入攻击距离后出招")
	var hp0 := player.hp
	await frames(24)  # 前摇 18 + 判定
	check(player.hp < hp0, "敌人攻击命中玩家并扣血")


func test_enemy_cooldown_starts() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	await frames(4)
	check(foe.cooldown_frames > 0, "敌人出招即写入冷却（打空也要等）")


func test_height_axis_tolerance() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	# A：高度 30 < 容差 48 → 应该被拳打到
	player.body.position.y = -30.0
	var hp_low := player.hp
	await frames(26)
	check(player.hp < hp_low, "高度在容差内时敌人拳头能命中")
	# B：高度 55 > 容差 48 → 从头顶掠过
	await reset()
	place(foe, ENEMY_NEAR)
	player.body.position.y = -55.0
	var hp_high := player.hp
	await frames(26)
	check(player.hp == hp_high, "高度超过容差时从头顶掠过不被命中")
	player.body.position.y = 0.0


func test_player_hurt_knockback() -> void:
	await reset()
	var x0 := player.global_position.x
	var hp0 := player.hp
	player.take_damage(10, 1, false, null)
	check(state(player) == &"Hurt", "玩家受击进入 Hurt")
	check(player.hp == hp0 - 10, "受击扣血")
	check(player.face_dir == -1, "受击后转身面向出手者")
	await frames(8)
	check(player.global_position.x > x0, "受击沿出手方向被击退")
	await frames(20)
	check(state(player) == &"Idle", "硬直结束回 Idle")


func test_enemy_death() -> void:
	await reset()
	place(foe, ENEMY_NEAR)
	var died_seen := [false]
	foe.died.connect(func() -> void: died_seen[0] = true)
	foe.take_damage(999, 1, false, player)
	check(died_seen[0], "HP 归零发出 died 信号")
	check(foe.is_dead and foe.hp == 0, "敌人进入死亡状态")
	await frames(6)
	check(state(foe) != &"Attack", "死亡后不再出招")
	var hp_before := player.hp
	await frames(40)
	check(player.hp == hp_before, "死亡后不再伤害玩家")


## 演出慢放（doc/09 §演出慢放设计）：tick 门控、击杀接线、玩家死亡全屏慢放
func test_slow_motion() -> void:
	await reset()
	await frames(30)  # 让上一用例遗留的个体慢放自然耗尽
	check(Game.world_step == 1, "开局无全屏慢放")

	# 个体门控：step 3 时每 3 物理帧只推进 1 有效帧
	foe.start_self_slow(3, 6)
	var foe_ticks := foe.local_ticks
	await frames(7)
	check(foe.local_ticks - foe_ticks == 2, "step 3 门控：7 物理帧推进 2 有效帧")
	check(absf(foe.sprite.speed_scale - 1.0 / 3.0) < 0.01, "动画 speed_scale 同步降为 1/3")
	await frames(12)  # 累计 18+ 物理帧 = 6 有效帧，刚好耗尽
	check(foe.local_step() == 1, "有效帧耗尽后自动恢复正常步长")

	# 击杀接线：死者与凶手同时进慢放
	await reset()
	place(foe, ENEMY_NEAR)
	var player_ticks := player.local_ticks
	foe.take_damage(999, 1, false, player)
	check(foe.local_step() == 3, "被击杀者进 1/3 慢放")
	await frames(7)
	check(player.local_ticks - player_ticks == 2, "凶手进 1/3 慢放（门控生效）")

	# 玩家死亡：全屏 1/4 慢放，45 物理帧后自动恢复
	Game.set_world_slow(1, 0)  # 防御性复位，保证只测本用例的世界层
	player.hp = 1
	player.take_damage(10, 1, false, foe)
	check(player.is_dead, "玩家死亡")
	check(Game.world_step == 4, "玩家死亡触发全屏 1/4 慢放")
	var foe_ticks2 := foe.local_ticks
	await frames(9)
	check(foe.local_ticks - foe_ticks2 <= 3, "全屏慢放下敌人推进减速（9 物理帧 ≤3 有效帧）")
	await frames(46)
	check(Game.world_step == 1, "45 物理帧后全屏慢放自动恢复")


## 国际化骨架：lang/translations.csv 双语可切换（doc/11 §贯穿线）
func test_i18n() -> void:
	Game.set_locale("zh_CN")
	check(tr("APP_TITLE") == "恐龙快打", "zh_CN 翻译生效（CSV 骨架）")
	Game.set_locale("en")
	check(tr("APP_TITLE") == "Cadillacs and Dinosaurs", "en 翻译生效")
	Game.set_locale("zh_CN")
	check(Game.locale == "zh_CN", "语言切回默认中文")


# ---------------------------------------------------------------- 断言与工具

func check(condition: bool, label: String) -> void:
	checked += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed += 1
		printerr("  [FAIL] %s" % label)


func frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func tap(action: StringName) -> void:
	press(action)
	await frames(1)
	release(action)
	await frames(1)


func press(action: StringName) -> void:
	push_input(action, true)


func release(action: StringName) -> void:
	push_input(action, false)


func push_input(action: StringName, pressed_state: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed_state
	Input.parse_input_event(event)


func release_all() -> void:
	for action in KEYS:
		push_input(action, false)


## 复位：松开所有键、玩家回 Idle、清缓冲与无敌、**重新生成一个满血敌人**
func reset() -> void:
	release_all()
	place(player, PLAYER_START)
	player.hp = player.max_hp
	player.invincible_left = 0
	player.knockdown_immune_left = 0
	player.power = 32
	player.velocity = Vector2.ZERO
	player.clear_buffers()
	if player.state_machine.current_name() != &"Idle":
		player.state_machine.transition_to("Idle")
	if foe != null and is_instance_valid(foe):
		foe.queue_free()
	foe = ENEMY_SCENE.instantiate() as Enemy
	actors.add_child(foe)
	place(foe, ENEMY_FAR)
	await frames(3)


## 把敌人当木桩用：血量拉满、不还手，专测伤害与连段节奏
func make_durable(target: Enemy, total_hp: int = 200) -> void:
	target.max_hp = total_hp
	target.hp = total_hp
	target.aggro_range = 0.0        # 永不进 aggro -> Approach 里只站着，不会打断玩家连段
	target.cooldown_frames = 0
	target.knockback_speed = 0.0    # 不后退，保证三段连击都在射程内


func place(node: Node2D, where: Vector2) -> void:
	node.global_position = where
	node.body.position.y = 0.0
	node.in_air = false
	node.z_velocity = 0.0


func state(fighter: FightObject) -> StringName:
	return fighter.state_machine.current_name()


func anim(fighter: FightObject) -> String:
	return fighter.anim_ref()


## 动作键解析到的动画引用（`"gN/actMM"`）
func act(fighter: FightObject, action: StringName) -> String:
	return fighter.ref_of(action)


## 招式某一阶段的期望动画引用：`hit_phase` 为真取命中段，否则取起手段
func move_ref(fighter: FightObject, action: StringName, hit_phase: bool) -> String:
	var move := fighter.move_of(action)
	if move != null:
		var raw := move.hit_anim if hit_phase and move.hit_anim != "" else move.start_anim
		if raw != "":
			return fighter.ref_or_empty(raw)
	return fighter.ref_of(action)


## 当前动画是否属于该招式的两段之一（起手段 / 命中段按帧切换，断言不卡时机）
func in_move(fighter: FightObject, action: StringName) -> bool:
	return fighter.anim_ref() in [move_ref(fighter, action, false), move_ref(fighter, action, true)]
