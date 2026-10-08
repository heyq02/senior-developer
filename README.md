# 吴八哥 - 高级开发工程师

10年以上全栈经验，精通多种语言和框架，是团队的技术中坚。

按 **项目内发现路径** 分发：嵌进业务仓库即可用，**默认不装全局**。

## Quick Start — 让 Agent 帮你装

在**业务项目**里把下面这段发给你的 AI Agent：

```
Set up senior-developer in this project by following https://raw.githubusercontent.com/heyq02/senior-developer/main/AGENT_INSTALL.md
```

Agent 会按 [AGENT_INSTALL.md](AGENT_INSTALL.md) 把 subagent + skills **写入当前项目**（`.agents/`、`.cursor/agents/`、`.claude/agents/`），不污染家目录。装完后**新开一轮 Agent 会话**即可发现。

中文等价 Prompt：

```
按 https://raw.githubusercontent.com/heyq02/senior-developer/main/AGENT_INSTALL.md 在当前项目安装 senior-developer（仅项目范围，不要装到全局）
```

## 布局

| 路径 | 说明 |
| --- | --- |
| `.cursor/agents/senior-developer.md` | Cursor subagent |
| `.claude/agents/senior-developer.md` | Claude Code subagent |
| `.agents/skills/*` | `fullstack-dev` / `frontend-dev` / `browser-skill` |
| `AGENTS.md` | 跨工具薄指令 |
| `AGENT_INSTALL.md` | 给 AI Agent 执行的安装指南 |
| `install.sh` | Agent / 手动共用的安装脚本 |
| `avatars/` | 头像资源 |

## 其它用法

### 打开本仓库

本仓库已是发现路径布局，直接新开 Agent 会话即可。

### 手动安装（可选）

```bash
git clone --depth 1 https://github.com/heyq02/senior-developer.git /tmp/senior-developer
bash /tmp/senior-developer/install.sh --scope project --target /path/to/your-app
```

或从 GitHub Packages：

```bash
oras pull ghcr.io/heyq02/senior-developer:latest
unzip senior-developer-*.zip
./senior-developer/install.sh --target /path/to/your-app
```

显式全局（不推荐）：`./install.sh --scope user`

### browser-skill 运行时

本包装入的是 skill 文件。若要真连浏览器，另发：

```
Set up browser-skill on this machine by following https://raw.githubusercontent.com/Tencent/BrowserSkill/main/AGENT_INSTALL.md
```

## 发布

```bash
git tag v1.0.0
git push origin v1.0.0
```

Actions：**Publish Zip to GitHub Packages**（GHCR + Release）。
