# senior-developer — Install Guide for AI Agents

You are an AI agent installing the **senior-developer** pack for the user.
Done = this project can discover the `senior-developer` subagent and the skills
`fullstack-dev`, `frontend-dev`, and `browser-skill`, and the user knows to
start a **new agent session** so discovery reloads.

**Default scope is the current project only.** Do **not** install into the user
home (`~/.cursor`, `~/.agents`, `~/.claude`) unless the user explicitly asks for
`--scope user`. Never use `sudo`.

## Success criteria

1. Project contains:
   - `.agents/skills/{fullstack-dev,frontend-dev,browser-skill}/SKILL.md`
   - `.cursor/agents/senior-developer.md`
   - `.claude/agents/senior-developer.md`
2. `AGENTS.md` exists at the project root and mentions `senior-developer`
   (create or append; do not wipe unrelated content).
3. You report what was installed and ask the user to open a **new** agent chat
   (or reload) so the harness picks up agents/skills.

Doctor-style checks for `browser-skill` / `bsk` are optional and separate; this
pack only vendors the skill files. Do not block pack install on `bsk`.

## 1. Confirm the project root

Work in the user's **current workspace / git repository root** (the app they
want the agent in). If unclear, ask once. All paths below are relative to that
root.

## 2. Obtain the pack (pick one)

Prefer a fresh copy under a temporary or vendor path, then run the installer.

### Option A — Git clone (preferred when git + network work)

```bash
PACK_DIR="$(mktemp -d)/senior-developer"
git clone --depth 1 https://github.com/heyq02/senior-developer.git "$PACK_DIR"
```

### Option B — GitHub Packages zip (ORAS)

If `oras` is available and the user wants the published package:

```bash
WORKDIR="$(mktemp -d)"
cd "$WORKDIR"
oras pull ghcr.io/heyq02/senior-developer:latest
unzip -o senior-developer-*.zip
PACK_DIR="$WORKDIR/senior-developer"
```

Private packages may need:

```bash
echo "$GITHUB_TOKEN" | oras login ghcr.io -u USERNAME --password-stdin
```

Ask the user for a token only if pull fails with auth errors; do not invent credentials.

### Option C — Already vendored in-tree

If `./install.sh` exists in this repo (or `vendor/senior-developer/install.sh`),
use that path as `PACK_DIR` and skip download.

## 3. Install into the project (not global)

From the **project root**:

```bash
bash "$PACK_DIR/install.sh" --scope project --target .
```

If files already exist and the user wants a refresh:

```bash
bash "$PACK_DIR/install.sh" --scope project --target . --force
```

Harness narrowing (only if the user asks):

```bash
bash "$PACK_DIR/install.sh" --scope project --target . --harness cursor
# or: claude | agents | all
```

**Do not** run `--scope user` unless the user explicitly requests a global install.

## 4. Verify on disk

Confirm these files exist under the project root:

```bash
test -f .agents/skills/fullstack-dev/SKILL.md
test -f .agents/skills/frontend-dev/SKILL.md
test -f .agents/skills/browser-skill/SKILL.md
test -f .cursor/agents/senior-developer.md
test -f .claude/agents/senior-developer.md
test -f AGENTS.md
```

List them for the user. If any are missing, re-run the installer with `--force`
once; if still failing, report the exact missing path and stop.

## 5. Tell the user how to use it

After install:

1. **Start a new agent session** (required for discovery).
2. Prefer the **senior-developer** subagent for full-stack delivery work.
3. Skills trigger by task: `fullstack-dev`, `frontend-dev`, `browser-skill`.
4. Optionally commit the vendored paths so teammates get them:

   ```text
   .agents/
   .cursor/agents/
   .claude/agents/
   AGENTS.md
   ```

## 6. Optional: browser-skill runtime

`browser-skill` needs the `bsk` CLI and browser extension on the machine that
runs the browser. That is **not** part of this pack install. If the user wants
browser automation next, point them to:

```text
Set up browser-skill on this machine by following https://raw.githubusercontent.com/Tencent/BrowserSkill/main/AGENT_INSTALL.md
```

Do not run that setup unless they ask.

## 7. Report

Report success only after Step 4 checks pass. Include:

- Install scope: `project` + absolute project root
- Paths written
- Reminder to open a new agent session
- Whether `bsk` was skipped (expected)

If blocked, say which step failed and what remains unverified. Never claim the
subagent is active in the **current** chat if the harness only reloads on a new session.
