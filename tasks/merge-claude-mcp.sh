#!/usr/bin/env bash
# mise `bootstrap` task. Renders the MCP-servers intent — injecting the Gemini
# API key from gopass and the per-machine image output dir at apply time, so
# the secret never lands in git — then merges `.mcpServers` into ~/.claude.json.
#
# Replaces the old chezmoi run_onchange_after_50-merge-claude-mcp.sh. Idempotent:
# re-running only rewrites ~/.claude.json when the merged result actually changes.
set -euo pipefail

REPO="${MISE_PROJECT_ROOT:-$HOME/.dotfiles}"
SKELETON="$REPO/.claude/mcp-servers.json"
INTENT="$HOME/.claude/mcp-servers.json"
TARGET="$HOME/.claude.json"

command -v jq >/dev/null     || { echo "merge-claude-mcp: jq not installed, skipping" >&2; exit 0; }
command -v gopass >/dev/null || { echo "merge-claude-mcp: gopass not installed, skipping" >&2; exit 0; }
[ -f "$SKELETON" ]           || { echo "merge-claude-mcp: skeleton missing ($SKELETON), skipping" >&2; exit 0; }

key="$(gopass show -o mcp/gemini-api-key)"

# Fill the two placeholder fields in the skeleton -> rendered intent file.
mkdir -p "$(dirname "$INTENT")"
jq --arg k "$key" --arg home "$HOME" '
  .mcpServers["mcp-image"].env.GEMINI_API_KEY = $k
  | .mcpServers["mcp-image"].env.IMAGE_OUTPUT_DIR = ($home + "/Workspace/mcp-image")
' "$SKELETON" > "$INTENT"

if [ ! -f "$TARGET" ]; then
  jq '{mcpServers: .mcpServers}' "$INTENT" > "$TARGET"
  echo "merge-claude-mcp: created $TARGET"
  exit 0
fi

tmp="$(mktemp)"
jq --slurpfile intent "$INTENT" '.mcpServers = $intent[0].mcpServers' "$TARGET" > "$tmp"
if ! cmp -s "$TARGET" "$tmp"; then
  mv "$tmp" "$TARGET"
  echo "merge-claude-mcp: updated .mcpServers in $TARGET"
else
  rm -f "$tmp"
fi
