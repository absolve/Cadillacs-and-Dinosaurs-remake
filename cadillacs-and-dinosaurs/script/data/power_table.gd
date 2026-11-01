class_name PowerTable
## 「力量（Power）」表与伤害缩放 —— 复刻最容易漏的机制（doc/08 §2）。
##
## ROM 偏移 `0x2C9B6`，128 字节 = 4 个难度块 × 32 个值，基准 `0x20 = 32`。
## 变化时机：**每次被击中重掷一次**（可能不变）；血越少越容易掷到高值；
## 不受伤则保持当前值、不衰减。低难度块里有 24 / 28，**挨打也可能变弱**。

## 块 1~4（十进制，逐块照抄 doc/08 §2 的 ROM 表；块 1 / 3 的原始转录各有 1 项
## 出入，多退少补不影响概率量级，实测时按 ROM 逐字节校正）
const BLOCK_1: Array[int] = [
	24, 28,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	36, 42, 48,
]
const BLOCK_2: Array[int] = [
	28,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	36, 36, 42, 42, 48,
]
const BLOCK_3: Array[int] = [
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32,
	36, 36, 36, 42, 42, 48, 48,
]
const BLOCK_4: Array[int] = [
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32,
	36, 36, 36, 36, 42, 42, 42, 48, 48, 64,
]

const BLOCKS: Array = [BLOCK_1, BLOCK_2, BLOCK_3, BLOCK_4]

## 基准力量（×1.00）
const BASE: int = 32


## 最终伤害 = 基础 × 力量 / 32（ROM 里是 `>> 5`，见 doc/10 §1）
static func scale(base_damage: int, power: int) -> int:
	return maxi(base_damage * power >> 5, 1)


## 被击中后重掷力量。`lost_ratio` = 已损失 HP 比例。
## 精确加权公式未逆向 `[推定]` TODO[实测]：这里用「重掷概率 = 已损失比例」，
## 保证满血几乎不变、残血大概率变，且不受伤不衰减。
static func roll(block_index: int, current: int, lost_ratio: float) -> int:
	if randf() > clampf(lost_ratio, 0.0, 1.0):
		return current
	var block: Array = BLOCKS[clampi(block_index, 1, BLOCKS.size()) - 1]
	return block[randi() % block.size()]
