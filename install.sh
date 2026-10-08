#!/usr/bin/env bash
# Install senior-developer agent pack into a project (default) or user home (explicit).
# BrowserSkill-style: --harness / --list / --json / --yes
set -euo pipefail

SCOPE="project"
TARGET=""
FORCE=0
WITH_AGENTS_MD=1
HARNESS="all"
LIST=0
JSON=0
YES=0

AGENT_NAME="senior-developer"
AGENT_DESC="Senior full-stack developer with 10+ years experience. Proficient in multiple languages and frameworks, delivers production-ready code with rigorous quality control."

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install this pack into discovery paths. Default is project-scoped (no global pollution).

Options:
  --scope project|user   Install target (default: project)
  --target <dir>         Project root to install into (default: $PWD)
  --harness <name>       Target harness (default: all). See --list
  --list                 List supported harness IDs and install paths
  --json                 Machine-readable output (with --list or install)
  --yes                  Non-interactive acknowledge (same as default all)
  --no-agents-md         Do not write/merge AGENTS.md
  --force                Overwrite existing skill/agent files
  -h, --help             Show help

Harness IDs:
  all        Portable skills + Cursor + Claude + Codex + OpenCode
  cursor     .agents/skills + .cursor/agents
  claude     .agents/skills + .claude/{agents,skills}
  codex      .agents/skills + .codex/agents (TOML)
  opencode   .agents/skills + .opencode/{agents,skills}
  agents     .agents/skills only
  auto       Best-effort detect current harness

Examples:
  ./install.sh --list --json
  ./install.sh --harness cursor --json
  ./install.sh --target /path/to/app --harness all
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="${2:?}"; shift 2 ;;
    --target) TARGET="${2:?}"; shift 2 ;;
    --harness) HARNESS="${2:?}"; shift 2 ;;
    --list) LIST=1; shift ;;
    --json) JSON=1; shift ;;
    --yes) YES=1; shift ;;
    --no-agents-md) WITH_AGENTS_MD=0; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "${ROOT}/.agents/skills" ]]; then
  echo "error: pack layout missing (.agents/skills). Run from the unpacked pack root." >&2
  exit 1
fi

case "${SCOPE}" in
  project)
    DEST="${TARGET:-$PWD}"
    DEST="$(cd "${DEST}" && pwd)"
    ;;
  user)
    DEST="${HOME}"
    ;;
  *)
    echo "error: --scope must be project or user" >&2
    exit 1
    ;;
esac

