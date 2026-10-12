#!/usr/bin/env bash
# Offline self-check of the dev-pattern repository: structure, the plugin manifest, and live
# synthetic tests of every hook and bin/ tool against throwaway git repositories.
#
#   bash scripts/check.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/plugins/dev-pattern"
cd "$ROOT"

FAILED=0
if [ -t 1 ]; then G=$'\033[32m' R=$'\033[31m' B=$'\033[1m' D=$'\033[2m' N=$'\033[0m'; else G="" R="" B="" D="" N=""; fi
section() { printf '\n%s%s%s\n' "$B" "$1" "$N"; }
ok()      { printf '  %s✓%s %s\n' "$G" "$N" "$1"; }
bad()     { printf '  %s✗ %s%s\n' "$R" "$1" "$N"; FAILED=$((FAILED + 1)); }
check()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 — expected '$3', got '$2'"; fi; }

for dep in git jq awk sed; do
  if ! command -v "$dep" >/dev/null 2>&1; then echo "check.sh needs $dep" >&2; exit 1; fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

new_repo() {  # new_repo NAME -> prints path of a fresh repo with one commit
  local d="$TMP/$1"
  mkdir -p "$d/src" && git -C "$d" init -q && echo a > "$d/src/a.ts"
  git -C "$d" add -A && git -C "$d" commit -qm init
  printf '%s' "$d"
}

# ------------------------------------------------------------------------------------------
section "1. Structure"
for f in .claude-plugin/marketplace.json plugins/dev-pattern/.claude-plugin/plugin.json \
         plugins/dev-pattern/hooks/hooks.json plugins/dev-pattern/rules.md \
         plugins/dev-pattern/agents/researcher.md plugins/dev-pattern/agents/worker.md \
         plugins/dev-pattern/output-styles/tutor.md plugins/dev-pattern/output-styles/tutor-practice.md \
         plugins/dev-pattern/skills/knowledge/SKILL.md plugins/dev-pattern/skills/setup/SKILL.md \
         plugins/dev-pattern/skills/uninstall/SKILL.md \
         plugins/dev-pattern/templates/kb-index.md plugins/dev-pattern/templates/kb-module.md; do
  if [ -f "$f" ]; then ok "$f"; else bad "$f is missing"; fi
done
for f in .claude-plugin/marketplace.json plugins/dev-pattern/.claude-plugin/plugin.json plugins/dev-pattern/hooks/hooks.json; do
  if jq empty "$f" 2>/dev/null; then ok "$f is valid JSON"; else bad "$f is not valid JSON"; fi
