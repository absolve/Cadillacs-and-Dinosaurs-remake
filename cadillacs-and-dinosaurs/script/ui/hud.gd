extends CanvasLayer
class_name Hud
## 玩家卡片栏：底部一排最多 4 张 [PlayerCard]（slot 按玩家注册顺序）。
##
## 口径：**4 人同屏为本项目改版**（原版 ROM 为 3 人，doc/09 §改版拍板），
## 卡片 96 × 4 = 384 正好铺满；多人联调排期见 doc/11。

const MAX_CARDS := 4
const CARD_SIZE := Vector2(96, 28)
const BOTTOM_Y := 224.0 - 28.0

var root: Control
var cards: Array[PlayerCard] = []


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.name = "CardRow"
	add_child(root)
	Game.player_registered.connect(_on_player_registered)
	# 场景里先于 HUD 出生的玩家：兜底扫描
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		_attach(node as Player)


## 测试与调试查询用
func card_count() -> int:
	var n := 0
	for card in cards:
		if card.fighter != null:
			n += 1
	return n


func card_at(index: int) -> PlayerCard:
	return cards[index] if index < cards.size() else null


func _on_player_registered(player: Player) -> void:
	_attach(player)


func _attach(player: Player) -> void:
	if player == null:
		return
	# 已绑定则跳过（兜底扫描与信号可能重复）
	for card in cards:
		if card.fighter == player:
			return
	# 取第一个空槽（玩家中途退出会留空位，不顶替活着的卡片）
	var slot := -1
	for i in cards.size():
		if cards[i].fighter == null:
			slot = i
			break
	if slot < 0:
		slot = cards.size()
	if slot >= MAX_CARDS:
		return
	var card := _card_for_slot(slot)
	card.bind(player)
	player.tree_exiting.connect(_on_player_exited.bind(slot, player))


func _on_player_exited(slot: int, player: Player) -> void:
	var card := card_at(slot)
	if card != null and card.fighter == player:
		card.bind(null)


func _card_for_slot(slot: int) -> PlayerCard:
	while cards.size() <= slot:
		var fresh := PlayerCard.new()
		fresh.size = CARD_SIZE
		root.add_child(fresh)
		cards.append(fresh)
	var card := cards[slot]
	card.position = Vector2(slot * CARD_SIZE.x, BOTTOM_Y)
	card.visible = true
	return card
