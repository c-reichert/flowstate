---
name: workflow:work-forge
description: "Execute an implementation plan for Atlassian Forge apps with automated verification (yarn lint, tsc), structured tunnel verification, worktree isolation, subagent dispatch, and two-stage code review."
disable-model-invocation: false
argument-hint: "[path to plan file in docs/plans/]"
---

# Execute a Plan — Forge App Variant

Orchestrate plan execution for Atlassian Forge apps. Replaces TDD with **automated static checks + structured tunnel verification** that respect Forge's sandboxed runtime constraints.

## Why This Variant Exists

Forge apps run inside Atlassian's sandboxed runtime. `@forge/api` and `@forge/bridge` only exist at runtime on Atlassian infrastructure — not in standard Node.js. Traditional test-first development does not apply. Verification is achieved through linting, type checking, and live tunnel verification against a real Atlassian dev site.

**The Forge Verification Law:**
```
EVERY TASK must pass: yarn lint → tsc --noEmit → tunnel verification
NEVER skip verification — confidence is not evidence
```

## Input Document

<plan_path> #$ARGUMENTS </plan_path>

**If the plan path above is empty:**
1. Check `docs/plans/` for the most recently modified active plan:
   ```bash
   ls -lt docs/plans/*.md 2>/dev/null | head -5
   ```
2. If found, ask: "Found plan at `[path]`. Should I execute this one?"
3. If not found, ask: "Which plan should I execute? Provide the path."

Do not proceed until you have a valid plan file.

---

## Forge Verification Model

Two automated gates run after every task. Tunnel verification runs at the end or when the user requests it.

| Gate | Command | What It Catches | When |
|------|---------|-----------------|------|
| Lint | `yarn lint` | Code quality, style, unused vars, common errors | After every task |
| Types | `tsc --noEmit` | Type errors across codebase | After every task |
| Tunnel | `forge tunnel` + browser | Real Forge API behavior, UI rendering, permissions | Phase 3 or on request |

**Automated gates are non-negotiable. Run them fresh, read the output, fix issues before proceeding.**

---

## Phase 1: Setup

### 1.1 Read Plan and Clarify

- Read the plan document **completely** — every section, every task, every acceptance criterion
- Review any references or links provided in the plan (brainstorm, learnings, patterns)
- If anything is unclear or ambiguous, **ask clarifying questions NOW**
- Get user approval to proceed

### 1.2 Create Worktree

Invoke the **flowstate:using-worktrees** skill to create an isolated workspace:

```bash
feature_name="<kebab-case-feature-name>"
mkdir -p .worktrees
git worktree add .worktrees/$feature_name -b feature/$feature_name
cd .worktrees/$feature_name
```

If the user prefers not to use a worktree, ask: "Continue on current branch, or create a new branch?"

### 1.3 Install Dependencies and Verify Baseline

```bash
yarn install
yarn lint
tsc --noEmit
```

**If any baseline check fails:** Stop immediately. Report failures. Ask the user how to proceed.

### 1.4 Create TodoWrite

Parse all tasks from the plan and create a TodoWrite with dependencies and ordering.

---

## Phase 2: Per-Task Execution

**Invoke the flowstate:subagent-driven-development skill** with the modified implementer prompt below.

The skill auto-detects execution mode based on plan dependency metadata:
- **Sequential** (default): Tasks processed one-by-one with two-stage review per task.
- **Parallel** (wave-based): Independent tasks execute simultaneously via team agents.

For each task (in either mode), the skill handles:
- Dispatching an implementer subagent with full task text and context
- Spec compliance review (must pass before quality review)
- Code quality review (only after spec compliance passes)
- **Automated verification after implementation: `yarn lint` + `tsc --noEmit`**
- Incremental commits when logical units are complete
- Progress updates (TodoWrite + plan checkboxes + user notification)

### The Orchestrator's Job During This Phase

1. **Provide context** — feed each task's full text, previous task summaries, and architecture context to the skill
2. **Answer questions** — if a subagent surfaces questions, answer them
3. **Handle escalations** — if spec review fails after 2 attempts, triage with the user
4. **Adapt the plan** — if a task is impossible or unnecessary, note it, update the plan, move on
5. **Enforce automated gates** — `yarn lint` and `tsc --noEmit` must pass after every task, no exceptions

---

### Phase 2.5: Merge Verification (parallel mode only)

