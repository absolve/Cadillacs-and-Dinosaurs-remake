extends Node2D
## 第 1 关 City in the Sea 正式场景（v1：只做「房间 + 背景」，
## 刷怪完善 / 桶枪道具 / 演出 / 选人流程都按 doc/09 里程碑后续加）。

const STAGE01: StageData = preload("res://script/data/stage01_data.tres")

@onready var actors: Node2D = $Actors
@onready var player: Player = $Actors/Player
@onready var backgrounds: StageBackground = $Backgrounds


func _ready() -> void:
	StageDirector.load_stage(STAGE01, actors)
	backgrounds.build()
	var band: Vector2 = STAGE01.areas[0].walk_band_y
	player.global_position = Vector2(100.0, band.y)
	player.reset_physics_interpolation()
	StageDirector.tick(player)


func _physics_process(_delta: float) -> void:
	StageDirector.tick(player)
