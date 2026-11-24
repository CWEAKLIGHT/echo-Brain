# ECHO

一款面向 Android 的 2D 回合制战术 roguelite，使用 Godot 4.x 和 GDScript 开发。

## 项目状态

- **阶段**：项目搭建（Phase 0）
- **原型目标**：Prototype 0.1
- **引擎**：Godot 4.x
- **主要平台**：Android（横屏优先）
- **模式**：单机、离线

本仓库是 ECHO 的独立仓库，与「时光」项目分开维护。

## Prototype 0.1 范围

- 一名可玩角色：誓守者 Sevrin
- 一名临时猎人同伴
- 三种普通敌人
- 一张完整战场
- 五到六个技能
- 玩家回合 3 点行动点（AP）
- 敌人预告与战术干扰
- 胜利与失败结算
- 触屏优先的 Android 操作

原型范围是刻意冻结的。局内成长、契约、收集、经济系统，以及完整的 roguelite 章节循环，都不在 Prototype 0.1 内。

## 设计约束

- 俯视方形网格战场，不支持斜向移动。
- 一次移动消耗 1 AP，最多沿正交方向移动两格。
- 玩家每回合基础 AP 为 3。
- 动作即时结算；只有在确认目标之前才能取消。
- 敌人预告在玩家回合开始时生成，并按清晰可见的固定顺序执行。
- 普通敌人的预告必须与实际执行完全一致。
- 不提供局内存档、检查点或对局恢复。只有局外进度可以持久化。

规则尚未确认时，实现不得把提案悄悄变成最终规则。未决事项应先记录在设计文档中，再进入实现。

## 仓库结构

```
.
├── docs/                 # 项目与技术文档
│   ├── ARCHITECTURE.md                  # 架构说明
│   ├── DECISIONS_AND_OPEN_QUESTIONS.md  # 已定决策与未决问题
│   └── PROJECT_STATUS.md                # 项目进度
├── scenes/
│   └── main/             # 主入口场景
├── scripts/              # GDScript 源码
│   ├── core/
│   ├── battle/
│   ├── actors/
│   ├── data/
│   └── ui/
└── project.godot
```

## 引擎与工程设置

- 渲染后端：GL Compatibility，桌面与移动端一致，优先保证 Android 兼容性。
- 视口尺寸：1280 × 720。
- 主场景：`res://scenes/main/main.tscn`。
- 项目配置：`project.godot`。

## 快速开始

1. 安装兼容的 Godot 4.x 版本。
2. 克隆本仓库。
3. 在 Godot 中导入仓库目录。
4. 用主场景运行项目。

当前提交只建立了工程骨架，玩法系统尚未实现。

## 相关文档

- [ARCHITECTURE.md](docs/ARCHITECTURE.md)：架构与模块划分
- [DECISIONS_AND_OPEN_QUESTIONS.md](docs/DECISIONS_AND_OPEN_QUESTIONS.md)：已定决策与未决问题
- [PROJECT_STATUS.md](docs/PROJECT_STATUS.md)：项目进度

## 已知限制

- 没有局内存档、检查点和恢复机制，这是设计上的刻意选择。
- 玩法系统尚未实现，当前为工程骨架。
