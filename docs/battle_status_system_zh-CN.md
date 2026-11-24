# 战斗状态系统（Prototype 0.1）

## 当前实现边界

状态容器已接入 BattleController 的回合边界和死亡/战斗结束清理流程。「誓盾架势」对应的 `oathguard` 已接入最终伤害修正阶段；其他状态仍未接入敌方意图修改或技能施放。

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

## 计划中的状态映射

| 状态 ID | 来源技能 | 计划行为 | 目前是否接入 |
|---|---|---|---|
| `oathguard` | 誓盾架势 | 下一次受击减伤后消耗 | 是（减伤；回响未接） |
| `watchwall` | 守望壁垒 | 区域内友方减伤，阶段边界移除 | 否 |
| `judgment_mark` | 裁决印记 | 干预目标下一次攻击，随后消耗 | 否 |
| `echo_counter` | 回响反击 | 下一次符合条件的攻击命中时触发 | 否 |
| `exposed` | 裁决印记/誓约裁断 | 降低防御与魔抗，按阶段到期 | 否 |

## 验证

新增 `tests/test_battle_status.gd` 覆盖状态创建、查询、触发消耗、阶段到期、三种叠加策略、刷新持续信息、非法输入、显式移除和单位清理。

控制器集成：
- 玩家回合开始处理 `player_phase_start` 到期状态。
- 敌方阶段完成后处理 `enemy_phase_end` 到期状态，再开始下一玩家回合。
- 单位死亡时清除其全部状态；战斗结束和新遭遇初始化时清空状态容器。
- `tests/test_battle_controller.gd` 增加敌方阶段结束到期和死亡清理断言。

运行命令（Godot 4.7.2 环境）：

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_battle_status.gd
```

远程文件写入和回读只证明文件已提交，不等于 Godot 导入或测试通过。
