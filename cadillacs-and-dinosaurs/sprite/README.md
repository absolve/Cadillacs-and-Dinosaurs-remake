# 精灵素材包（res://sprite）

《恐龙快打》dino（World 930201）ROM 解码出来的美术素材，
由 `E:/arcade-sprite-viewer-master/analysis/export.js` 离线解码
（`rom/dino.gfx` 4MB 图块 + 68k 程序镜像），再由
[`tools/import_dino_sprites.py`](../../tools/import_dino_sprites.py) 导入本工程。

## 结论（TL;DR）

1. **187 个动画集 / 2335 段动画 / 12460 帧**，共 3260 个 PNG，约 21 MB；
   按 `players / enemies / weapons / items / effects / npc / backgrounds / extras` 分类。
2. **一段动画 = 一张表**：`<分类>/setNNN/actNN.png`，等宽等高、无间隔的网格，
   每行最多 8 帧（列数 `cols = min(8, frameCount)`）。
3. **`manifest.json` 是唯一索引**：ROM 地址、帧数、单帧尺寸、网格、锚点、是否循环都在里面，
   不需要再解析散落的 `act.json`。
4. **锚点是脚底**：`anchor = [-bbox.x, -bbox.y]`，即该帧画布内对应 ROM 坐标原点的像素；
   绘制时 `Sprite2D.centered = false`、`offset = (-anchor[0], -anchor[1])`。
5. **`setNNN` 就是 ROM 动画集号**（`0xB7472` 表的第 NNN 条）：
   与 [10-damage-and-hit-data.md §8.2](../../doc/10-damage-and-hit-data.md) 的地址逐一比对，
   185 个集的表指针**完全一致**，可以直接用集号做美术↔判定数据的关联键。
6. **全部按第 1 关第 1 场景调色板（0-0）渲染**：敌人换色、镜像翻转都要在引擎里自己做。
7. **Godot 侧直接用 `.tres`**：`sprite/frames/<分类>/<角色组>/setNNN.tres`
   是 `DinoAnimSet`（内含 `SpriteFrames` + 锚点），187 个资源 / 2335 段动画，
   由 `res://tools/build_sprite_frames.gd` 从 `manifest.json` 生成，运行时只取用不重建。

## 目录结构

```
sprite/
├── manifest.json                      全量索引（切片 + 锚点 + ROM 地址）
├── README.md                          本文件
├── frames/…/setNNN.tres               生成的 DinoAnimSet + SpriteFrames（187 个，见下文）
├── players/<角色组>/setNNN/actNN.png   26 集 / 499 段 / 2433 帧
│   ├── 01_jack/  02_mustapha/  03_hannah/  04_mess/
├── enemies/setNNN/actNN.png            91 集 / 1171 段 / 5033 帧（含 Boss、恐龙、动物）
│   └── palette.png                     91 张敌人配色对照表（2x，带「关卡-场景」标签）
├── weapons/setNNN/actNN.png             20 集 / 376 段 / 4178 帧（武器与投射物）
├── items/setNNN/actNN.png               27 集 / 187 段 / 366 帧（道具、奖励、可破坏场景物）
├── effects/setNNN/actNN.png             22 集 / 97 段 / 443 帧（火花、碎片、断肢）
├── npc/set108/actNN.png                  1 集 /  5 段 /   7 帧（非战斗 NPC）
├── backgrounds/LN_SM_layerX.png          44 张滚动层（每屏 256×256 的整关地图）
└── extras/                               603 张
    ├── title/    标题 logo、Cadillac 车（8 张）
    ├── credits/  开场字幕（3 张）
    ├── ui/       STAGE CLEARED 等（1 张）
    └── unused/   591 张「动画表未引用」的散帧 + `index.json`（帧号↔文件）
```

每个集目录还有一张 `preview.png`（该集代表帧，做选择器缩略图用），187 张。

## manifest.json 结构

```jsonc
{
  "generated": "...", "source": "E:/arcade-sprite-viewer-master/export/dino",
  "sets": [
    {
      "set": 0,                       // ROM 动画集号 = 0xB7472 表下标
      "category": "players",          // players|enemies|weapons|items|effects|npc
      "group": "jack",                // 仅玩家；null 表示非玩家
      "romAddr": "0x9e41c",           // 该集动画表指针（已与逆向数据核对一致）
      "dir": "players/01_jack/set000",// 相对 res://sprite
      "acts": [
        {
          "act": 0, "file": "act00.png",
          "count": 14, "w": 64, "h": 96, "cols": 8, "rows": 2,
          "anchor": [40, 96],         // 画布内脚底/ROM 原点位置
          "frames": [0,0,0,2,3, ...], // 该段引用的 ROM 帧号（重复项=同一张图多帧停留）
          "loop": true,               // 是否循环（false 表示攻击/受击等结束段）
          "terminated": false         // ROM 动画链是否带结束标志
        }
      ]
    }
  ],
  "backgrounds": ["L1_S1_layer2.png", ...],
  "extras": { "title": {"dir": "extras/title", "files": [...]}, ... }
}
```

