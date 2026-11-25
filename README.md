# ECHO

ECHO 是一款使用 Godot 4.7.2 Standard 与 GDScript 开发的 2D 回合制战术游戏原型。

## 项目状态

- **里程碑**：Prototype 0.1，可运行战斗切片
- **引擎版本**：Godot 4.7.2 Standard
- **桌面开发与验证平台**：Windows 10/11（64 位）
- **目标画面**：1280 × 720，横向布局
- **移动端方向**：Android 横屏；本阶段优先完成 Windows 桌面导入与玩法验证
- **验证状态**：正式原型基线曾在 Godot 4.7.2 中完成导入与自动化验证（详见 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md`）；当前新版开发分支尚未重新执行 Godot 导入、自动化测试或主场景运行

本仓库是 ECHO 的独立项目，与「拾光」完全分离。

## Windows 导入与运行

1. 安装 **Godot 4.7.2 Standard** 的 Windows x86_64 版本。不要下载 .NET 版本。
2. 在 GitHub 仓库页面下载当前开发分支 ZIP，并完整解压到普通文件夹。
3. 启动 Godot，在项目管理器中点击 **导入（Import）**。
4. 选择解压目录中的 `project.godot` 文件，点击导入并编辑。
5. 等待首次资源扫描完成，然后按 **F5** 运行主场景。

也可以直接下载当前开发分支：

- [下载当前 Oathkeeper v2 开发分支 ZIP](https://github.com/qingxu443-dev/echo-game/archive/refs/heads/feature/oathkeeper-v2-sync-20261125.zip)
- [打开当前开发分支](https://github.com/qingxu443-dev/echo-game/tree/feature/oathkeeper-v2-sync-20261125)
- [打开正式原型分支](https://github.com/qingxu443-dev/echo-game/tree/prototype/0.1)

首次运行不需要 Android 导出模板，也不需要 Godot .NET 版本。

## 当前可玩的战斗内容

- 瑟弗林（守誓者）与 8 × 8 正交网格战场。
- 三种敌人：先锋、神射手、区域术士。
- 每回合 3 点 AP；移动消耗 1 AP，最多移动两格。瑟弗林的普通攻击已从玩家操作界面移除，未选择技能时点击敌人不会发动攻击。
- 敌人意图在玩家回合开始时公开，并按固定顺序执行。
- 新版瑟弗林主动技能：
  - **裁决印记**：消耗 1 AP，对 1–4 格内且视线无遮挡的单个敌人造成 DEF×0.8 物理伤害，并施加唯一标记；再次施放替换旧标记。
  - **誓盾庇护**：消耗 1 AP，为瑟弗林及一名两格内友军施加护盾；当前正式遭遇没有友军，因此 UI 暂以瑟弗林自身为目标，友军目标由控制器独立测试覆盖。
  - **绝对守护**：消耗 2 AP 与 5 点终极能量；在瑟弗林周围两格内重定向合法单体攻击，并在敌方攻击意图结算后反击。
- **不屈誓约**为被动，不占技能按钮；敌方主动攻击命中瑟弗林时获得守誓，最多三层。
- **猎人通灵**保留朋友已有技能及余泡泡图标，不改变原有执行逻辑。
- 技能按钮、AP/能量显示、目标选择、范围提示、护盾/状态标识与键鼠操作。

## Oathkeeper v2 开发状态（仅开发分支）

- **新版正式设计规范**：[守誓者·瑟弗林新版技能与战斗机制规范 1.0](docs/design/OATHKEEPER_V2_DESIGN_SPEC_v1.0_zh-CN.md)。旧版技能文档已明确标记为历史版本。

新版技能目录与界面已切换，但仍处于待 Godot 引擎验证阶段：

- 新版技能目录 oathkeeper_v2_skill_catalog.gd 独立定义三项主动技能；不屈誓约以被动定义表示。
- 旧版技能目录、控制器 API、旧版状态处理与历史回归测试继续保留，避免破坏兼容性；旧技能不再出现在新版技能栏。
- 终极能量为每个单位独立的 0–5 点；每名存活友方角色在玩家回合开始时各自获得 1 点；成功主动行动（包括绝对守护本身）每名角色每回合最多额外获得 1 点。
- 绝对守护反击倍率为 DEF×0.5；新版裁决印记目标为 DEF×0.7。反击暴击尚未接入，因为全局暴击规则仍待统一。
- 护盾先吸收伤害；每个目标护盾上限为自身最大生命 15%，重施不降低较强的剩余护盾并刷新持续时间；护盾于施加后的第二个玩家回合结束时移除。
- 正式遭遇仍只创建瑟弗林与敌人。友军逻辑通过独立测试单位验证，没有擅自加入正式战场同伴。
- 当前没有生成新的测试包；Godot 4.7.2 导入、无头测试和 F5 实际运行均待验证。

## 桌面操作

| 操作 | 输入 |
|---|---|
| 移动 | 鼠标左键点击可到达的格子 |
| 裁决印记 | 点击技能按钮或按 1，再点击合法敌人 |
| 誓盾庇护 | 点击技能按钮或按 2，当前为瑟弗林自身施放 |
| 绝对守护 | 点击技能按钮或按 3；需 2 AP 与 5 点终极能量 |
| 猎人通灵 | 点击技能按钮或按 4，再点击合法敌人 |
| 取消目标选择 | Esc 或鼠标右键 |
| 结束回合 | 点击「结束回合」、Enter 或空格键 |

数字键 1–4 对应当前技能栏顺序。未选择技能时，点击敌人不会发动瑟弗林攻击；自身技能按下后立即施放，目标技能需要再点击战场上的敌人确认。敌方单位的普通攻击机制不受影响。

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
godot --headless --path . --script res://tests/test_hunter_summon.gd
godot --headless --path . --script res://tests/test_oathkeeper_v2_actor.gd
godot --headless --path . --script res://tests/test_oathkeeper_v2_controller.gd
godot --headless --path . --script res://tests/test_oathkeeper_v2_skill_catalog.gd
```

如果 Windows 没有把 Godot 加入 PATH，请使用 Godot 可执行文件的完整路径替换命令中的 `godot`。

原 Prototype 0.1 基线测试曾于 2026-11-25 在 Godot 4.7.2 中执行通过（九个套件共 408 条断言，详见 `docs/GODOT_ENGINE_VALIDATION_zh-CN.md`）。本开发分支新增的 Oathkeeper v2 actor、controller、skill catalog 测试及新版 battle view 集成测试尚未在 Godot 中运行，因此不能视为已通过；后续改动应重新执行全部命令，并以实际输出中的零失败为准。headless 测试不能替代 F5 主场景的鼠标、键盘和画面检查。

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
