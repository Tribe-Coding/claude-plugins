---
name: review-plan
description: >
  Manually trigger a fresh-context review of an implementation plan.
  Use after exiting plan mode, or to review a plan pasted from another session or document.
  Critiques the plan for gaps, blind spots, and ordering issues, then iterates it before any code.
  Keywords: review plan, review-plan, critique plan, plan review, check my plan.
---

# Review Plan

Run a fresh-context review of an implementation plan.

## Steps

### 1. Locate the plan

- If a plan was just produced in this session (via plan mode / `ExitPlanMode`) → use that plan text.
- If the user passed a plan as an argument or pasted one → use that.
- If no plan is available → ask the user to paste the plan to review.

### 2. Run the review protocol

Invoke the `plan-review-guide` skill and follow its protocol exactly:

- Isolate the plan artifact — pass only the plan text to the reviewer, never the planning chat.
- Spawn a fresh-context `Task` subagent with the review prompt from the guide.
- The review must produce prioritized findings with a concrete suggestion for **every** finding.

### 3. Apply and present

- Show the findings table verbatim.
- Revise the plan with the suggestions (CRITICAL/HIGH always; MEDIUM/LOW unless the user opts out).
- Present the revised plan and the verdict.
- On a `RECONSIDER APPROACH` verdict → stop and ask the user how to proceed; do not implement.

Implement only after the revised plan is accepted.
