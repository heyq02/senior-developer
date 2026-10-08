#!/usr/bin/env bash
# Install senior-developer agent pack into a project (default) or user home (explicit).
set -euo pipefail

SCOPE="project"
TARGET=""
FORCE=0
WITH_AGENTS_MD=1
HARNESS="all" # all | cursor | claude | agents

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install this pack into discovery paths. Default is project-scoped (no global pollution).

Options:
  --scope project|user   Install target (default: project)
  --target <dir>         Project root to install into (default: $PWD)
  --harness <name>       all|cursor|claude|agents (default: all)
  --no-agents-md         Do not write/merge AGENTS.md
  --force                Overwrite existing skill/agent files
  -h, --help             Show help

Examples:
  # In a business repo: vendor into this project only
  ./install.sh

  # Install into another project
  ./install.sh --target /path/to/my-app

  # Explicit global (opt-in only)
  ./install.sh --scope user
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="${2:?}"
      shift 2
      ;;
    --target)
      TARGET="${2:?}"
      shift 2
      ;;
    --harness)
      HARNESS="${2:?}"
      shift 2
      ;;
    --no-agents-md)
      WITH_AGENTS_MD=0
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
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
    SKILLS_DIR="${DEST}/.agents/skills"
    CURSOR_AGENTS="${DEST}/.cursor/agents"
    CLAUDE_AGENTS="${DEST}/.claude/agents"
    AGENTS_MD="${DEST}/AGENTS.md"
    AVATARS_DIR="${DEST}/.agents/assets/senior-developer"
    ;;
  user)
    echo "warning: --scope user writes into your home directory." >&2
    DEST="${HOME}"
    SKILLS_DIR="${HOME}/.agents/skills"
    CURSOR_AGENTS="${HOME}/.cursor/agents"
    CLAUDE_AGENTS="${HOME}/.claude/agents"
    AGENTS_MD="${HOME}/AGENTS.md"
    AVATARS_DIR="${HOME}/.agents/assets/senior-developer"
    ;;
  *)
    echo "error: --scope must be project or user" >&2
    exit 1
    ;;
esac

copy_tree() {
  local src="$1"
  local dst="$2"
  if [[ -e "${dst}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${dst}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${dst}")"
  rm -rf "${dst}"
  cp -R "${src}" "${dst}"
  find "${dst}" -name '.DS_Store' -delete 2>/dev/null || true
  echo "installed: ${dst}"
}

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ -e "${dst}" && "${FORCE}" -ne 1 ]]; then
    echo "skip (exists): ${dst}  (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
  echo "installed: ${dst}"
}

install_skills() {
  mkdir -p "${SKILLS_DIR}"
  local skill
  for skill in "${ROOT}/.agents/skills/"*/; do
    [[ -d "${skill}" ]] || continue
    local name
    name="$(basename "${skill}")"
    copy_tree "${skill%/}" "${SKILLS_DIR}/${name}"
  done
}

install_cursor_agent() {
  mkdir -p "${CURSOR_AGENTS}"
  copy_file "${ROOT}/.cursor/agents/senior-developer.md" \
    "${CURSOR_AGENTS}/senior-developer.md"
}

install_claude_agent() {
  mkdir -p "${CLAUDE_AGENTS}"
  local src="${ROOT}/.claude/agents/senior-developer.md"
  if [[ ! -f "${src}" ]]; then
    src="${ROOT}/.cursor/agents/senior-developer.md"
  fi
  copy_file "${src}" "${CLAUDE_AGENTS}/senior-developer.md"
}

install_avatars() {
  if [[ -d "${ROOT}/avatars" ]]; then
    mkdir -p "${AVATARS_DIR}"
    local f
    for f in "${ROOT}/avatars/"*; do
      [[ -e "${f}" ]] || continue
      copy_file "${f}" "${AVATARS_DIR}/$(basename "${f}")"
    done
  fi
}

install_agents_md() {
  [[ "${WITH_AGENTS_MD}" -eq 1 ]] || return 0
  local snippet
  snippet="$(cat <<'EOF'
# Senior Developer

Prefer the **senior-developer** subagent for full-stack delivery tasks.
Use project skills when relevant: `fullstack-dev`, `frontend-dev`, `browser-skill`.

Skills live under `.agents/skills/`. Agent definitions: `.cursor/agents/` (Cursor) and `.claude/agents/` (Claude Code).
EOF
)"

  if [[ ! -f "${AGENTS_MD}" ]]; then
    printf '%s\n' "${snippet}" > "${AGENTS_MD}"
    echo "installed: ${AGENTS_MD}"
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
}

echo "Installing senior-developer → scope=${SCOPE} dest=${DEST} harness=${HARNESS}"

case "${HARNESS}" in
  all)
    install_skills
    install_cursor_agent
    install_claude_agent
    ;;
  cursor)
    install_skills
    install_cursor_agent
    ;;
  claude)
    install_skills
    # Claude also reads .claude/skills; mirror for discovery
    _claude_skills_dest="${DEST}/.claude/skills"
    [[ "${SCOPE}" == "user" ]] && _claude_skills_dest="${HOME}/.claude/skills"
    mkdir -p "${_claude_skills_dest}"
    for skill in "${ROOT}/.agents/skills/"*/; do
      [[ -d "${skill}" ]] || continue
      name="$(basename "${skill}")"
      copy_tree "${skill%/}" "${_claude_skills_dest}/${name}"
    done
    install_claude_agent
    ;;
  agents)
    install_skills
    ;;
  *)
    echo "error: --harness must be all|cursor|claude|agents" >&2
    exit 1
    ;;
esac

install_avatars
install_agents_md

# browser-skill needs bsk CLI + extension; do not pretend it is fully automatic
if [[ -d "${SKILLS_DIR}/browser-skill" ]] || [[ -d "${ROOT}/.agents/skills/browser-skill" ]]; then
  if ! command -v bsk >/dev/null 2>&1; then
    echo ""
    echo "note: browser-skill needs the bsk CLI + browser extension."
    echo "      See https://github.com/Tencent/BrowserSkill"
  fi
fi

echo ""
echo "Done. Restart / start a new agent session so discovery picks up the files."
if [[ "${SCOPE}" == "project" ]]; then
  echo "Tip: commit .agents/ .cursor/agents/ .claude/agents/ (and AGENTS.md) so the team gets them with the repo."
fi