path_for() {
  local rel="$1"
  if [[ "${SCOPE}" == "user" ]]; then
    case "${rel}" in
      .agents/*|.cursor/*|.claude/*|.codex/*) echo "${HOME}/${rel#.}" ;;
      .opencode/*) echo "${HOME}/.config/opencode/${rel#.opencode/}" ;;
      AGENTS.md) echo "${HOME}/AGENTS.md" ;;
      *) echo "${HOME}/${rel}" ;;
    esac
  else
    echo "${DEST}/${rel}"
  fi
}

list_harnesses() {
  if [[ "${JSON}" -eq 1 ]]; then
    cat <<EOF
[
  {"id":"all","description":"All supported harnesses","skills":[".agents/skills",".claude/skills",".opencode/skills"],"agents":[".cursor/agents",".claude/agents",".codex/agents",".opencode/agents"]},
  {"id":"cursor","skills":[".agents/skills"],"agents":[".cursor/agents/${AGENT_NAME}.md"]},
  {"id":"claude","skills":[".agents/skills",".claude/skills"],"agents":[".claude/agents/${AGENT_NAME}.md"]},
  {"id":"codex","skills":[".agents/skills"],"agents":[".codex/agents/${AGENT_NAME}.toml"]},
  {"id":"opencode","skills":[".agents/skills",".opencode/skills"],"agents":[".opencode/agents/${AGENT_NAME}.md"]},
  {"id":"agents","skills":[".agents/skills"],"agents":[]},
  {"id":"auto","description":"Detect from environment, else all"}
]
EOF
  else
    cat <<EOF
Supported harnesses (scope=${SCOPE}, root=${DEST}):

  all       skills + cursor + claude + codex + opencode
  cursor    $(path_for .agents/skills)
            $(path_for .cursor/agents)/${AGENT_NAME}.md
  claude    $(path_for .agents/skills)
            $(path_for .claude/skills)
            $(path_for .claude/agents)/${AGENT_NAME}.md
  codex     $(path_for .agents/skills)
            $(path_for .codex/agents)/${AGENT_NAME}.toml
  opencode  $(path_for .agents/skills)
            $(path_for .opencode/skills)
            $(path_for .opencode/agents)/${AGENT_NAME}.md
  agents    $(path_for .agents/skills)
  auto      detect env, else all

Example:
  ./install.sh --harness cursor --json
EOF
  fi
}

if [[ "${LIST}" -eq 1 ]]; then
  list_harnesses
  exit 0
fi

# --yes is acknowledged for BrowserSkill-compatible non-interactive callers
: "${YES}"

if [[ "${SCOPE}" == "user" ]]; then
  echo "warning: --scope user writes into your home directory." >&2
fi

SKILLS_DIR="$(path_for .agents/skills)"
CURSOR_AGENTS="$(path_for .cursor/agents)"
CLAUDE_AGENTS="$(path_for .claude/agents)"
CLAUDE_SKILLS="$(path_for .claude/skills)"
CODEX_AGENTS="$(path_for .codex/agents)"
OPENCODE_AGENTS="$(path_for .opencode/agents)"
OPENCODE_SKILLS="$(path_for .opencode/skills)"
AGENTS_MD="$(path_for AGENTS.md)"
AVATARS_DIR="$(path_for .agents/assets/senior-developer)"

INSTALLED_JSON='[]'

record_install() {
  local path="$1"
  [[ "${JSON}" -eq 1 ]] || return 0
  INSTALLED_JSON="$(python3 -c 'import json,sys; a=json.loads(sys.argv[1]); a.append(sys.argv[2]); print(json.dumps(a))' "${INSTALLED_JSON}" "${path}")"
}

same_path() {
  local a b
  a="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  b="$(cd "$(dirname "$2")" 2>/dev/null && pwd)/$(basename "$2")" || return 1
  [[ "${a}" == "${b}" ]]
}

copy_tree() {
  local src="$1" dst="$2"
  if same_path "${src}" "${dst}"; then
    echo "skip (same path): ${dst}"
    return 0
  fi
  if [[ -e "${dst}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${dst}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${dst}")"
  rm -rf "${dst}"
  cp -R "${src}" "${dst}"
  find "${dst}" -name '.DS_Store' -delete 2>/dev/null || true
  echo "installed: ${dst}"
  record_install "${dst}"
}

copy_file() {
  local src="$1" dst="$2"
  if same_path "${src}" "${dst}"; then
    echo "skip (same path): ${dst}"
    return 0
  fi
  if [[ -e "${dst}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${dst}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
  echo "installed: ${dst}"
  record_install "${dst}"
}

agent_md_src() {
  if [[ -f "${ROOT}/.cursor/agents/${AGENT_NAME}.md" ]]; then
    echo "${ROOT}/.cursor/agents/${AGENT_NAME}.md"
  elif [[ -f "${ROOT}/.claude/agents/${AGENT_NAME}.md" ]]; then
    echo "${ROOT}/.claude/agents/${AGENT_NAME}.md"
  else
    echo "error: missing agent markdown for ${AGENT_NAME}" >&2
    exit 1
  fi
}

agent_body() {
  python3 - "$1" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
if text.startswith("---"):
    parts = text.split("---", 2)
    if len(parts) >= 3:
        print(parts[2].lstrip("\n"), end="")
        raise SystemExit
print(text, end="")
PY
}

install_skills_into() {
  local dest_skills="$1"
  mkdir -p "${dest_skills}"
  local skill name
  for skill in "${ROOT}/.agents/skills/"*/; do
    [[ -d "${skill}" ]] || continue
    name="$(basename "${skill}")"
    copy_tree "${skill%/}" "${dest_skills}/${name}"
  done
}