done
for a in "$P"/agents/*.md; do
  check "$(basename "$a") runs on sonnet" "$(awk -F': *' '/^model:/{print $2; exit}' "$a")" "sonnet"
done
for s in "$P"/scripts/*.sh "$P"/bin/* scripts/check.sh; do
  if bash -n "$s" 2>/dev/null; then ok "$(basename "$s") parses"; else bad "$s has a syntax error"; fi
done
for s in "$P"/scripts/guard.sh "$P"/scripts/session-start.sh "$P"/scripts/stop-docs.sh "$P"/bin/*; do
  if [ -x "$s" ]; then ok "$(basename "$s") is executable"; else bad "$s is not executable"; fi
done
RULES_LEN="$(wc -c < "$P/rules.md")"
if [ "$RULES_LEN" -lt 4000 ]; then ok "rules.md is short ($RULES_LEN bytes)"; else bad "rules.md is $RULES_LEN bytes; keep it under 4000"; fi

# ------------------------------------------------------------------------------------------
section "2. Plugin manifest"
if command -v claude >/dev/null 2>&1; then
  for target in plugins/dev-pattern .; do
    if out="$(claude plugin validate "$target" 2>&1)" && grep -q 'Validation passed' <<<"$out"; then
      ok "claude plugin validate $target"
    else
      bad "claude plugin validate $target"; printf '%s\n' "$out" | sed 's/^/      /'
    fi
  done
else
  printf '  %sclaude not installed — skipped%s\n' "$D" "$N"
fi

# ------------------------------------------------------------------------------------------
section "3. guard.sh"
G_REPO="$(new_repo guard)"
guard() {  # guard AGENT TOOL TOOL_INPUT_JSON -> allow | deny | pass
  local out rc=0
  out="$(jq -cn --arg a "$1" --arg t "$2" --arg c "$G_REPO" --argjson ti "$3" \
          '{agent_type: $a, tool_name: $t, cwd: $c, tool_input: $ti}' | "$P/scripts/guard.sh" 2>/dev/null)" || rc=$?
  if [ "$rc" = 2 ]; then echo deny; elif grep -q '"allow"' <<<"$out"; then echo allow; else echo pass; fi
}
f() { jq -cn --arg p "$1" '{file_path: $p}'; }
c() { jq -cn --arg c "$1" '{command: $c}'; }
RS=dev-pattern:researcher WK=dev-pattern:worker
check "researcher writes the knowledge base"        "$(guard $RS Write "$(f "$G_REPO/docs/dp/knowledge/x.md")")" allow
check "researcher writes code"                      "$(guard $RS Write "$(f "$G_REPO/src/a.ts")")" deny
check "researcher escapes with .."                  "$(guard $RS Write "$(f "$G_REPO/docs/dp/knowledge/../../x.md")")" deny
check "researcher writes outside the repo"          "$(guard $RS Write "$(f /etc/passwd)")" deny
check "researcher runs git log"                     "$(guard $RS Bash "$(c 'git log --oneline -5')")" allow
check "researcher runs dp-kb-stale"                 "$(guard $RS Bash "$(c dp-kb-stale)")" allow
check "researcher redirects output"                 "$(guard $RS Bash "$(c 'git log > out')")" pass
check "researcher runs other commands"              "$(guard $RS Bash "$(c 'npm test')")" pass
check "researcher commits"                          "$(guard $RS Bash "$(c 'ls && git commit -m x')")" deny
check "worker edits code"                           "$(guard $WK Edit "$(f "$G_REPO/src/a.ts")")" pass
check "worker edits docs/"                          "$(guard $WK Edit "$(f "$G_REPO/docs/readme.md")")" deny
check "worker edits a manifest"                     "$(guard $WK Edit "$(f "$G_REPO/package.json")")" deny
check "worker edits a nested CLAUDE.md"             "$(guard $WK Edit "$(f "$G_REPO/sub/CLAUDE.md")")" deny
check "worker edits outside the repo"               "$(guard $WK Edit "$(f /tmp/elsewhere.ts)")" deny
check "worker pushes"                               "$(guard $WK Bash "$(c 'npm test && git push')")" deny
check "worker runs tests"                           "$(guard $WK Bash "$(c 'go test ./...')")" pass
check "main session is never touched"               "$(guard '' Write "$(f "$G_REPO/docs/x.md")")" pass
check "other subagents are never touched"           "$(guard Explore Bash "$(c 'git commit -m x')")" pass
rc=0; echo 'not json' | "$P/scripts/guard.sh" >/dev/null 2>&1 || rc=$?
check "garbage input fails open"                    "$rc" 0

# ------------------------------------------------------------------------------------------
section "4. dp-kb-stale"
K="$(new_repo kb)"
mkdir -p "$K/docs/dp/knowledge" && echo b > "$K/src/b.ts"
git -C "$K" add -A && git -C "$K" commit -qm b
SHA="$(git -C "$K" rev-parse --short HEAD)"
printf -- '---\ntopic: a\ncovers:\n  - src/a.ts\nverified_at: %s\n---\n' "$SHA" > "$K/docs/dp/knowledge/a.md"
printf -- '---\ntopic: b\ncovers: [src/b.ts, src/gone.ts]\nverified_at: %s\n---\n' "$SHA" > "$K/docs/dp/knowledge/b.md"
printf -- '---\ntopic: x\ncovers: [src]\nverified_at: deadbeef\n---\n' > "$K/docs/dp/knowledge/x.md"
cp "$P/templates/kb-index.md" "$K/docs/dp/knowledge/INDEX.md"
stale() { (cd "$K" && "$P/bin/dp-kb-stale" | grep -E '^(STALE|UNVERIFIED)' | awk '{print $1, $2}' | sort | tr '\n' ' '); }
check "fresh, missing-file and unverified modules"  "$(stale)" "STALE b.md UNVERIFIED x.md "
echo z >> "$K/src/a.ts"
check "uncommitted change makes a module stale"     "$(stale)" "STALE a.md STALE b.md UNVERIFIED x.md "
git -C "$K" checkout -q src/a.ts && echo n > "$K/src/a2.ts"
sed -i 's|  - src/a.ts|  - src/|' "$K/docs/dp/knowledge/a.md"
check "new untracked file in a covered dir"         "$(stale)" "STALE a.md STALE b.md UNVERIFIED x.md "
rc=0; (cd "$K" && "$P/bin/dp-kb-stale" --check >/dev/null) || rc=$?
check "--check exits 1 when stale"                  "$rc" 1

# ------------------------------------------------------------------------------------------
section "5. SessionStart and Stop hooks"
S="$(new_repo stop)"
mkdir -p "$S/docs/dp/knowledge" && cp "$P/templates/kb-index.md" "$S/docs/dp/knowledge/INDEX.md"
git -C "$S" add -A && git -C "$S" commit -qm kb
echo "pre-existing" >> "$S/src/a.ts"
ev()    { jq -cn --arg s "$1" --arg c "$S" --argjson a "${2:-false}" '{session_id: $s, cwd: $c, stop_hook_active: $a}'; }
start() { ev "$1" | "$P/scripts/session-start.sh"; }
stop()  {
  local o; o="$(ev "$1" "${2:-false}" | "$P/scripts/stop-docs.sh")"
  if [ -z "$o" ]; then echo pass; elif jq -e '.decision == "block"' <<<"$o" >/dev/null; then echo block; else echo message; fi
}
CTX="$(start s1 | jq -r '.hookSpecificOutput.additionalContext')"
if grep -q 'dev-pattern rules' <<<"$CTX" && grep -q 'Knowledge index' <<<"$CTX"; then ok "context has rules and index"; else bad "context lacks rules or index"; fi
if [ "${#CTX}" -lt 10000 ]; then ok "context fits the 10k hook limit (${#CTX})"; else bad "context is ${#CTX} chars"; fi
check "work from before the session is ignored"     "$(stop s1)" pass
echo b > "$S/src/b.ts"
check "code changed, no docs → block"               "$(stop s1)" block
check "still blocked when stop_hook_active"         "$(stop s1 true)" block
(cd "$S" && "$P/bin/dp-docs-waive" "test waiver" >/dev/null)
check "waiver for this exact tree"                  "$(stop s1 true)" message
echo c >> "$S/src/b.ts"
check "further change voids the waiver"             "$(stop s1)" block
echo note >> "$S/docs/dp/knowledge/INDEX.md"
check "docs updated → pass"                         "$(stop s1)" pass
git -C "$S" add -A && git -C "$S" commit -qm work
check "commit inside the session → pass"            "$(stop s1)" pass
start s2 >/dev/null
mkdir -p "$S/docs/dp/plans" && echo p > "$S/docs/dp/plans/x.md" && echo d > "$S/src/d.ts"
check "a plan file is not documentation"            "$(stop s2)" block
stop s2 true >/dev/null; stop s2 true >/dev/null
check "after 3 blocks the hook lets go"             "$(stop s2 true)" message
printf '// TODO(human): your turn\n' > "$S/src/e.ts"
start s3 >/dev/null; echo x > "$S/src/f.ts"; printf '// TODO(human): your turn\n' >> "$S/src/f.ts"
check "TODO(human) exercise may pause the turn"     "$(stop s3)" pass
mkdir -p "$S/.git/dp" && touch "$S/.git/dp/disabled"
check "disabled repository: no context"             "$(start s4)" ""
rm -f "$S/.git/dp/disabled"
NG="$TMP/nogit" && mkdir -p "$NG"
check "outside git: no output"                      "$(jq -cn --arg c "$NG" '{session_id: "x", cwd: $c}' | "$P/scripts/stop-docs.sh")" ""
check "real index untouched by tree snapshots"      "$(git -C "$S" diff --cached --name-only | wc -l | tr -d ' ')" 0

# ------------------------------------------------------------------------------------------
section "6. setup / uninstall on a foreign repository"
F="$TMP/foreign"
mkdir -p "$F/.claude" "$F/docs" "$F/scripts" && git -C "$F" init -q
echo '# Existing rules' > "$F/CLAUDE.md"
printf '{\n    "model": "sonnet",\n    "permissions": { "allow": ["Bash(npm test)"] }\n}\n' > "$F/.claude/settings.json"
echo '# arch' > "$F/docs/architecture.md" && echo 'echo hi' > "$F/scripts/status.sh"
git -C "$F" add -A && git -C "$F" commit -qm init
snap() { git -C "$F" status --porcelain --untracked-files=all; git -C "$F" diff | git hash-object --stdin; cat "$F/.git/info/exclude" 2>/dev/null | git hash-object --stdin; }
BEFORE="$(snap)"

out="$(cd "$F" && "$P/bin/dp-setup" --mode shared)"
if grep -q '! model' <<<"$out"; then ok "shared: existing model is reported, not overwritten"; else bad "shared: model conflict not reported"; fi
check "shared: model left as is"                    "$(jq -r .model "$F/.claude/settings.json")" sonnet
check "shared: plan mode by default"                "$(jq -r .permissions.defaultMode "$F/.claude/settings.json")" plan
check "shared: existing permissions kept"           "$(jq -c .permissions.allow "$F/.claude/settings.json")" '["Bash(npm test)"]'
check "shared: CLAUDE.md untouched"                 "$(git -C "$F" diff --name-only -- CLAUDE.md docs/architecture.md scripts/)" ""
check "shared: second run is a no-op"               "$(cd "$F" && "$P/bin/dp-setup" --mode shared | grep -c 'already set up')" 1
(cd "$F" && "$P/bin/dp-uninstall" --purge-kb >/dev/null)
check "shared: uninstall leaves the repo as it was" "$(snap)" "$BEFORE"

(cd "$F" && "$P/bin/dp-setup" --mode local >/dev/null)
check "local: nothing visible to git"               "$(git -C "$F" status --porcelain)" ""
check "local: model set in settings.local.json"     "$(jq -r .model "$F/.claude/settings.local.json")" opus
(cd "$F" && "$P/bin/dp-uninstall" >/dev/null)
check "local: hooks off after uninstall"            "$(cd "$F" && bash -c ". '$P/scripts/lib.sh'; dp_active && echo on || echo off")" off
rm -rf "$F/docs/dp"
check "local: uninstall leaves the repo as it was"  "$(snap)" "$BEFORE"

(cd "$F" && "$P/bin/dp-setup" --mode shared --force >/dev/null)
jq '.env = {"BAR": "2"}' "$F/.claude/settings.json" > "$F/x" && mv "$F/x" "$F/.claude/settings.json"
(cd "$F" && "$P/bin/dp-uninstall" --purge-kb >/dev/null)
check "edited after setup: only our keys removed"   "$(jq -c . "$F/.claude/settings.json")" \
  '{"model":"sonnet","permissions":{"allow":["Bash(npm test)"]},"env":{"BAR":"2"}}'

# ------------------------------------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
  printf '%sAll checks passed.%s\n' "$G" "$N"
else
  printf '%s%d check(s) failed.%s\n' "$R" "$FAILED" "$N"
  exit 1
fi
