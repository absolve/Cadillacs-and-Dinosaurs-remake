# Cadillacs-and-Dinosaurs-remake

使用 Godot 重置的恐龙快打 —— 未完成

本仓库使用 Godot 4 复刻 Capcom 1993 年的街机清版动作游戏《恐龙快打》
（Cadillacs and Dinosaurs / キャディラックス 恐竜新世紀）。

## 目录结构

```text
Cadillacs-and-Dinosaurs-remake/
├── doc/                          # 游戏资料（人物数值、招式、关卡等），供开发参考
└── cadillacs-and-dinosaurs/      # Godot 工程
    ├── addons/                   # 编辑器插件
    ├── autoload/                 # 全局单例（Autoload）脚本
    ├── build/                    # 导出产物（内容不纳入版本控制）
    ├── font/                     # 字体
    ├── lang/                     # 本地化（翻译文件）
    ├── scene/                    # 场景（.tscn）
    ├── script/                   # GDScript 脚本
    ├── shader/                   # 着色器
    ├── sound/                    # 音频资源
    ├── sprite/                   # 图像资源
    ├── theme/                    # UI 主题
    ├── tools/                    # 开发辅助脚本
    ├── default_bus_layout.tres   # 音频总线布局（Master / Music / Sfx）
    ├── icon.svg                  # 项目图标
    └── project.godot             # 项目配置
```

## 开发环境

| 项目 | 值 |
| --- | --- |
| 引擎版本 | Godot 4.7.2 stable |
| 渲染后端 | GL Compatibility |
| 基准分辨率 | 384 × 224（CPS-1 原生分辨率），窗口 3 倍整数缩放至 1152 × 672 |
| 拉伸模式 | `viewport` + `integer`（像素画不失真） |
| 默认纹理过滤 | 最近邻（Nearest） |

用 Godot 打开 `cadillacs-and-dinosaurs/project.godot` 即可。
命令行验证工程可正常导入（`<GODOT>` 为本机的 `Godot_v4.7.2-stable_win64_console.exe`）：

```powershell
& "<GODOT>" --headless --path .\cadillacs-and-dinosaurs --import
```

### 美术素材流水线

ROM 解码出的精灵已按分类导入 `cadillacs-and-dinosaurs/sprite/`，
`.tres` 由工程内脚本生成（细节与限制见
[sprite/README.md](cadillacs-and-dinosaurs/sprite/README.md)）：

```bash
python tools/import_dino_sprites.py                  # 导出包 → sprite/ 分类 PNG + manifest.json
& "<GODOT>" --headless --path .\cadillacs-and-dinosaurs `
    --script res://tools/build_sprite_frames.gd      # manifest → sprite/frames/**.tres
& "<GODOT>" --headless --path .\cadillacs-and-dinosaurs `
    --script res://tools/verify_sprite_frames.gd     # 回读 .tres 与 manifest 对账
# 一次性（已执行，marker 防重复）：人物/敌人条图就地镜像成朝右存储
& "<GODOT>" --headless --path .\cadillacs-and-dinosaurs `
    --script res://tools/flip_facing.gd
```

> 主场景当前指向**测试房** `res://scene/test/test_room.tscn`（灰盒街道 + 玩家 / 敌人沙盒）。
> 无头跑一遍状态与功能回归断言：
>
> ```powershell
> & "<GODOT>" --headless --path .\cadillacs-and-dinosaurs res://scene/test/test_room.tscn
> ```
>
> 关卡加载（StageDirector / AreaData，第 1 关灰盒数据 + `scene/stage/stage01/` 正式场景 v1）
> 单独一套断言（37 项：
> 区域排布 / Y 带 / 摄像机夹取与单向推进 / 触发线刷怪 / 锁屏墙 / 全灭解锁 / 人数标记过滤 /
> 玩家卡片 HUD / 4 人改版（p4 输入与 count_flag=8）/ stage01 背景铺设计）：
>
> ```powershell
> & "<GODOT>" --headless --path .\cadillacs-and-dinosaurs res://scene/test/stage_flow_test.tscn
> ```
>
> 100 项断言（动画组与 `act_map` / 招式两段式动画 / 移动 / 纵深 / 边界 / 跳跃 / 飞踢 / 贴地影子 /
> 三段连击 / hit-confirm / 一次挥击只结算一次 / 力量缩放 / 击倒→起身→眩晕 /
> 60 帧免疫 / 敌人 AI / 高度轴 / 死亡 / 慢放 tick 门控与全屏慢放）
> 全绿才算通过；退出码非 0 即有断言失败。图形界面下加 `-- --auto` 同样会跑断言。

