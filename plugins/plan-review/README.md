# plan-review

> [!TIP]
> ✨ ***Never implement an unreviewed plan — a fresh-context agent critiques it for blind spots before any code is written.***

The plan-and-review pattern for Claude Code. After plan mode produces an implementation plan, a second agent with **fresh context** critiques it — surfacing gaps, blind spots, ordering problems, and missing edge cases that the planning agent cannot see because it authored the plan. Catches intent-level errors before tokens are burned generating broken code.

> [!NOTE]
> [⚙️ How it works](#how-it-works) · [📦 Installation](#installation) · [🛠️ Skills](#skills) · [📚 Reference](#reference)

## 🎬 Demo <a name="demo"></a>

```markdown
You: [accepts a plan from plan mode]

Claude: Want a fresh-context review of this plan first?

You: yes

Claude: Spawned a fresh-context reviewer. Findings:

| Priority | Finding                                          | Suggestion                                              |
|----------|--------------------------------------------------|---------------------------------------------------------|
| CRITICAL | Migration step has no rollback path              | Add step 4b: wrap migration in a transaction with down  |
| HIGH     | Step 3 assumes the cache is warm — never stated  | Add explicit cache-warm or cold-start handling to step 3|
| MEDIUM   | No test named for the new error branch           | Name the test in step 6: test_auth_expired_token        |

Verdict: REVISE (major)

Revised plan applied. Here is the updated plan — review before I implement.
```

## ⚙️ How it works <a name="how-it-works"></a>

| Trigger | What happens |
|---------|-------------|
| SessionStart | Injects plan-review rules — Claude offers a review after every accepted plan |
| After `ExitPlanMode` | Claude proactively offers a fresh-context review before writing code |
| `/review-plan` | Manually review a plan — including one pasted from another session or a document |

The reviewer is a **fresh-context subagent** spawned via the `Task` tool. It receives only the plan text — never the planning conversation — so it does not inherit the planning agent's assumptions. It returns prioritized findings (CRITICAL / HIGH / MEDIUM / LOW), each with a concrete suggested change, plus a verdict.

**Why fresh context:** the agent that wrote a plan cannot reliably review it — its context is anchored to the reasoning that produced the plan. A clean-context reviewer re-derives judgment from the artifact alone. Asking for a suggestion for *every* finding (not just the top few) forces the list to be exhausted.

## 📦 Installation <a name="installation"></a>

```bash
/plugin marketplace add Tribe-Coding/claude-plugins
/plugin install plan-review@tribe-coding
```

Select **plan-review** in `/plugin` → enable **auto-update**. Restart your session — done. No configuration required.

## 🛠️ Skills <a name="skills"></a>

| Skill | Type | Purpose |
|-------|------|---------|
| `review-plan` | Command | Manually trigger a fresh-context plan review (`/review-plan`) |
| `plan-review-guide` | Skill | The review protocol — subagent prompt, prioritized findings, iteration |

## 📚 Reference <a name="reference"></a>

The review protocol runs in four steps:

1. **Isolate the plan** — extract the plan artifact only; the planning chat is never passed on.
2. **Spawn the reviewer** — a fresh-context `Task` subagent critiques the plan with a skeptical-reviewer prompt.
3. **Apply the review** — show the findings table, revise the plan with the suggestions, present the revised plan.
4. **Optional second pass** — re-review the revised plan for large or high-risk work; stop when no CRITICAL/HIGH findings remain.

A `RECONSIDER APPROACH` verdict halts implementation — Claude surfaces it and asks how to proceed.

The pattern originates from the plan-and-review workflow described by Matt Cary (Cloudflare) and Adam Stacoviak on The Changelog: have one model plan, hand the plan to a second model invocation with fresh context, ask it to list gaps and blind spots with priorities, and get a concrete suggestion for each before writing any code.
