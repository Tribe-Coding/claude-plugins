#!/bin/bash
# SessionStart hook: inject plan-review rules into Claude's context.
# Makes Claude proactively offer a fresh-context review after plan mode
# produces an implementation plan, before any code is written.
# Silent on errors — never block session start.

cat <<'RULES'
## Plan Review — Base Rules

MANDATORY: A plan produced in plan mode is reviewed by a fresh-context subagent before any code is written.

- After `ExitPlanMode` is accepted (a plan was produced) → offer a fresh-context plan review BEFORE writing code: "Want a fresh-context review of this plan first?"
- When the user accepts → invoke the `plan-review-guide` skill and follow its protocol exactly. NEVER review the plan yourself in the same context — your context is biased by having authored the plan.
- When the user declines → proceed to implementation without nagging.
- The reviewer subagent receives ONLY the plan text — never the planning conversation, rationale, or chat history. Independence is the point.
- The review MUST produce, for the plan: (1) gaps, blind spots, and unclear points, (2) each finding tagged with a priority, (3) a concrete suggested change for EVERY finding — not just the top few.
- After the review returns → revise the plan with the findings, show the user the revised plan, then implement.
- Run `/review-plan` to review a plan manually — including a plan pasted from outside this session.
- **ALWAYS invoke the `plan-review-guide` skill BEFORE running any plan review** to load the full review protocol and subagent prompt. This is MANDATORY — do not skip this step.
RULES