## 操作映射

街机原版为「摇杆 + 攻击 + 跳跃」两键布局，工程内的输入映射与之对应。

### 全局

| 动作 | 键位 |
| --- | --- |
| `start` | `1` / `Enter` / 手柄 Start |
| `coin` | `5` / 手柄 Back |
| `pause` | `Esc` / `P` |
| `toggle_fullscreen` | `F11` |

### 玩家 1（同时支持手柄）

| 动作 | 键位 |
| --- | --- |
| `p1_up` / `p1_down` / `p1_left` / `p1_right` | `W` / `S` / `A` / `D`，手柄十字键或左摇杆 |
| `p1_attack` | `J`，手柄 X / RB |
| `p1_jump` | `K`，手柄 A / LB |

### 玩家 2 / 玩家 3 / 玩家 4（改版 4 人同屏）

| 动作 | 键位（玩家 2 / 玩家 3 / 玩家 4） |
| --- | --- |
| 上 / 下 / 左 / 右 | `↑` `↓` `←` `→` / 小键盘 `8` `5` `4` `6` / `T` `G` `F` `H` |
| `attack` | 小键盘 `1` / 小键盘 `7` / `R` |
| `jump` | 小键盘 `2` / 小键盘 `9` / `Y` |

> 原版为 3 人同屏；本工程按改版扩到 4 人（拍板与口径见 [doc/09 §改版拍板](./doc/09-development-plan.md)）。

组合招式由输入顺序判定，例如「攻击 + 跳跃」同时按下即触发必杀技，
因此输入映射中不存在单独的必杀技动作。

### 物理层

| 层 | 名称 | 用途 |
| --- | --- | --- |
| 1 | `player` | 玩家角色受击体 |
| 2 | `enemy` | 敌人 / Boss 受击体 |
| 3 | `player_attack` | 玩家攻击判定 |
| 4 | `enemy_attack` | 敌人攻击判定 |
| 5 | `pickable` | 可拾取物（武器、食物、分数道具） |
| 6 | `obstacle` | 场景障碍物 / 墙体 |
| 7 | `trigger` | 关卡触发器 / 摄像机边界 |

渲染层 `1 background`、`2 world`、`3 actor`、`4 fx` 用于清版动作游戏的深度排序。

## 参考资料

游戏玩法、角色数值、敌人配置等开发资料收集在 [doc/](./doc/) 目录下：

| 文档 | 内容 |
| --- | --- |
| [doc/01-game-overview.md](./doc/01-game-overview.md) | 游戏概述：版本、基板、剧情、区域差异 |
| [doc/02-characters.md](./doc/02-characters.md) | 四名角色的数值、定位与完整招式表 |
| [doc/03-controls-and-system.md](./doc/03-controls-and-system.md) | 操作、受击 / 眩晕 / 无敌规则、分数与续关 |
| [doc/04-weapons-and-items.md](./doc/04-weapons-and-items.md) | 武器、弹药、食物回复量、掉落表 |
| [doc/05-stages.md](./doc/05-stages.md) | 八个关卡的尺寸、时间限制、Boss 与刷怪结构 |
| [doc/06-enemies-and-bosses.md](./doc/06-enemies-and-bosses.md) | 敌人与 Boss 名单、HP 分层、恐龙机制 |
| [doc/07-dev-reference.md](./doc/07-dev-reference.md) | 复刻实现参考：数值取舍与实现要点 |
| [doc/08-rom-data-tables.md](./doc/08-rom-data-tables.md) | **原版 ROM 数据表**（血量、伤害、弹药、掉落、内存地址） |

其中的核心数值（角色 HP 100、连击伤害 68/67/65/78、必杀消耗 14、
武器弹药、食物回复量、敌人 HP 分层、关卡尺寸与时间限制等）
**都是从原版 ROM 中逐字节提取的**，可以直接用于实现。

## 授权

见 [LICENSE](./LICENSE)。
