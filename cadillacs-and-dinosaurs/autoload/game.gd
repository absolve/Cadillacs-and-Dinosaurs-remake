extends Node
## Game —— 全局单例：全局信号、共用函数、共用类型。
##
## 已落地：演出慢放的**全屏层**（设计见 doc/09 §演出慢放设计）；
## 国际化语言切换入口（`lang/translations.csv`，en / zh_CN）。
## 个体层慢放在 [FightObject.start_self_slow]，两层相乘成有效步长。
##
## 规划职责（随里程碑填入）：暂停、分数与命数信号；
## 游戏流程枚举（标题 / 选人 / 关卡 / 结算，M6 `GameFlow` 的底座）。

signal dilation_changed(step: int, real_frames_left: int)
## 玩家对象进树时广播（[Hud] 据此挂卡片；出生顺序 = 卡片槽位）
signal player_registered(player: Player)
## 界面语言切换（lang/translations.csv，en / zh_CN）
signal locale_changed(locale: String)


func _ready() -> void:
	_load_project_translations()
	set_locale(locale)


## 显式注册 `[internationalization] rendering/translations` 列出的翻译资源。
## 引擎启动自加载在本版本 headless 下不可靠（见 lang/translations.csv 冒烟），
## 统一由此单例负责；重复注册同 locale 由 TranslationServer 幂等处理。
func _load_project_translations() -> void:
	var paths: Array = ProjectSettings.get_setting("internationalization/rendering/translations", [])
	for path: String in paths:
		var translation := load(path) as Translation
		if translation == null:
			push_warning("翻译资源加载失败: " + path)
			continue
		TranslationServer.add_translation(translation)


# ---------------------------------------------------------------- 国际化

## 支持的语言清单（选人 / 设置界面从这里取）
const LOCALES := ["en", "zh_CN"]

## 当前界面语言，默认中文；UI 文案一律走 tr("KEY") 取翻译
var locale: String = "zh_CN"


func set_locale(new_locale: String) -> void:
	if new_locale not in LOCALES:
		push_warning("未登记的语言: " + new_locale)
		return
	locale = new_locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)

## 全屏慢放步长 N：所有 [FightObject] 每 N 物理帧只推进 1 有效帧。
## 摄像机 / 输入缓冲不受影响（保持真实速率）
var world_step: int = 1
var _world_left: int = 0


## 触发全屏慢放 `1/step`，持续 `real_frames` 个物理帧后自动恢复
func set_world_slow(step: int, real_frames: int) -> void:
	world_step = clampi(step, 1, 8)
	_world_left = maxi(real_frames, 0)
	dilation_changed.emit(world_step, _world_left)


func is_world_slow() -> bool:
	return world_step > 1


func _physics_process(_delta: float) -> void:
	if _world_left <= 0:
		return
	_world_left -= 1
	if _world_left == 0 and world_step != 1:
		world_step = 1
		dilation_changed.emit(1, 0)
