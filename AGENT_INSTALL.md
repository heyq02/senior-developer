# senior-developer — Install Guide for AI Agents

You are an AI agent installing the **senior-developer** pack for the user.
Done = the **intended harness** can discover the `senior-developer` subagent (when
that harness supports agents) and the skills `fullstack-dev`, `frontend-dev`,
and `browser-skill`, and the user knows to start a **new agent session**.

**Default scope is the current project only.** Do **not** install into the user
home (`~/.cursor`, `~/.agents`, `~/.claude`, …) unless the user explicitly asks
for `--scope user`. Never use `sudo`.

## Success criteria

1. Skills exist under the harness’s skill paths (at least `.agents/skills/*/SKILL.md`).
2. Agent definition exists for harnesses that support it:
   - Cursor: `.cursor/agents/senior-developer.md`
   - Claude Code: `.claude/agents/senior-developer.md`
   - Codex: `.codex/agents/senior-developer.toml`
   - OpenCode: `.opencode/agents/senior-developer.md`
3. `AGENTS.md` mentions `senior-developer` (create or append; do not wipe other content).
4. You report install paths and ask for a **new** agent chat so discovery reloads.

Do not block on `bsk` / browser extension; that is optional for `browser-skill` runtime.

## 1. Confirm project root + harness

Work in the user's **current workspace / git repository root**. If unclear, ask once.

Install for the **intended** harness. Inspect IDs and paths:

```bash
bash "$PACK_DIR/install.sh" --list --json
```

Then install explicitly (works even when auto-detect is wrong):

```bash
bash "$PACK_DIR/install.sh" --scope project --target . --harness cursor --json
```

Replace `cursor` with: `claude` | `codex` | `opencode` | `agents` | `all` | `auto`.

- If the user names a harness, use that ID.
- If unknown, use `--harness auto` once; if detection returns `all`, that is fine for project install.
- `--yes` without `--harness` still installs `all` (project-scoped). It does **not** identify the current agent by itself.

## 2. Obtain the pack (pick one)

### Option A — Git clone (preferred)

```bash
PACK_DIR="$(mktemp -d)/senior-developer"
git clone --depth 1 https://github.com/heyq02/senior-developer.git "$PACK_DIR"
```

### Option B — GitHub Packages zip (ORAS)

```bash
WORKDIR="$(mktemp -d)"
cd "$WORKDIR"
oras pull ghcr.io/heyq02/senior-developer:latest
unzip -o senior-developer-*.zip
PACK_DIR="$WORKDIR/senior-developer"
```

Private packages may need `oras login`. Ask for a token only if auth fails.

### Option C — Already vendored

If `./install.sh` or `vendor/senior-developer/install.sh` exists, use that as `PACK_DIR`.

## 3. Install (project scope)

From the **project root**:

```bash
bash "$PACK_DIR/install.sh" --scope project --target . --harness <id> --json
```

Refresh:

```bash
bash "$PACK_DIR/install.sh" --scope project --target . --harness <id> --force --json
```

**Do not** use `--scope user` unless the user explicitly requests a global install.

## 4. Verify on disk

After install, confirm paths reported in the JSON `installed` array exist.
Minimum for every harness:

```bash
test -f .agents/skills/fullstack-dev/SKILL.md
test -f .agents/skills/frontend-dev/SKILL.md
test -f .agents/skills/browser-skill/SKILL.md
test -f AGENTS.md
```

Plus the harness-specific agent file from Step 1. If anything is missing, re-run
once with `--force`; then report the missing path and stop.

## 5. Tell the user how to use it

1. **Start a new agent session** (required for discovery).
2. Prefer the **senior-developer** subagent for full-stack delivery.
3. Skills: `fullstack-dev`, `frontend-dev`, `browser-skill`.
4. Optionally commit vendored paths for the team.

## 6. Optional: browser-skill runtime

If the user wants a live browser next:

```text
Set up browser-skill on this machine by following https://raw.githubusercontent.com/Tencent/BrowserSkill/main/AGENT_INSTALL.md
```

Do not run that unless they ask.

## 7. Report

Report success only after verification. Include:

- `scope=project` + absolute project root
- `harness=<id>`
- paths written
- reminder to open a new agent session
- that `bsk` was skipped (expected)

Never claim the subagent is active in the **current** chat if the harness only
reloads on a new session.
