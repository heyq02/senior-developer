# 小麦 - 高级开发工程师

10年以上全栈经验，精通多种语言和框架，是团队的技术中坚。

按 **项目内发现路径** 分发：嵌进业务仓库即可用，**默认不装全局**。支持多 harness（Cursor / Claude Code / Codex / OpenCode）。

## Quick Start — 让 Agent 帮你装

在**业务项目**里把下面这段发给你的 AI Agent：

```
Set up senior-developer in this project by following https://raw.githubusercontent.com/heyq02/senior-developer/main/AGENT_INSTALL.md
```

Agent 会按 [AGENT_INSTALL.md](AGENT_INSTALL.md) 为当前 harness 写入项目目录（不污染家目录）。装完后**新开一轮 Agent 会话**即可发现。

中文等价 Prompt：

```
按 https://raw.githubusercontent.com/heyq02/senior-developer/main/AGENT_INSTALL.md 在当前项目安装 senior-developer（仅项目范围，不要装到全局）
```

## Harness

```bash
./install.sh --list
./install.sh --harness cursor      # Cursor
./install.sh --harness claude      # Claude Code
./install.sh --harness codex       # Codex（生成 .toml agent）
./install.sh --harness opencode    # OpenCode
./install.sh --harness agents      # 仅 .agents/skills
./install.sh --harness all         # 默认：全部写入
./install.sh --harness auto        # 尝试从环境探测
```

| Harness | Skills | Agent |
| --- | --- | --- |
| `cursor` | `.agents/skills/` | `.cursor/agents/senior-developer.md` |
| `claude` | `.agents/skills/` + `.claude/skills/` | `.claude/agents/senior-developer.md` |
| `codex` | `.agents/skills/` | `.codex/agents/senior-developer.toml` |
| `opencode` | `.agents/skills/` + `.opencode/skills/` | `.opencode/agents/senior-developer.md` |
| `agents` | `.agents/skills/` | — |
| `all` | 以上技能路径 | 以上 agent 全部 |

## 布局

| 路径 | 说明 |
| --- | --- |
| `.agents/skills/*` | 可移植 Skills |
| `.cursor/agents/` | Cursor subagent |
| `.claude/agents/` · `.claude/skills/` | Claude Code |
| `.codex/agents/` | Codex TOML agent |
| `.opencode/agents/` · `.opencode/skills/` | OpenCode |
| `AGENTS.md` | 跨工具薄指令 |
| `AGENT_INSTALL.md` | 给 AI Agent 的安装指南 |
| `install.sh` | `--harness` / `--list` / `--json` |

## 其它用法

打开本仓库即可用。手动：

```bash
git clone --depth 1 https://github.com/heyq02/senior-developer.git /tmp/senior-developer
bash /tmp/senior-developer/install.sh --target /path/to/app --harness all
```

`browser-skill` 真连浏览器另发：

```
Set up browser-skill on this machine by following https://raw.githubusercontent.com/Tencent/BrowserSkill/main/AGENT_INSTALL.md
```

## 发布

```bash
git tag v1.0.0 && git push origin v1.0.0
```
