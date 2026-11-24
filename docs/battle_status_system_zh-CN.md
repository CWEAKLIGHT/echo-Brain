# 战斗状态系统（Prototype 0.1）

## 当前实现边界

状态系统目前作为独立基础设施存在，尚未接入 BattleController 的实际伤害和回合流程。新增/移除状态不会自动改变伤害、属性、敌方意图或 UI。技能接入必须在后续单独提交，并为每条效果增加控制器级测试。

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
- `remove_status`：按 ID 移除。
- `clear_actor`：清空单位全部状态。

## 计划中的状态映射

| 状态 ID | 来源技能 | 计划行为 | 目前是否接入 |
|---|---|---|---|
| `oathguard` | 誓盾架势 | 下一次受击减伤后消耗 | 否 |
| `watchwall` | 守望壁垒 | 区域内友方减伤，阶段边界移除 | 否 |
| `judgment_mark` | 裁决印记 | 干预目标下一次攻击，随后消耗 | 否 |
| `echo_counter` | 回响反击 | 下一次符合条件的攻击命中时触发 | 否 |
| `exposed` | 裁决印记/誓约裁断 | 降低防御与魔抗，按阶段到期 | 否 |

## 验证

新增 `tests/test_battle_status.gd` 覆盖状态创建、查询、触发消耗、阶段到期、三种叠加策略、刷新持续信息、非法输入、显式移除和单位清理。

运行命令（Godot 4.7.2 环境）：

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_battle_status.gd
```

远程文件写入和回读只证明文件已提交，不等于 Godot 导入或测试通过。