## 切片与锚点

第 `i` 帧（0 基）在这张表上的矩形：

```
x = (i % cols) * w
y = (i // cols) * h
size = (w, h)
```

Godot 侧不用手写切片：`tools/build_sprite_frames.gd` 已经把每个集生成好
`SpriteFrames` + 锚点（见下一节）。需要自己切片时公式就是上面三行，例如：

```gdscript
var at := AtlasTexture.new()
at.atlas = load("res://sprite/players/01_jack/set000/act00.png")
at.region = Rect2((i % cols) * w, (i / cols) * h, w, h)
sprite.centered = false
sprite.offset = Vector2(-anchor[0], -anchor[1])   # anchor 来自 manifest
sprite.flip_h = facing == 1                       # ROM：+0x24 朝向 0=左、1=右
```

最大的一张表 **1808×1260**（`enemies/set109/act21.png`，67 帧），
最宽的 `enemies/set086/act01.png` 为 1904×64；导入后请保持纹理不压缩或至少保留 alpha，避免边缘渗色。

## SpriteFrames `.tres`（推荐用法）

`cadillacs-and-dinosaurs/tools/build_sprite_frames.gd` 读 `manifest.json`，
**每个动画集生成一个 `DinoAnimSet` 资源**（内含 `SpriteFrames`），
目录与素材目录一一对应：

```
sprite/frames/players/01_jack/set000.tres     # 26 玩家集
sprite/frames/enemies/set024.tres             # 91 敌人集
sprite/frames/weapons|items|effects|npc/...    # 共 187 个 .tres / 2335 段 / 12460 帧槽，2.7 MB
```

`DinoAnimSet`（[script/data/dino_anim_set.gd](../script/data/dino_anim_set.gd)）字段：

| 字段 | 含义 |
| --- | --- |
| `set_index` / `category` / `group` / `rom_addr` | 集号、分类、角色组、ROM 动画表指针（与逆向文档对账用） |
| `sprite_frames` | `SpriteFrames`，动画名 `act00…actNN`，帧为去重后的 `AtlasTexture`，已带 `loop` 与 fps |
| `acts` | `act 名 -> {anchor, size, cols, rows, count, loop, terminated, sheet, frames}` |
| `anchor_of(anim)` / `rom_frames_of(anim)` / `is_terminated(anim)` | 常用取值的封装 |

角色场景里直接用（工程里 [FightObject](../script/core/fight_object.gd) 就是这么做的）：

```gdscript
## 下标 = ROM 动画组号；玩家按组挂 6 个集，敌人只挂组 0
@export var anim_groups: Array[DinoAnimSet]
@onready var sprite: AnimatedSprite2D = $Body/Sprite

## 动画引用写成 "gN/actMM"（N = 组号，MM = 十进制段号）
func play_ref(ref: String) -> void:
    var parts := ref.split("/")                      # ["g1", "act11"]
    var set := anim_groups[int(parts[0].trim_prefix("g"))]
    sprite.sprite_frames = set.sprite_frames         # 换组 = 换 SpriteFrames
    sprite.offset = -set.anchor_of(parts[1])         # 脚底对齐到节点原点
    sprite.centered = false
    sprite.play(parts[1])
```

> **fps 默认 30**：ROM 每帧的实际停留帧数还没提取出来（doc/10 §8.6 第 3 项），
> 先用统一值；需要按段调整时用 `--fps=` 重生成，或在编辑器里直接改 `.tres` 的动画速度。
> 帧号重复（`frames: [0,0,0,2,3,…]`）本身已经表达了「同一张图停留多帧」。

## 与逆向文档的对应关系

| 需要的数据 | 素材包提供 | 逆向文档提供 |
| --- | --- | --- |
| 美术长什么样 | `actNN.png` + `preview.png` | — |
| 动画集 ↔ 敌人 | `setNNN` 集号、`romAddr` | [10 §8.2](../../doc/10-damage-and-hit-data.md) 集→盒子组 |
| 逐帧判定盒 | `frames[]` 帧号顺序 | [10 §8.5](../../doc/10-damage-and-hit-data.md) `E:/rea_ai_work/player_frame_boxes.tsv` |
| AI 状态 → 动画 | `act` 段号 | [09 附录 G](../../doc/09-enemy-and-boss-ai.md) 状态表里的 `anim=` |
| 敌人换色 | `enemies/setNNN/palette.png` | [10 §2](../../doc/10-damage-and-hit-data.md) 攻击表 |