If parallel mode was used, verify the merged feature branch before proceeding:
1. Confirm all task branches have been merged to the feature branch
2. Run `yarn lint` and `tsc --noEmit` on the merged feature branch
3. If failures exist, investigate whether merge introduced regressions
4. All automated checks must pass before proceeding to Phase 3

---

## Phase 3: Verification Gate

**Invoke the flowstate:verification-before-completion skill** with Forge adaptations.

Before claiming all work is done, the verification gate requires ALL of these:

### Automated Gates (non-negotiable, run fresh)
1. **Lint** — `yarn lint` → clean, zero errors, read complete output
2. **Type check** — `tsc --noEmit` → passes, zero errors

### Structured Tunnel Verification (for Forge integration code)
3. **Tunnel verification** — present the user with a structured checklist:

```markdown
## Tunnel Verification Checklist

Forge tunnel must be running: `forge tunnel`
Test against: [dev site URL]

For each feature/behavior in this implementation:
- [ ] [Feature/behavior 1]: [what to do] → [expected result]
- [ ] [Feature/behavior 2]: [what to do] → [expected result]
- [ ] Error handling: [trigger error condition] → [expected behavior]
- [ ] Permissions: verify scopes are sufficient (no 403s in console)
- [ ] Console: no unexpected errors in tunnel terminal output

Status: PENDING USER VERIFICATION
```

**Do NOT claim work is complete until the user confirms tunnel verification.**
**Do NOT substitute "I'm confident" for actual tunnel testing.**

### Requirements Gate
4. **Line-by-line checklist** against the plan — every acceptance criterion confirmed with evidence (lint/type output for code correctness, user confirmation for Forge behavior)

Only after ALL gates pass can you proceed to Phase 4.

---

## Phase 4: Review

**Invoke `/workflow:review`** to run multi-agent code review on the completed work.

This is NOT optional. The pipeline is: Execute → Verify → **Review** → Compound → Ship.

The review dispatches 5 parallel agents (security, performance, simplicity, architecture, patterns) plus the learnings-researcher. Address all P1 findings before proceeding. Triage P2/P3 with the user.

**Additional Forge-specific review concerns:**
- Forge permission scopes: are they minimal and correct?
- Storage API usage: proper error handling, key naming conventions
- Rate limiting: Forge has request limits — is the code respectful of them?
- Sandbox constraints: no disallowed Node.js APIs used?
- Content Security Policy: Custom UI respects Forge CSP?
- manifest.yml: scopes, modules, and triggers match implementation

---

## Phase 5: Compound

**Invoke `/workflow:compound`** to capture learnings from this work.

This is NOT optional. Forge development has many gotchas worth documenting. Skip only if the user explicitly declines.

**Forge-specific learnings to capture:**
- Forge API behaviors discovered during tunnel testing
- Manifest configuration patterns
- Scopes that were needed vs. what documentation suggested
- Workarounds for sandbox limitations

---

## Phase 6: Ship

### 6.1 Final Commit

If any uncommitted changes remain (e.g., review fixes):

```bash
git status
git add <remaining files>
git commit -m "$(cat <<'EOF'
feat(scope): description of what and why

Brief explanation of the complete feature.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 6.2 Deploy to Development (if requested)

```bash
forge deploy -e development
forge install --upgrade --site <dev-site> --product jira -e development
```

**Note:** Manifest changes (`manifest.yml`) ALWAYS require a full deploy — tunnel cannot pick them up.

### 6.3 Finish the Branch

**Invoke the flowstate:finishing-a-branch skill.**

The skill handles: presenting options (merge / PR / keep / discard), executing the chosen option, worktree cleanup, and branch cleanup.

### 6.4 Update Plan Status

Update the plan's YAML frontmatter: `status: active` → `status: completed`

### 6.5 Notify User

- Summarize what was completed
- Link to PR (if created)
- Report lint and type check results
- Report tunnel verification status (confirmed / pending)
- Note any follow-up work needed (staging deploy, etc.)

---

## Forge Implementer Prompt Template

Dispatch with model: **Sonnet**

```
You are implementing a task from a Forge app plan. This is an Atlassian Forge
app — @forge/api and @forge/bridge only exist in the Forge runtime, not in
standard Node.js.

## Task
[FULL task text pasted here — files, steps, acceptance criteria.
Do NOT reference a file. Paste the complete task.]

## Context
- Project: [brief description — Forge app for Jira]
- Previous tasks completed: [list with summary of what each built]
- Architecture: [relevant context for where this task fits]
- Conventions: [from CLAUDE.md]

