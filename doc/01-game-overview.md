# 游戏概述

> 本页信息主要整理自
> [RQ87's Cadillacs and Dinosaurs shrine](https://rq87.flyingomelette.com/RQ/CAD/main.html)
> 的 [info](https://rq87.flyingomelette.com/RQ/CAD/info.html)、
> [story](https://rq87.flyingomelette.com/RQ/CAD/story.html)、
> [game](https://rq87.flyingomelette.com/RQ/CAD/game.html)、
> [faq](https://rq87.flyingomelette.com/RQ/CAD/faq.html) 页。

## 基本信息

| 项目 | 值 | 可信度 |
| --- | --- | --- |
| 英文名 | Cadillacs and Dinosaurs | `[原版实测/文档]` |
| 日文名 | キャディラックス 恐竜新世紀 | `[原版实测/文档]` |
| 常见中文名 | 恐龙快打（又名：恐龙新世纪、凯迪拉克与恐龙） | `[原版实测/文档]` |
| 开发 / 发行 | Capcom | `[原版实测/文档]` |
| 发行时间 | 1993 年 4 月（街机） | `[原版实测/文档]` |
| 类型 | 横版清版动作（belt-scroll beat 'em up） | `[原版实测/文档]` |
| 操作方式 | 8 向摇杆 + 2 个按键（攻击、跳跃） | `[原版实测/文档]` |
| 同屏人数 | 最多 3 人同时游玩 | `[原版实测/文档]` |
| 可选角色 | 4 名 | `[原版实测/文档]` |
| 关卡数 | 8 关（第 3 关为驾驶关） | `[原版实测/文档]` |
| 基板 | CPS-1 的变种，称为 **CPS Q Sound** | `[原版实测/文档]` |
| 分辨率 | 384 × 224（横向 ROT0） | `[ROMDATA]` |
| 刷新率 | 约 59.6 Hz（引擎内部全部以**帧**计时） | `[文档]` |
| 音乐 / 音效 | QSound | `[原版实测/文档]` |
| 授权来源 | Mark Schultz 的漫画《Xenozoic Tales》 | `[原版实测/文档]` |
| 机台 | 横屏，3 个投币口 | `[ROMDATA]` |

### 关于「最多 3 人」

可选角色有 4 名，但一台机台最多同时投币 3 人；第 4 名角色只能在
人数不足三人的时候被选到。复刻时如果需要 4 人同屏，属于扩展功能，
不属于原版行为。

## 基板与版本

- 游戏运行在 **CPS-1 的变种基板 CPS Q Sound** 上。该基板与普通 CPS-1
  基本一致，但音频部分换成了 QSound 芯片，因此本作音乐效果明显好于
  同期的 CPS-1 作品。`[原版实测/文档]`
- 因此本作的音频需要按 QSound 的方式处理：**音源采样率约为 24 kHz
  （QSound 输出为 24000 Hz 单声道）**，而不是 CPS-1 常见的
  YM2151 + OKI6295 组合。`[社区分析]`

### ROM 版本（MAME romset）

| romset | 区域 | ROM 日期戳 |
| --- | --- | --- |
| `dino` | World | **930201** |
| `dinou` | USA | **930201** |
| `dinoj` | Japan | **930201** |
| `dinoa` | Asia TW | **930223** |
| `dinopic` / `dinopic2` | 盗版（bootleg） | — |
| `dinohunt` | 改版（见作弊库） | — |

来源：`mamedev/mame:src/mame/capcom/cps1_v.cpp`、`cps1bl_pic.cpp` `[ROMDATA]`

### 基板型号

| 项目 | 值 |
| --- | --- |
| A 板（World / USA / Asia TW） | **91635B-2** |
| A 板（Japan） | **91634B-2** |
| B 板 | **CD63B** |
| PAL | BPRG1 / IOB1 / 92641C-1 |
| 自定义芯片 | CPS-B-21、DL-0921-10014、IOC1 |
| 盗版板 | CPS1BL + **PIC16c57** + OKI M6295（无 Z80），PCB 标记 `3M05B` |
| Kabuki 保护解锁表 | `76543210 24601357 4343 43` |

### 民间改版 / 衍生 romset

| romset | 说明 |
| --- | --- |
| `dinot` | *Cadillacs and Dinosaurs Turbo 97* |
| `dinos284` | 带 KOD 音效的版本 |
| `dinore`（HBMame `dinos283`） | **Readjusted** hack，本目录大量「原版数值」即来自它的改动日志 |
| `dinohb` | 社区改版 |

> 民间盗版改版通常修改了可选角色或敌人配置，**不属于原版行为**，
> 复刻时不要照搬。

## 剧情背景

### 世界观（RQ87 版本）

> 来源：[story 页](https://rq87.flyingomelette.com/RQ/CAD/story.html)

- 地球被严重污染，接连发生巨大的自然灾害，城市被摧毁，数百万人死亡。
- 为了生存，人类在世界各地建造地下城市，最后所有人都迁入地下生活。
- 地下生活持续了 **600 年**。之后人类决定回到地表，看看外面的世界。
- 回到地表后发现的却是：**恐龙**。这些被认为早已灭绝的物种重新出现，
  并与其它怪物一起在地表自由活动。
- 尽管危险，仍有一部分人类开始重返地表定居 —— 故事由此展开。

### 官方剧情概要（设定在 26 世纪）

> 来源：维基百科正文（经 GitHub 镜像恢复）

- 一伙**「黑市商人（Black Marketeers）」**为了不明目的捕猎恐龙，
  导致恐龙开始攻击人类。
- 四名主角联手对抗：
  - **Jack Tenrec** —— 机械师 / 萨满
  - **Hannah Dundee** —— 外交官 / 探险家
  - **Mustapha Cairo** —— 工程师
  - **Mess O'Bradovich** —— 身份神秘
- **关卡即剧情推进路线**：
  City in the Sea（Vice Terhune）→ 北方森林 / 沼泽森林（Butcher）
  → 乘车的死亡沙漠（被 Hogg 追击）→ Jack 的修车厂（Slice）
  → 燃烧的村庄（Morgan→Morgue）→ 煤矿 + 丛林（Tyrog）
  → **Dr. Simon Fessenden** 的地下据点：图书馆 → 电脑室 → 生物实验室
  → 洞窟 → 实验室（Fessenden 第 1 形态 → 三头形态）
  → 自爆逃脱结局。
- 最终 Boss 全名为 **Dr. Simon Fessenden**。

## 区域差异

> 来源：[区域对比页](https://rq87.flyingomelette.com/R/ARC/C%26D/1.html)

| 项目 | 差异 |
| --- | --- |
| 开场过场 | **有 2 段开场只出现在美版 / 欧版**；**有 1 段只出现在日版** |
| 角色介绍画面 BGM | 美版 / 欧版播放 *C&D Attract 3*；日版播放 *C&D Continue 3* |
| 基板 | 世界版 / 美版 / 亚洲版用 A 板 **91635B-2**，日版用 **91634B-2**，其余相同 |
| 各关 BGM | 第 2 关第 2 段、第 6 关第 3 段、第 7 关第 3 段有独立曲目 |

## 未上市的移植版

- Capcom 曾计划推出 **Capcom Power System Changer（CPS Changer）** 版本，
  并且已经放出过预览，但**最终没有发售**。`[文档]`

## 与其它作品的关系

| 问题 | 说明 | 来源 |
| --- | --- | --- |
| 是改编自动画吗？ | 不是。游戏 1993 年 4 月上市，动画 1993 年 9 月才开播，**游戏在前**。动画延续了基本设定。 | [faq](https://rq87.flyingomelette.com/RQ/CAD/faq.html) |
| 有 SEGA CD / PC 移植版吗？ | **没有**。1994 年 Rocket Science Games 的《Cadillacs and Dinosaurs: The Second Cataclysm》是完全不同的另一款游戏（驾驶射击玩法）。 | [faq](https://rq87.flyingomelette.com/RQ/CAD/faq.html) |
| 为什么没有重制 / 复刻上市？ | 大概率是因为 **通用汽车（General Motors）的授权问题**：Cadillac 是通用旗下品牌，重版费用难以谈拢。 | [faq](https://rq87.flyingomelette.com/RQ/CAD/faq.html) |

## 基础规则

### 币与命

- 默认设置下，**1 个币 = 2 条命**，机台为 **3 人 / 3 投币口**。`[原版实测/文档]`
- 达到一定分数可以加命，但阈值很高，正常通关流程中最多只能加到一两条命，
  实际收益有限。`[原版实测/文档]`（具体阈值 **待核对**，见
  [README 的资料缺口](./README.md#关于数据可靠性的说明)）
- **原版 bug**：在过关结算画面加命会让角色僵住（不再欢呼、无法移动，
  直到下一关载入），并且可能让玩家**变成不死之身**。`[ROMDATA]`

### 续关（Continue）

- 命全部用完后进入续关画面：**Boss 在第一人称视角用枪指着你**，
  并挑衅 *"Eat lead, baby!"*，画面有 **20 秒倒计时**。`[原版实测/文档]`
- 倒计时结束后开枪 → 游戏结束。选择不续关会播放**角色被射杀**的演出。
- 选择续关则播放**角色反击打倒对方**的演出，并从原处继续游戏。
- **续关时可以更换角色**，且续关后角色必定携带一把
  **4 发火箭筒（bazooka）**。`[原版实测/文档]`

### 难度与敌人配置

- 共有 **8 档难度（0~7）**，存放在 DIP 开关 `$FF8022/$FF8023/$FF8024`；
  另有一个「游戏难度 2」字节 `(0x766C,A5)` 专门驱动**敌人 HP 缩放**。`[ROMDATA]`
- DIP 开关 **B6 与 B8** 打开后，游戏会**显示命中盒**（调试用）。`[ROMDATA]`
- 多人游玩时敌人数量与 Boss 数量会相应增加（例如第 7 关的 Slisaur
  在 2~3 人时会出现 3 只）。`[原版实测/文档]`
- 具体的 HP 加成表、敌人槽位预算见
  [08-rom-data-tables.md](./08-rom-data-tables.md#4-敌人-hp-分层)。

## 相关链接

- [RQ87 shrine 首页](https://rq87.flyingomelette.com/RQ/CAD/main.html)
- [区域版本对比页](https://rq87.flyingomelette.com/R/ARC/C%26D/1.html)
- [未使用素材](https://rq87.flyingomelette.com/RQ/CAD/unu.html)
- [音乐](https://rq87.flyingomelette.com/RQ/CAD/music.html)