write_codex_toml() {
  local toml_path="$1" body="$2"
  if [[ -e "${toml_path}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${toml_path}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${toml_path}")"
  python3 - "${toml_path}" "${AGENT_NAME}" "${AGENT_DESC}" "${body}" <<'PY'
import sys
path, name, desc, body = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
body = body.replace("\\", "\\\\")
with open(path, "w", encoding="utf-8") as f:
    f.write(f'name = "{name}"\n')
    f.write(f'description = """{desc}"""\n')
    f.write(f'developer_instructions = """\n{body}\n"""\n')
print(f"installed: {path}")
PY
  record_install "${toml_path}"
}

write_opencode_agent() {
  local out="$1" body="$2"
  if [[ -e "${out}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${out}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${out}")"
  python3 - "${out}" "${AGENT_NAME}" "${AGENT_DESC}" "${body}" <<'PY'
import sys
path, name, desc, body = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path, "w", encoding="utf-8") as f:
    f.write("---\n")
    f.write(f"name: {name}\n")
    f.write(f"description: {desc}\n")
    f.write("mode: subagent\n")
    f.write("---\n\n")
    f.write(body)
    if not body.endswith("\n"):
        f.write("\n")
print(f"installed: {path}")
PY
  record_install "${out}"
}

do_cursor() {
  install_skills_into "${SKILLS_DIR}"
  copy_file "$(agent_md_src)" "${CURSOR_AGENTS}/${AGENT_NAME}.md"
}

do_claude() {
  install_skills_into "${SKILLS_DIR}"
  install_skills_into "${CLAUDE_SKILLS}"
  copy_file "$(agent_md_src)" "${CLAUDE_AGENTS}/${AGENT_NAME}.md"
}

do_codex() {
  install_skills_into "${SKILLS_DIR}"
  write_codex_toml "${CODEX_AGENTS}/${AGENT_NAME}.toml" "$(agent_body "$(agent_md_src)")"
}

do_opencode() {
  install_skills_into "${SKILLS_DIR}"
  install_skills_into "${OPENCODE_SKILLS}"
  write_opencode_agent "${OPENCODE_AGENTS}/${AGENT_NAME}.md" "$(agent_body "$(agent_md_src)")"
}

do_agents() {
  install_skills_into "${SKILLS_DIR}"
}

do_all() {
  local body
  body="$(agent_body "$(agent_md_src)")"
  install_skills_into "${SKILLS_DIR}"
  install_skills_into "${CLAUDE_SKILLS}"
  install_skills_into "${OPENCODE_SKILLS}"
  copy_file "$(agent_md_src)" "${CURSOR_AGENTS}/${AGENT_NAME}.md"
  copy_file "$(agent_md_src)" "${CLAUDE_AGENTS}/${AGENT_NAME}.md"
  write_codex_toml "${CODEX_AGENTS}/${AGENT_NAME}.toml" "${body}"
  write_opencode_agent "${OPENCODE_AGENTS}/${AGENT_NAME}.md" "${body}"
}

install_avatars() {
  [[ -d "${ROOT}/avatars" ]] || return 0
  mkdir -p "${AVATARS_DIR}"
  local f
  for f in "${ROOT}/avatars/"*; do
    [[ -e "${f}" ]] || continue
    copy_file "${f}" "${AVATARS_DIR}/$(basename "${f}")"
  done
}

install_agents_md() {
  [[ "${WITH_AGENTS_MD}" -eq 1 ]] || return 0
  local snippet
  snippet="$(cat <<'EOF'
# Senior Developer (小麦)

Prefer the **senior-developer** subagent for full-stack delivery tasks.
Use project skills when relevant: `fullstack-dev`, `frontend-dev`, `browser-skill`.

Skills: `.agents/skills/`. Agents: `.cursor/agents/` · `.claude/agents/` · `.codex/agents/` · `.opencode/agents/`.
EOF
)"

  if [[ ! -f "${AGENTS_MD}" ]]; then
    printf '%s\n' "${snippet}" > "${AGENTS_MD}"
    echo "installed: ${AGENTS_MD}"
    record_install "${AGENTS_MD}"
    return 0
  fi

  if grep -q 'senior-developer' "${AGENTS_MD}" 2>/dev/null; then
    echo "skip (already mentions senior-developer): ${AGENTS_MD}"
    return 0
  fi

  {
    echo ""
    echo "<!-- senior-developer pack -->"
    printf '%s\n' "${snippet}"
  } >> "${AGENTS_MD}"
  echo "appended: ${AGENTS_MD}"
  record_install "${AGENTS_MD}"
}

detect_harness() {
  if [[ -n "${CURSOR_AGENT:-}" || -n "${CURSOR_SESSION_ID:-}" || -d "${DEST}/.cursor" ]]; then
    # Prefer cursor when Cursor signals exist; .cursor alone is weak — fall through
    if [[ -n "${CURSOR_AGENT:-}" || -n "${CURSOR_SESSION_ID:-}" ]]; then
      echo cursor; return
    fi
  fi
  if [[ -n "${CLAUDECODE:-}" || -n "${CLAUDE_CODE:-}" ]]; then
    echo claude; return
  fi
  if [[ -n "${CODEX_HOME:-}" ]]; then
    echo codex; return
  fi
  if [[ -n "${OPENCODE_CONFIG:-}" || -n "${OPENCODE:-}" ]]; then
    echo opencode; return
  fi
  echo all
}

if [[ "${HARNESS}" == "auto" ]]; then
  HARNESS="$(detect_harness)"
  echo "detected harness: ${HARNESS}"
fi

echo "Installing senior-developer → scope=${SCOPE} dest=${DEST} harness=${HARNESS}"

case "${HARNESS}" in
  all) do_all ;;
  cursor) do_cursor ;;
  claude) do_claude ;;
  codex) do_codex ;;
  opencode) do_opencode ;;
  agents) do_agents ;;
  *)
    echo "error: unknown --harness '${HARNESS}'. Use --list" >&2
    exit 1
    ;;
esac

install_avatars
install_agents_md

if ! command -v bsk >/dev/null 2>&1; then
  echo ""
  echo "note: browser-skill needs the bsk CLI + browser extension when used."
  echo "      See https://github.com/Tencent/BrowserSkill"
fi

if [[ "${JSON}" -eq 1 ]]; then
  python3 -c 'import json,sys; print(json.dumps({"ok":True,"scope":sys.argv[1],"dest":sys.argv[2],"harness":sys.argv[3],"installed":json.loads(sys.argv[4])}, indent=2))' \
    "${SCOPE}" "${DEST}" "${HARNESS}" "${INSTALLED_JSON}"
else
  echo ""
  echo "Done. Restart / start a new agent session so discovery picks up the files."
  if [[ "${SCOPE}" == "project" ]]; then
    echo "Tip: commit installed paths so the team gets them with the repo."
  fi
fi
