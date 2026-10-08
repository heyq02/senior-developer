# 吴八哥 - 高级开发工程师

10年以上全栈经验，精通多种语言和框架，是团队的技术中坚。

本仓库按 **项目内发现路径** 组织：打开本仓库即可用；嵌进业务仓库则只在该项目生效，**默认不装全局**。

## 布局

| 路径 | 说明 |
| --- | --- |
| `.cursor/agents/senior-developer.md` | Cursor subagent |
| `.claude/agents/senior-developer.md` | Claude Code subagent |
| `.agents/skills/fullstack-dev` | 全栈开发 Skill |
| `.agents/skills/frontend-dev` | 前端 / AI 资产生成 Skill |
| `.agents/skills/browser-skill` | 浏览器自动化（[Tencent/BrowserSkill](https://github.com/Tencent/BrowserSkill)） |
| `AGENTS.md` | 跨工具薄指令 |
| `avatars/` | 头像资源 |
| `install.sh` | 安装到目标项目（默认 project scope） |

## 用法

### 1. 直接打开本仓库

Cursor / Claude Code 会自动发现 `.cursor/agents`、`.claude/agents`、`.agents/skills`。新开一轮 Agent 会话即可。

### 2. 嵌进业务项目（推荐）

在业务仓库根目录：

```bash
oras pull ghcr.io/heyq02/senior-developer:latest
unzip senior-developer-*.zip
./senior-developer/install.sh --target .
# 或：cd /path/to/app && /path/to/senior-developer/install.sh
```

默认 `--scope project`，写入：

- `.agents/skills/*`
- `.cursor/agents/senior-developer.md`
- `.claude/agents/senior-developer.md`
- `AGENTS.md`（没有则创建，已有则追加片段）

把这些路径提交进 git，团队 clone 即有。

显式全局（不推荐）：

```bash
./install.sh --scope user
```

### 3. Git submodule

```bash
git submodule add https://github.com/heyq02/senior-developer.git vendor/senior-developer
./vendor/senior-developer/install.sh --target .
```

## 从 GitHub Packages 拉取

```bash
oras pull ghcr.io/heyq02/senior-developer:latest
unzip senior-developer-*.zip
./senior-developer/install.sh --target /path/to/your-app
```

私有包先登录：`echo "$GITHUB_TOKEN" | oras login ghcr.io -u USERNAME --password-stdin`

`browser-skill` 仍需本机 [bsk CLI + 扩展](https://github.com/Tencent/BrowserSkill)。

## 发布

```bash
git tag v1.0.0
git push origin v1.0.0
```

打 `v*` 标签或手动跑 Actions：**Publish Zip to GitHub Packages**（GHCR + Release）。
