# Plan-Review Plugin Acceptance Tests

## Purpose

The plan-review plugin makes Claude run a fresh-context review of an implementation plan before writing code. These tests verify that required files are valid, the SessionStart hook injects rules correctly, and the proactive review behavior triggers as expected.

## Test Execution Order

1. Static checks (automated)
2. Script unit tests — inject-rules.sh (automated)
3. Behavioral tests — SessionStart rules (manual, fresh session)
4. End-to-end — full plan-review workflow (manual)

## Automation Status

- ✅ Fully automated: Tests 1–2
- ⚠️ Manual only: Tests 3–4 (require a fresh session and real plan mode usage)

---

## Test Categories

### 1. Static Checks

**Objective:** Verify file structure, YAML frontmatter, and JSON schema validity.

**Automation:** ✅

```bash
PLUGIN="$(git rev-parse --show-toplevel)/plugins/plan-review"

# 1.1 Check all required files exist
for f in \
  ".claude-plugin/plugin.json" \
  "hooks/hooks.json" \
  "scripts/inject-rules.sh" \
  "commands/review-plan/SKILL.md" \
  "skills/plan-review-guide/SKILL.md" \
  "docs/ACCEPTANCE_TESTS.md" \
  "README.md"; do
  test -f "$PLUGIN/$f" && echo "✅ $f" || echo "❌ MISSING: $f"
done

# 1.2 Validate JSON files
for f in ".claude-plugin/plugin.json" "hooks/hooks.json"; do
  jq empty "$PLUGIN/$f" 2>/dev/null && echo "✅ JSON valid: $f" || echo "❌ Invalid JSON: $f"
done

# 1.3 inject-rules.sh is executable
test -x "$PLUGIN/scripts/inject-rules.sh" && echo "✅ inject-rules.sh executable" || echo "❌ not executable"

# 1.4 SKILL.md files have YAML frontmatter with name + description
for f in "commands/review-plan/SKILL.md" "skills/plan-review-guide/SKILL.md"; do
  head -1 "$PLUGIN/$f" | grep -q '^---$' \
    && grep -q '^name:' "$PLUGIN/$f" \
    && grep -q '^description:' "$PLUGIN/$f" \
    && echo "✅ frontmatter OK: $f" || echo "❌ frontmatter missing: $f"
done

# 1.5 No duplicate skill name across commands/ and skills/
CMD_NAME=$(grep '^name:' "$PLUGIN/commands/review-plan/SKILL.md" | head -1)
SKILL_NAME=$(grep '^name:' "$PLUGIN/skills/plan-review-guide/SKILL.md" | head -1)
[ "$CMD_NAME" != "$SKILL_NAME" ] && echo "✅ skill names distinct" || echo "❌ duplicate name: $CMD_NAME"
```

**Expected:** all lines print `✅`.

---

### 2. Script Unit Tests — inject-rules.sh

**Objective:** Verify the SessionStart hook outputs the expected rules block.

**Automation:** ✅

```bash
PLUGIN="$(git rev-parse --show-toplevel)/plugins/plan-review"
OUT=$(bash "$PLUGIN/scripts/inject-rules.sh")

# 2.1 Outputs the rules header
echo "$OUT" | grep -q "Plan Review — Base Rules" && echo "✅ header present" || echo "❌ header missing"

# 2.2 References the ExitPlanMode trigger
echo "$OUT" | grep -q "ExitPlanMode" && echo "✅ trigger present" || echo "❌ trigger missing"

# 2.3 Mandates the plan-review-guide skill
echo "$OUT" | grep -q "plan-review-guide" && echo "✅ skill invocation present" || echo "❌ skill invocation missing"

# 2.4 Exit code is 0 (never blocks session start)
bash "$PLUGIN/scripts/inject-rules.sh" >/dev/null 2>&1 && echo "✅ exit 0" || echo "❌ non-zero exit"
```

**Expected:** all lines print `✅`.

---

### 3. Behavioral Tests — SessionStart Rules

**Objective:** Verify the rules inject into a real session.

**Automation:** ⚠️ Manual — requires a fresh session.

| # | Step | Expected |
|---|------|----------|
| 3.1 | Install the plugin, start a fresh session | No errors at startup |
| 3.2 | Run `/context` | "Plan Review — Base Rules" appears in the SessionStart hook output |
| 3.3 | Confirm skill listing | `review-plan` and `plan-review-guide` both appear, with no duplicate names |

---

### 4. End-to-End — Full Plan-Review Workflow

**Objective:** Verify the proactive review fires and the protocol runs correctly.

**Automation:** ⚠️ Manual — requires real plan mode usage.

| # | Step | Expected |
|---|------|----------|
| 4.1 | Enter plan mode, ask for a non-trivial plan, accept it | Claude offers a fresh-context review before writing code |
| 4.2 | Accept the review offer | Claude invokes `plan-review-guide`, spawns a `Task` subagent |
| 4.3 | Inspect the subagent invocation | Subagent receives only the plan text — not the planning conversation |
| 4.4 | Review the output | Findings are prioritized (CRITICAL/HIGH/MEDIUM/LOW); every finding has a concrete suggestion; output ends with a verdict |
| 4.5 | Continue | Claude presents a revised plan before implementing |
| 4.6 | Decline the review offer in a second run | Claude proceeds to implementation without nagging |
| 4.7 | Run `/review-plan` with a pasted external plan | Review runs on the pasted plan |
| 4.8 | Force a `RECONSIDER APPROACH` verdict (review a deliberately flawed plan) | Claude halts, surfaces the verdict, asks how to proceed — does not implement |
