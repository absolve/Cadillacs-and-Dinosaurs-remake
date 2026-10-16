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
命令行验证工程可正常导入：

```powershell
& "F:\Godot_v4.7.2-stable_win64_console.exe" --headless --path .\cadillacs-and-dinosaurs --import
```

> 工程尚未设置主场景（`application/run/main_scene`），完成首个场景后
> 在「项目设置 → 应用程序 → 运行 → 主场景」中指定即可。

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

### 玩家 2 / 玩家 3

| 动作 | 键位（玩家 2 / 玩家 3） |
| --- | --- |
| 上 / 下 / 左 / 右 | `↑` `↓` `←` `→` / 小键盘 `8` `5` `4` `6` |
| `attack` | 小键盘 `1` / 小键盘 `7` |
| `jump` | 小键盘 `2` / 小键盘 `9` |

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