> **段号 = ROM 动画 ID（2026-11-01 已确认）**：ROM 里 `0x120E` / `0x13A0` 播动画时做
> `move.w (0,集表,D0*2),D0` —— `D0` 就是集表里 word 偏移表的下标，
> 与本包 `actNN` 的 NN **同一个编号**（本包用**十进制**命名，反汇编与探针日志里的
> `D0` 是**十六进制**，`D0=0x0d` 对应 `act13`）。所以「某段动画」可以直接和 ROM 代码对接
> （推导与证据见 [10 §8.8](../../doc/10-damage-and-hit-data.md)、实测状态表见
> [10 §8.11](../../doc/10-damage-and-hit-data.md)）。
> 唯一别混的是 [10 §8.5](../../doc/10-damage-and-hit-data.md) 那份逐帧盒 TSV：
> 它的 `anim` 下标语义相同，但我方遍历的**段数**与素材包不一致（停止条件不同），
> 拼接时以素材包的 `actNN` 为准。

### 玩家槽位是共用的（工程已按此接线）

四人各自的基础集（`01_jack/set000`、`02_mustapha/set006`、`03_hannah/set012`、
`04_mess/set018`）**都是 32 段**，段号的 `loop / terminated` 标志几乎逐格一致，
其中 11 个段号四人帧数完全相同（act01 走路 12f、act09 奔跑 8f、act22 直拳 3f …）。
所以**一套槽位表就能服务四个角色**，换角色只需换动画集与帧数表：

- 槽位表落在 `scene/actor/player/player.tscn` 的 `act_map`（通用玩家场景），
  `jack.tscn` / `hannah.tscn` 只覆盖 `character_stats` 与 `anim_groups`；
- 槽位↔招式的对应**已用 FBNeo 运行时探针实测**（[10 §8.11](../../doc/10-damage-and-hit-data.md)）：
  玩家一个对象同时用组 0/1/3/5，组号 = `基础集 + N`（Jack `set000..005`、Hannah `set012..017`），
  所以 `act_map` 的值写成 `"gN/actMM"`（N 组号、MM **十进制**段号，ROM 里的 `D0` 是十六进制）；
- 早期 [10 §8.7](../../doc/10-damage-and-hit-data.md) 的逐格命名是人工看帧图的功能级猜测，
  其中 `attack1→act22`、`jump→act05` 已被实测否证，只当美术参考；
- 敌人侧不适用：杂兵每个集槽位各不相同，`enemies/setNNN` 换集就要重看。

## 已知限制

- **调色板**：一切按 `0-0`（第 1 关第 1 场景）渲染。敌人实际按关卡换色，
  复刻里要么用 shader 做色盘替换，要么用 `palette.png` 对照后重导。
  玩家用固定 0–3 号色盘，所以玩家不涉及换色。
- **未做水平镜像**：所有帧都是 ROM 存储的原始朝向（导出器不解释图块的 X-flip 位），
  哪一面是「朝左」请用 `preview.png` 对照游戏画面确认后再决定 `flip_h` 的条件。
- **CPS1 用 15 号笔做透明键**，已按此处理；查看器原样显示时才会画出该色。
- 有 **8 段**动画只包含 ROM 里的空白占位帧（全透明 16×16），表看起来是空的属正常。
- `extras/unused/` 的散帧没有动画表记录，无法判断游戏用哪一页调色板，统一按 `0-0` 导出。
- 动画集 **86、95** 在 `0xB7472` 逆向表里取不到有效盒子组（负数组号，走 `0x100000` 之外的分支），
  素材包里仍按查看器的解码给出了图，用作美术参考可以，接判定数据时要单独确认。

## 重新生成

素材源仓库更新后（或需要换调色板页重导）：

```bash
# 1) 在 arcade-sprite-viewer 仓库里重跑离线解码，产出 export/dino/
node analysis/export.js
# 2) 导入本工程（可选自定义源/目标路径），产出 PNG 表 + manifest.json
python tools/import_dino_sprites.py [SRC] [DST]
# 3) 生成 SpriteFrames .tres（仓库根目录执行；--only=players 可只跑一部分）
E:/Godot_v4.7.2-stable_win64_console.exe --headless --path ./cadillacs-and-dinosaurs \
    --script res://tools/build_sprite_frames.gd -- --fps=30
# 4) 回读校验：逐个 .tres 与 manifest 对账，有问题时非 0 退出
E:/Godot_v4.7.2-stable_win64_console.exe --headless --path ./cadillacs-and-dinosaurs \
    --script res://tools/verify_sprite_frames.gd
```

第 2 步会**清空并重建** `sprite/` 下的分类目录与 `manifest.json`，
第 3 步只重建 `sprite/frames/`；所以不要手工往
`sprite/{players,enemies,weapons,items,effects,npc,backgrounds,extras,frames}/` 里塞文件。
想在编辑器里微调（改某段 fps、勾 loop、删帧）可以直接改 `.tres`，
但重跑第 3 步会覆盖，长期改动请回写到 `manifest.json` 的生成脚本里。
