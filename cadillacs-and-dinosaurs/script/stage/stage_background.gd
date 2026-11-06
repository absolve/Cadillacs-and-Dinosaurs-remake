extends Node2D
class_name StageBackground
## 按房间铺背景条图（doc/09 §关卡加载策略：背景是房间四要素之一）。
##
## v1 口径 `[推定]` TODO[实测]：条图原尺寸 1:1 横向平铺到铺满区域宽度，
## **底边贴区域底**（视差滚动、场景与区域映射、地面线对齐都待录像核对）。
## 渲染通道：远景 → 层 1（background），近景 → 层 5（压过角色层 4）。

const FAR_LAYER := 1
const NEAR_LAYER := 5


func build() -> void:
	for child in get_children():
		child.queue_free()
	if StageDirector.stage == null:
		return
	for i in StageDirector.stage.areas.size():
		var area := StageDirector.stage.areas[i]
		var origin: Vector2 = StageDirector.area_offsets[i]
		_tile(area.far_backgrounds, origin, area, FAR_LAYER)
		_tile(area.near_backgrounds, origin, area, NEAR_LAYER)


func _tile(textures: Array[Texture2D], origin: Vector2, area: AreaData, layer: int) -> void:
	for tex in textures:
		if tex == null or tex.get_width() <= 0:
			continue
		var strip_w := float(tex.get_width())
		var x := 0.0
		while x < area.size.x:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.position = origin + Vector2(x, area.size.y - float(tex.get_height()))
			spr.visibility_layer = layer
			add_child(spr)
			x += strip_w