## Verification Rules

This project does NOT use automated tests. Verification is:
1. `yarn lint` — must pass, zero errors
2. `tsc --noEmit` — must pass, zero type errors
3. Tunnel verification — document what needs manual checking

After implementing, you MUST:
1. Run `yarn lint` and fix any errors
2. Run `tsc --noEmit` and fix any type errors
3. Write a tunnel verification checklist for integration behavior

Do NOT claim the task is done until lint and types pass clean.

## Self-Review Checklist (before reporting done)
- [ ] `yarn lint` passes (zero errors)
- [ ] `tsc --noEmit` passes (zero type errors)
- [ ] No unnecessary features added (YAGNI)
- [ ] Code follows project conventions (CLAUDE.md)
- [ ] manifest.yml changes are correct (if applicable)
- [ ] Forge permission scopes are minimal and correct (if applicable)
- [ ] Tunnel verification checklist written for integration behavior

## Learnings to Apply
[Any relevant docs/solutions/ references for this task]

Report: files created/modified, lint results, type check results,
tunnel verification checklist, implementation notes.
```

---

## Forge Spec Reviewer Prompt Template

Dispatch with model: **Sonnet**

```
You are a spec compliance reviewer for an Atlassian Forge app. Your job is to
verify that the implementation matches the task specification exactly.

CRITICAL INSTRUCTION: Do not trust the implementer's report. The implementer
finished suspiciously quickly. Read the actual code.

## Task Specification
[Full task text from the plan]

## What to Check

Read each file that was supposed to be created or modified.
Compare the actual code against the task specification line by line.

For each requirement in the spec:
1. Find the code that implements it
2. Verify it matches the specification
3. Check for missing pieces (spec says X, code doesn't do X)
4. Check for extra features (code does Y, spec doesn't mention Y)

### Forge-Specific Checks:
5. `manifest.yml` changes match what the task requires (scopes, modules, triggers)
6. Tunnel verification checklist covers all integration points
7. No disallowed Node.js APIs used (Forge sandbox restrictions)

### Verification Checks:
8. Run `yarn lint` — confirm zero errors
9. Run `tsc --noEmit` — confirm zero type errors

## Output Format

For each requirement:
- Requirement: [what the spec says]
- Status: PASS or FAIL
- Evidence: [file:line reference]
- Notes: [if FAIL, what's wrong and how to fix]

## Final Assessment
- APPROVED: All requirements met, verification passed, checklist complete
- REJECTED: [list of issues with file:line references]

If REJECTED, be specific about what needs to change. The implementer will fix
and you will re-review.
```

---

## Key Principles

- **`yarn lint` + `tsc --noEmit` after every task** — non-negotiable automated gates
- **Tunnel verification requires user confirmation** — the AI cannot click through Jira
- **Subagents do not self-certify** — spec reviewer reads actual code, not the implementer's report
- **Incremental commits build confidence** — small, focused commits
- **The plan is your guide, not your prison** — adapt to reality, update the plan
- **Verification is the final word** — no task is done until checks prove it

---

## When Things Go Wrong

| Problem | Action |
|---------|--------|
| Baseline lint/types fail before starting | Stop. Report. Ask user. |
| Implementer can't pass spec review after 2 attempts | Escalate to user. Task spec may need refinement. |
| Quality reviewer flags critical issues after 2 fix attempts | Ask user to triage. |
| `yarn lint` fails | Fix lint errors. Re-run. Do not proceed until clean. |
| `tsc --noEmit` fails | Fix type errors. Re-run. Do not proceed until clean. |
| Tunnel shows unexpected behavior | Check terminal output for errors. Compare with `forge logs`. Ask user. |
| Scopes insufficient (403 in tunnel) | Update manifest.yml scopes. Requires `forge deploy` — tunnel can't pick up manifest changes. |
| Plan task is impossible or contradicts codebase | Report to user. Suggest alternatives. Update plan. |
| Dependency between tasks creates circular requirement | Restructure order. Ask user to approve. |
| Merge conflict between parallel task branches | Attempt auto-resolve. If ambiguous, ask user. Re-run lint+types after resolution. |
| Rate limit during parallel execution | Degrade remaining wave tasks to sequential. Continue. |
| Implementer teammate unresponsive (>5 min) | Timeout, mark task deferred, continue wave. Retry after wave completes. |
| Team creation fails | Fall back to sequential execution for all tasks. |
