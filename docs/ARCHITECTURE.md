# ECHO — 当前架构

本文件描述 **`main` 当前实际存在的实现**，不是规划稿，也不承担进度汇报职责（进度见 `PROJECT_STATUS.md`）。历史演进过程请查阅 git 记录。

最后核对：2026-11-25，`main` @ `36c14a4`，Godot 4.7.2 导入零错误、十五个测试套件 582 条断言 0 失败。

## 目录结构

```
.
├── project.godot                     # Godot 4.7.2 工程配置（1280×720，横屏优先）
├── scenes/main/main.tscn             # 唯一场景，挂载 battle_view.gd
├── scripts/
│   ├── main.gd                       # 极简入口脚本
│   ├── actors/battle_actor.gd        # 战斗单位运行时数据与伤害结算
│   ├── battle/                       # 战斗规则、状态与关卡数据（14 个模块，见下）
│   └── ui/battle_view.gd             # 战斗界面：绘制、输入、技能栏、结算面板
├── assets/ui/summons/                # 猎人通灵的表现层图标
├── tests/                            # 15 个 SceneTree 无头测试
└── docs/                             # 设计规范、状态记录与验证清单
```

## 模块清单

### 战斗规则（`scripts/battle/`）

| 模块 | 行数 | 职责 | 关键约束 |
|---|---|---|---|
| `battle_controller.gd` | 936 | 战斗权威状态：回合边界、AP 动作、意图生成与执行、伤害/死亡、状态与区域结算、护盾与终极能量、猎人通灵、终止判定、结算统计、有序事件流 | **唯一的权威状态持有者**；UI 只读取，不自行计算 |
| `grid_rules.gd` | 95 | 纯网格校验、路径、曼哈顿距离；正交视线与玩家侧直线视线 | 无状态，不持有战斗数据 |
| `ap_budget.gd` | 31 | 确定性 AP 账本：重置、消耗、回合结束清零 | 仅在动作确认后扣除 |
| `combat_math.gd` | 17 | 共享伤害公式，防御采用递减收益 | 物理走防御、法术走法抗 |
| `battle_intent.gd` | 60 | 敌方意图快照，支持 actor / tile / area 三种锁定模式与 active→resolved/canceled 单向生命周期 | **预告展示与敌方执行使用同一份快照** |
| `battle_status.gd` | 44 | 单个状态实例：触发次数（-1 为无限）、到期边界、叠层策略 | — |
| `battle_status_collection.gd` | 186 | 按 actor 聚合状态，处理阶段边界过期与延迟 | 裁决印记可延后一个敌方阶段 |
| `battle_area_effect.gd` | 67 | 区域效果实例（中心、覆盖格、持续时间） | — |
| `battle_area_effect_collection.gd` | 63 | 区域效果集合，同 ID 覆盖 | 守望壁垒按队伍而非固定 ID 判定 |
| `skill_definition.gd` | 47 | 技能的纯数据规格（Resource），含被动标记与新目标模式 | 不含执行逻辑 |
| `oathkeeper_v2_skill_catalog.gd` | 40 | **当前生效**的守誓者 V2 技能数据：裁决印记、誓盾庇护、绝对守护 + 被动不屈誓约 | 数值仍为待实战验证的原型基线 |
| `oathkeeper_skill_catalog.gd` | 44 | v1 旧技能数据，仅供历史追溯与兼容性测试 | **不再接入技能栏**，见 `docs/sevrin_skill_kit_zh-CN.md` 的历史提示 |
| `encounter_definition.gd` | 52 | 单关数据（ID、名称、战术提示、玩家起点、敌人格与兵种、障碍）与布阵自洽校验 | 只描述配置，不持有运行时状态 |
| `level_catalog.gd` | 69 | 三关固定配置：蓄力、射线、混编 | 不使用随机布阵 |

### 单位（`scripts/actors/`）

| 模块 | 行数 | 职责 | 关键约束 |
|---|---|---|---|
| `battle_actor.gd` | 125 | 单位身份、阵营、格位、整数血量、护盾、终极能量、承伤与阵亡状态 | 终段减伤在防御/抗性之后应用 |

### 表现层（`scripts/ui/`）

`battle_view.gd`（562 行）是 `Node2D`，负责：绘制 8×8 棋盘、障碍格、单位、意图预告与执行顺序、AP/血量/护盾/终极能量/守誓层数、状态标记、区域效果、结算面板；处理鼠标/触摸/键盘输入；维护四格技能栏。

输入约定：数字键 `1`–`4` 对应技能栏顺序；`Esc` 或右键取消目标选择；`Enter`/空格结束回合。自身技能按下即施放，目标技能需再点战场上的敌人确认。结算面板出现时，点击只响应「重开本关」与「下一关」。

## 运行时数据流

```
main.tscn (Node2D + battle_view.gd)
   │
   ├─ 读取 ──> LevelCatalog         三关固定配置
   │
   ├─ 创建并持有 ──> BattleController（权威状态）
   │                    ├─ GridRules        路径、范围与视线校验
   │                    ├─ APBudget         AP 账本
   │                    ├─ BattleActor[]    单位、血量、护盾、终极能量
   │                    ├─ BattleIntent[]   已捕获的敌方意图
   │                    ├─ BattleStatusCollection
   │                    ├─ BattleAreaEffectCollection
   │                    └─ signals: battle_event / battle_finished
   │
   └─ 每帧读取 controller 状态并绘制 ──> 屏幕
        ▲
        └─ 输入事件 ──> controller.request_* 方法 ──> 状态变更 ──> queue_redraw()
```

UI 不计算任何结果：命中、伤害、死亡、意图取消、护盾吸收全部由 `BattleController` 判定并发事件。

## 关卡与结算流程

1. `battle_view._ready()` 读取 `LevelCatalog`，调用 `_start_level(0)`。
2. `_start_level(index)` 取出 `EncounterDefinition`，调用 `controller.start_encounter(...)` 重建全部战斗状态（单位、状态、区域、意图、AP、结算统计）。
3. 战斗结束时 `battle_finished` 触发，界面进入结算面板。
4. 点击「重开本关」回到步骤 2；点击「下一关」进入下一索引，最后一关之后回到第 0 关。

## 权威边界（仍然有效）

1. 玩法系统持有权威状态；UI 只读取与呈现，不得独立计算结果。
2. 敌方意图的展示与执行必须使用同一份动作定义与结算规则。
3. 战斗事件必须按已文档化的确定性顺序结算（见 `docs/design/BATTLE_EVENT_TIMELINE_v0.1.md`）。
4. 局外进度与单局临时状态必须分离。
5. 单局状态不得序列化用于进程终止后的恢复。
6. 内容定义应尽量数据驱动，但不得因此掩盖规则或使原型复杂化。

## 当前未实现

| 项 | 状态 |
|---|---|
| Android 布局、触摸适配、导出与真机（P4） | 未开始；当前仅桌面鼠标键盘验证 |
| Windows 人工交互与画面检查 | 自动化与无头运行已通过，真人操作待做 |
| 标题菜单 / 关卡选择 | 不在 Prototype 0.1 范围；关卡只能经结算面板的「下一关」切换 |
| 战斗内存档与恢复 | 明确排除 |

## 验证状态

见 `docs/PROJECT_STATUS.md` 的「验证记录」小节：2026-11-25 在 Godot 4.7.2（Windows）完成导入、十五个测试套件与主场景运行。Windows 人工交互手感、画面观感、Android 真机表现仍未验证。更早的 Linux 无头运行记录保留在 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md` 作为历史参考。
