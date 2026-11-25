# ECHO

ECHO 是一款使用 Godot 4.7.2 Standard 与 GDScript 开发的 2D 回合制战术游戏原型。

## 项目状态

- **里程碑**：Prototype 0.1，可运行战斗切片
- **引擎版本**：Godot 4.7.2 Standard
- **桌面开发与验证平台**：Windows 10/11（64 位）
- **目标画面**：1280 × 720，横向布局
- **移动端方向**：Android 横屏；本阶段优先完成 Windows 桌面导入与玩法验证
- **验证状态**：已在 Godot 4.7.2 中完成导入、六个测试套件与主场景无头运行（2026-11-25，300 条断言 0 失败，详见 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md`）；Windows 交互与画面、Android 导出仍待人工验证

本仓库是 ECHO 的独立项目，与「拾光」完全分离。

## Windows 导入与运行

1. 安装 **Godot 4.7.2 Standard** 的 Windows x86_64 版本。不要下载 .NET 版本。
2. 在 GitHub 仓库页面下载 `prototype/0.1` 分支 ZIP，并完整解压到普通文件夹。
3. 启动 Godot，在项目管理器中点击 **导入（Import）**。
4. 选择解压目录中的 `project.godot` 文件，点击导入并编辑。
5. 等待首次资源扫描完成，然后按 **F5** 运行主场景。

也可以直接下载当前开发分支：

- [下载 prototype/0.1 分支 ZIP](https://github.com/qingxu443-dev/echo-game/archive/refs/heads/prototype/0.1.zip)
- [打开 ECHO GitHub 仓库](https://github.com/qingxu443-dev/echo-game/tree/prototype/0.1)

首次运行不需要 Android 导出模板，也不需要 Godot .NET 版本。

## 当前可玩的战斗内容

- 瑟弗林（守誓者）与 8 × 8 正交网格战场。
- 三种敌人：先锋、神射手、区域术士。
- 每回合 3 点 AP；移动消耗 1 AP，最多移动两格；普通攻击消耗 1 AP。
- 敌人意图在玩家回合开始时公开，并按固定顺序执行。
- 五个主动技能已接入第一版战斗界面和控制器：
  - **誓盾架势**：下一次承伤额外降低 35%，符合条件的公开敌方攻击可产生回响。
  - **守望壁垒**：以施放位置为中心建立五格十字区域，区域内友方承伤降低 20%。
  - **裁决印记**：标记 1–4 格内且视线无遮挡的敌人，干预其后续攻击。
  - **回响反击**：预备一次反击；符合条件的公开敌方攻击命中后触发。
  - **誓约裁断**：对 1–2 格内带有裁决印记的敌人造成 1.4×物理伤害，并打断其当前活动意图。
- 技能按钮、AP 消耗、目标选择、目标范围提示和状态标识。
- 鼠标操作与键盘技能快捷键。

## 桌面操作

| 操作 | 输入 |
|---|---|
| 移动 | 鼠标左键点击可到达的格子 |
| 普通攻击 | 点击右侧「普通攻击」，再点击相邻敌人；默认也可直接选择敌人 |
| 誓盾架势 | 点击技能按钮，或按数字键 `2` |
| 守望壁垒 | 点击技能按钮，或按数字键 `3` |
| 裁决印记 | 点击技能按钮或按 `4`，再点击合法敌人 |
| 回响反击 | 点击技能按钮，或按数字键 `5` |
| 誓约裁断 | 点击技能按钮或按 `6`，再点击带有印记的合法敌人 |
| 取消目标选择 | `Esc` 或鼠标右键 |
| 结束回合 | 点击「结束回合」、`Enter` 或空格键 |

数字键 `1` 选择普通攻击。自身技能按下后立即施放；目标技能需要再点击战场上的敌人确认。

## 自动化测试

在项目根目录、Godot 4.7.2 Standard 环境中运行：

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_core_rules.gd
godot --headless --path . --script res://tests/test_battle_status.gd
godot --headless --path . --script res://tests/test_battle_area_effects.gd
godot --headless --path . --script res://tests/test_battle_echo_counter.gd
godot --headless --path . --script res://tests/test_battle_controller.gd
godot --headless --path . --script res://tests/test_battle_view_skills.gd
godot --headless --path . --script res://tests/test_skill_definitions.gd
godot --headless --path . --script res://tests/test_turn_bookkeeping.gd
```

如果 Windows 没有把 Godot 加入 PATH，请使用 Godot 可执行文件的完整路径替换命令中的 `godot`。

以上命令已于 2026-11-25 在 Godot 4.7.2 中全部执行，结果为零失败（八个套件共 369 条断言，详见 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md`）。后续任何改动都应重新执行，并以实际输出中的零失败为准；headless 测试不能替代 F5 主场景的鼠标、键盘和画面检查。

## 当前边界

- 当前主场景直接进入原型战斗，没有正式标题菜单或关卡选择界面。
- 当前战斗界面仍是功能原型表现，不是最终美术。
- 伙伴、章节流程、局外成长、经济和存档不属于当前 Prototype 0.1 范围。
- Android 导出和设备表现尚未验证。
- 所有技能数值仍是待实际对局验证的原型基线。

## 仓库结构

- `docs/`：设计规范、项目状态和验证清单
- `scenes/main/`：主入口场景
- `scripts/battle/`：战斗规则、技能效果、意图与状态系统
- `scripts/actors/`：战斗单位数据
- `scripts/ui/`：原型战斗界面
- `tests/`：规则、控制器、技能效果和 UI 集成测试

ECHO 与「拾光」项目严格隔离。不要将拾光代码、配置或数据加入本仓库。
