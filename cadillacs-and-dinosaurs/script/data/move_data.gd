extends Resource
class_name MoveData
## 一个招式的时间与判定数据。帧数全部以**物理帧**（60 Hz，1 帧 = 1 原版帧）计。
##
## 占位纪律见 doc/09-development-plan §数据准备清单：`[推定]` 只写在这里，
## 不散落到场景与逻辑代码里；实测替换时只改 `.tres`。

@export var id: StringName = &"attack1"
## 播放用的动作键，交给 [FightObject.act_map] 解析成动画引用
@export var action: StringName = &"attack1"
## 起手段动画引用 `"gN/actMM"`；留空表示用 `action` 走 [FightObject.act_map]。
## `[ROMDATA]` doc/10 §8.11 实测：一次攻击是「起手段 → 命中段」两段动画，
## 而且两段**分属不同动画组**（如 `g0/act03` 起手 + `g1/act11` 命中）。
@export var start_anim: String = ""
## 命中段动画引用：进入判定窗口时切换；留空表示整招只有一段
@export var hit_anim: String = ""
## 起手（无判定）帧数
@export var startup: int = 6
## 判定生效帧数
@export var active: int = 4
## 收招 / 硬直帧数
@export var recovery: int = 10
## 基础伤害（力量 = 32 时的值，最终伤害 = 基础 × 力量 / 32）
@export var damage: int = 10
## 命中后是否击倒（原版击倒类攻击带「カタ」拟声标签）
@export var knockdown: bool = false
## 可取消窗口：本招式经过该帧数后即可接下一段（连击手感用）
@export var cancel_from: int = 10
## 判定盒（相对脚底的像素矩形，x 已按朝向翻转）
@export var hitbox_rect: Rect2 = Rect2(10, -60, 26, 40)
## 受击盒（相对脚底的像素矩形）
@export var hurtbox_rect: Rect2 = Rect2(-12, -72, 24, 72)
## 高度轴容差：攻击者与目标脚底高度差超过该值时不结算（跳过 / 飞踢从头顶掠过）
@export var height_tolerance: float = 48.0


## 招式总帧数（起手 + 判定 + 收招）
func total_frames() -> int:
	return startup + active + recovery

