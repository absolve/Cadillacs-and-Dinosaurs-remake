class_name DinoAnimSet
extends Resource
## 一个 ROM 动画集（`0xB7472` 表下标）的精灵数据与逐段元信息。
##
## 由 `res://tools/build_sprite_frames.gd` 从 `res://sprite/manifest.json` 生成，
## 运行时只取用不重建；素材与切片规则见 [sprite/README.md](../sprite/README.md)。

## ROM 动画集号，即 `res://sprite/<分类>/setNNN/` 的 NNN
@export var set_index: int = -1
## players / enemies / weapons / items / effects / npc
@export var category: StringName = &""
## 仅玩家：`01_jack` 之类的角色目录名，其余分类为空
@export var group: String = ""
## 该集动画表在 ROM 中的指针（如 `0x9e41c`），用于与逆向文档对账
@export var rom_addr: String = ""
## 精灵表所在目录（相对 `res://`）
@export var sheet_dir: String = ""
## 每段动画一个 `actNN`，帧为 `AtlasTexture`
@export var sprite_frames: SpriteFrames
## `&"actNN"` -> `{ anchor: Vector2, size: Vector2i, cols: int, rows: int,
## count: int, loop: bool, terminated: bool, sheet: string, frames: Array[int> }`；
## `anchor` 是脚底在单帧画布内的位置，`frames` 是该段引用的 ROM 帧号
@export var acts: Dictionary = {}


func has_act(anim: StringName) -> bool:
	return acts.has(String(anim))


func act_of(anim: StringName) -> Dictionary:
	return acts.get(String(anim), {})


## 单帧画布内脚底（ROM 坐标原点）的位置；用它给节点做偏移对齐
func anchor_of(anim: StringName) -> Vector2:
	return act_of(anim).get("anchor", Vector2.ZERO)


## 该段是否带 ROM 结束标志（false 多为待机 / 行走等循环段）
func is_terminated(anim: StringName) -> bool:
	return act_of(anim).get("terminated", false)


## 该段引用的 ROM 帧号序列，与 doc/10 §8.5 的逐帧判定盒导出同一套帧号
func rom_frames_of(anim: StringName) -> Array:
	return act_of(anim).get("frames", [])
