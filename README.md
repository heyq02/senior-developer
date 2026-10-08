# 吴八哥 - 高级开发工程师

10年以上全栈经验，精通多种语言和框架，是团队的技术中坚。

## 内容

| 路径 | 说明 |
| --- | --- |
| `agents/senior-developer.md` | Agent 角色定义 |
| `skills/fullstack-dev` | 全栈开发 Skill |
| `skills/frontend-dev` | 前端 / AI 资产生成 Skill |
| `skills/browser-skill` | 浏览器自动化（[Tencent/BrowserSkill](https://github.com/Tencent/BrowserSkill)） |
| `avatars/` | 头像资源 |

## 从 GitHub Packages 安装

发布产物是 zip，托管在 **GitHub Packages（GHCR）**，用 [ORAS](https://oras.land/) 拉取。

```bash
# 安装 ORAS：https://oras.land/docs/installation
oras pull ghcr.io/heyq02/senior-developer:latest
unzip senior-developer-*.zip
```

指定版本：

```bash
oras pull ghcr.io/heyq02/senior-developer:1.0.0
```

首次拉取私有包时先登录：

```bash
echo "$GITHUB_TOKEN" | oras login ghcr.io -u USERNAME --password-stdin
```

## 发布

打 `v*` 标签推送，或在 Actions 里手动运行 **Publish Zip to GitHub Packages**：

```bash
git tag v1.0.0
git push origin v1.0.0
```

包地址：`ghcr.io/heyq02/senior-developer`（tag = 版本号 / `latest`）。
