# 战斗状态系统（Prototype 0.1）

## 当前实现边界

状态容器已接入 BattleController 的回合边界和死亡/战斗结束清理流程。「誓盾架势」的 `oathguard` 已接入最终伤害修正；「裁决印记」已接入敌方意图快照、伤害削减与破绽结算。技能 UI/目标预览尚未接入。

## 状态数据

每个 BattleStatus 保存：
- `status_id`：稳定状态标识。
- `source_actor_id`：施加来源。
- `target_actor_id`：状态所属单位。
- `stacks` / `max_stacks`：当前层数和上限。
- `remaining_triggers`：剩余触发次数；`-1` 表示不限次数，`0` 表示已耗尽。
- `expiry_boundary`：到达指定阶段边界时移除；空值表示不自动到期。

## 叠加策略

| 策略 | 层数行为 | 触发次数/到期边界 |
|---|---|---|
| replace | 用新层数替换旧层数 | 完全替换为新设置 |
| refresh | 保留当前层数，并按新上限裁切 | 重置为新触发次数和新到期边界 |
| add | 当前层数加新层数，不超过上限 | 重置为新触发次数和新到期边界 |

施加非法 ID、空目标、非正层数、非法触发次数或未知叠加策略会失败且不写入状态。

## 生命周期 API

- `apply_status`：创建或按策略更新状态。
- `has_status` / `get_status`：查询状态。
- `consume_trigger`：消耗一次触发；最后一次触发后自动移除。
- `expire_boundary`：移除目标单位在指定阶段边界到期的状态。
- `expire_all_boundary`：在全体单位范围内处理指定阶段边界。
- `clear_all`：战斗结束或新遭遇初始化时清空全部状态。
- `remove_status`：按 ID 移除。
- `clear_actor`：清空单位全部状态。

## 已接入效果

### 誓盾架势（`oathguard`）

- 在目标下一次成功承受伤害时触发。
- 先按物理防御/魔法抗性结算，再将剩余伤害降低 35%，最终伤害最低为 1。
- 只有实际造成伤害后才消耗一次触发；空区域、已取消意图和零伤害不会消耗状态。
- 触发会写入 `status_triggered` 战斗事件。
- 当前只实现减伤；「来自公开敌方意图时获得回响」尚未接入。

### 裁决印记（`judgment_mark`）与破绽（`exposed`）

- `request_judgment_mark(target_actor_id)` 校验战斗阶段、目标存活/敌对、正交距离 1–4、清晰视线和 1 AP；成功后给目标施加印记。
- 当前回合已公开的活动攻击意图会立即标记为「受裁决」，不改变目标格或区域范围。
- 单体攻击（普通近战、瞄准射击）在防御/抗性结算前将原始伤害降低 25%；攻击实际执行后消耗印记。
- 蓄力格子攻击和区域攻击不降低伤害、不改变预告范围；成功执行后消耗印记，并给攻击来源施加 `exposed`。
- `exposed` 在下一玩家阶段持续有效，使物理防御和魔法抗性各降低 200；玩家结束该回合时到期。
- 待机/追击不被标记为攻击；若本次敌方阶段没有成功执行攻击，印记会在本次阶段结束时延期，并保留到下一次敌方阶段结束。目标下一次生成攻击意图时会被标记；若第二个敌方阶段仍未成功执行攻击，则印记到期。被取消或未命中的攻击不会触发破绽。
- `request_oath_severance(target_actor_id)` 校验 1–2 格、清晰视线、存活敌人、印记与 2 AP；确认后先消耗印记，再取消目标当前活动意图（若有），最后造成 1.4×物理伤害。
- 成功取消时意图原因记录为 `oath_severance`，并发出 `intent_severed` 事件；该敌人在本敌方阶段不会执行该意图。
- 事件包含 `intent_judgment_marked`、`status_applied`、`status_consumed`、`judgment_mark_resolved`、`intent_severed` 与 `skill_resolved`。

## 计划中的状态映射

| 状态 ID | 来源技能 | 计划行为 | 目前是否接入 |
|---|---|---|---|
| `oathguard` | 誓盾架势 | 下一次受击减伤后消耗 | 是（减伤；回响未接） |
| `watchwall` | 守望壁垒 | 区域内友方减伤，阶段边界移除 | 否 |
| `judgment_mark` | 裁决印记 | 单体攻击削伤；蓄力/区域攻击施加破绽 | 是（运行时接口；UI未接） |
| `echo_counter` | 回响反击 | 下一次符合条件的攻击命中时触发 | 否 |
| `exposed` | 裁决印记/誓约裁断 | 降低防御与魔抗 200，持续下一玩家阶段 | 是（裁决印记路径） |

## 验证

新增 `tests/test_battle_status.gd` 覆盖状态创建、查询、触发消耗、阶段到期、三种叠加策略、刷新持续信息、非法输入、显式移除和单位清理。

控制器集成：
- 玩家回合开始处理 `player_phase_start` 到期状态。
- 敌方阶段完成后处理 `enemy_phase_end` 到期状态，再开始下一玩家回合；未成功触发的 `judgment_mark` 可延期至 `enemy_phase_end_next`，最多跨过一个敌方阶段。
- 单位死亡时清除其全部状态；战斗结束和新遭遇初始化时清空状态容器。
- `tests/test_battle_controller.gd` 增加敌方阶段结束到期、死亡清理、誓盾减伤、裁决印记单体削伤、蓄力攻击破绽和追击保留/到期断言。

运行命令（Godot 4.7.2 环境）：

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_battle_status.gd
```

远程文件写入和回读只证明文件已提交，不等于 Godot 导入或测试通过。
