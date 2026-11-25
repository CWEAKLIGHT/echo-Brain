# ECHO — 当前架构

本文件描述 **`prototype/0.1` 当前实际存在的实现**，不是规划稿，也不承担进度汇报职责（进度见 `PROJECT_STATUS.md`）。历史演进过程请查阅 git 记录。

最后核对：2026-11-25，`prototype/0.1` @ `906d585`，Godot 4.7.2 导入零错误、六个测试套件 300 条断言 0 失败。

## 目录结构

```
.
├── project.godot                     # Godot 4.7.2 工程配置（1280×720，横屏优先）
├── scenes/main/main.tscn             # 唯一场景，挂载 battle_view.gd
├── scripts/
│   ├── main.gd                       # 极简入口脚本
│   ├── actors/battle_actor.gd        # 战斗单位运行时数据与伤害结算
│   ├── battle/                       # 战斗规则与状态（11 个模块，见下）
│   └── ui/battle_view.gd             # 战斗界面：绘制、输入、技能栏
├── tests/                            # 7 个 SceneTree 无头测试
└── docs/                             # 设计规范、状态记录与验证清单
```

## 模块清单

### 战斗规则（`scripts/battle/`）

| 模块 | 行数 | 职责 | 关键约束 |
|---|---|---|---|
| `battle_controller.gd` | 624 | 战斗权威状态：回合边界、AP 动作、意图生成与执行、伤害/死亡、终止判定、有序事件流 | **唯一的权威状态持有者**；UI 只读取，不自行计算 |
| `grid_rules.gd` | 61 | 纯正交网格校验、路径与曼哈顿距离 | 无状态，不持有战斗数据 |
| `ap_budget.gd` | 31 | 确定性 AP 账本：重置、消耗、回合结束清零 | 仅在动作确认后扣除 |
| `combat_math.gd` | 17 | 共享伤害公式，防御采用递减收益 | 物理走防御、法术走法抗 |
| `battle_intent.gd` | 60 | 敌方意图快照，支持 actor / tile / area 三种锁定模式与 active→resolved/canceled 单向生命周期 | **预告展示与敌方执行使用同一份快照** |
| `battle_status.gd` | 44 | 单个状态实例：触发次数（-1 为无限）、到期边界、叠层策略 | — |
| `battle_status_collection.gd` | 191 | 按 actor 聚合状态，处理阶段边界过期与延迟 | 裁决印记可延后一个敌方阶段 |
| `battle_area_effect.gd` | 67 | 区域效果实例（中心、覆盖格、持续时间） | — |
| `battle_area_effect_collection.gd` | 63 | 区域效果集合，同 ID 覆盖 | 守望壁垒按队伍而非固定 ID 判定 |
| `skill_definition.gd` | 45 | 技能的纯数据规格（Resource） | 不含执行逻辑 |
| `oathkeeper_skill_catalog.gd` | 44 | 五个守誓者技能的数据定义 | 数值仍为待实战验证的原型基线 |

### 单位（`scripts/actors/`）

| 模块 | 行数 | 职责 | 关键约束 |
|---|---|---|---|
| `battle_actor.gd` | 73 | 单位身份、阵营、格位、整数血量、承伤与阵亡状态 | 终段减伤在防御/抗性之后应用 |

### 表现层（`scripts/ui/`）

`battle_view.gd`（477 行）是 `Node2D`，负责：绘制 8×8 棋盘、障碍格、单位、意图预告与执行顺序、AP/血量、状态标记、区域效果；处理鼠标/触摸/键盘输入；维护六格技能栏。

输入约定：数字键 `1`–`6` 对应技能栏顺序；`Esc` 或右键取消目标选择；`Enter`/空格结束回合。自身技能按下即施放，目标技能需再点战场上的敌人确认。

## 运行时数据流

```
main.tscn (Node2D + battle_view.gd)
   │
   ├─ 创建并持有 ──> BattleController（权威状态）
   │                    ├─ GridRules        路径与范围校验
   │                    ├─ APBudget         AP 账本
   │                    ├─ BattleActor[]    单位与血量（含敌方三原型）
   │                    ├─ BattleIntent[]   已捕获的敌方意图
   │                    ├─ BattleStatusCollection
   │                    ├─ BattleAreaEffectCollection
   │                    └─ signals: battle_event / battle_finished
   │
   └─ 每帧读取 controller 状态并绘制 ──> 屏幕
        ▲
        └─ 输入事件 ──> controller.request_* 方法 ──> 状态变更 ──> queue_redraw()
```

UI 不计算任何结果：命中、伤害、死亡、意图取消全部由 `BattleController` 判定并发事件。

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
| 猎人同伴及其独立支援行动（P2） | 未实现，无代码、无设计文档 |
| 结算界面与重开循环（P3） | 只有 `battle_finished` 信号；无结算展示与重开流程 |
| Android 布局、触摸适配、导出与真机（P4） | 未开始；当前仅桌面鼠标键盘验证 |
| 标题菜单 / 关卡选择 | 不在 Prototype 0.1 范围 |

## 验证状态

见 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md`：2026-11-25 在 Godot 4.7.2 完成导入、六个测试套件与主场景无头运行。Windows 交互手感、画面观感、Android 真机表现仍未验证。
