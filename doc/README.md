# 恐龙快打 开发资料

本目录收集 Capcom 1993 年街机清版动作游戏《恐龙快打》
（Cadillacs and Dinosaurs / キャディラックス 恐竜新世紀）的玩法与数据资料，
供本仓库的 Godot 复刻工程使用。

## 文档索引

每份文档开头都有 **「结论（TL;DR）」** 小节，赶时间可以先只读结论，再按需深入正文。

| 文档 | 内容 |
| --- | --- |
| [01-game-overview.md](./01-game-overview.md) | 游戏概述：版本、硬件、剧情、基础规则 |
| [02-characters.md](./02-characters.md) | 四名可选角色的定位与完整招式表 |
| [03-controls-and-system.md](./03-controls-and-system.md) | 操作方式、组合技、分数与续关等系统规则 |
| [04-weapons-and-items.md](./04-weapons-and-items.md) | 武器、投掷物、载具与道具 |
| [05-stages.md](./05-stages.md) | 八个关卡的场景、机制与 Boss |
| [06-enemies-and-bosses.md](./06-enemies-and-bosses.md) | 敌人与 Boss 名单及行为 |
| [07-dev-reference.md](./07-dev-reference.md) | 复刻实现参考：数值取舍与实现要点 |
| [08-rom-data-tables.md](./08-rom-data-tables.md) | **原版 ROM 数据表**（血量、伤害、弹药、食物回复、掉落表、关卡尺寸、内存地址） |
| [09-development-plan.md](./09-development-plan.md) | **开发计划**：现阶段只实现第 1 关 —— 里程碑 M0~M6、数据准备清单与占位策略 |

## 关于数据可靠性的说明

- 街机原版从未公开过官方数值表（HP、伤害、帧数等），
  但社区已经有**从 ROM 逐字节提取**的可靠数据，
  已汇总在 [08-rom-data-tables.md](./08-rom-data-tables.md)。
- 本目录中的文档对每条数据都标注了 **来源** 与 **可信度**：
  - `[ROMDATA]` —— 由第三方 ROM 编辑器 / 汇编项目从 ROM 镜像逐字节提取，**可信度最高**。
  - `[MOD引原版]` —— 来自 ROM hack 的改动日志，日志写明了被替换掉的**原版值**。
  - `[原版实测/文档]` —— 有玩家实测或攻略站文档佐证。
  - `[社区分析]` —— 来自拆包、逆向或社区整理。
  - `[推定]` —— 为复刻需要而给出的建议值，**并非原版数据**。
- 优先使用 `[ROMDATA]` / `[MOD引原版]` 的数据；
  仍标 `[推定]` 的部分是需要实测补齐的空白。

## 主要资料来源

| 来源 | 说明 |
| --- | --- |
| [RQ87's Cadillacs and Dinosaurs shrine](https://rq87.flyingomelette.com/RQ/CAD/main.html) | 角色招式、武器、关卡要点、常见问题，最详细的中立资料站 |
| [`GameHackFan/cdree`](https://github.com/GameHackFan/cdree) | CAD 的 ROM 编辑器，含逐字节提取的数值表（血量、弹药、食物、掉落、关卡尺寸） |
| [`GameHackFan/dinore`](https://github.com/GameHackFan/dinore) | `cdree` 的汇编 hack，改动日志中记录了**原版数值** |
| [`zelurker/raine`](https://github.com/zelurker/raine) | Raine 模拟器的作弊脚本，提供 Boss HP 等内存地址 |
| [MAME](https://www.mamedev.org/) | 街机基板、ROM 版本与区域差异（`mamedev/mame` 驱动源码） |
| [GameFAQs: Cadillacs and Dinosaurs FAQ](https://gamefaqs.gamespot.com/arcade/575551-cadillacs-and-dinosaurs/faqs/53882) | 社区整理的攻略与招式说明（**目前无法访问**，见下） |
| [`bombzj/arcade-sprite-viewer`](https://github.com/bombzj/arcade-sprite-viewer) | 街机精灵 / 背景查看器（CPS1 / NEOGEO 等），支持本作：从 ROM 拼装精灵、动画与整关场景图，**可显示命中盒**，可在线使用（asv.bombzj.com），适合做美术与判定参考 |
| [The Cutting Room Floor](https://tcrf.net/) | 未使用素材（未采用的开发人员头像、未使用的小恐龙等，**目前无法访问**） |

> **已知的资料缺口**：GameFAQs 的 FAQ 53882 与 TCRF 页面目前都无法抓取
> （403 / 传输失败）。根据社区索引，这两处最可能包含
> **各招式具体伤害值、宝物分值、加命阈值、输入窗口帧数**，
> 这些数据目前在本目录中标记为 `[待核对]`。

各文档正文中会给出更细粒度的引用链接。

## 版权

本目录仅记录游戏机制与数值，用于技术研究与复刻参考。
《Cadillacs and Dinosaurs》的商标、美术、音乐等版权归 Capcom 及相关权利人所有，
本仓库不包含任何原版素材。
