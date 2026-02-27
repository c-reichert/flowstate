---
name: work
description: "Execute an implementation plan task-by-task with strict TDD discipline, worktree isolation, subagent dispatch, and two-stage code review. Produces tested, committed, PR-ready code."
disable-model-invocation: true
argument-hint: "[path to plan file in docs/plans/]"
---

# Execute a Plan with TDD

Orchestrate plan execution by coordinating setup, per-task subagent dispatch, verification, and branch finishing. Process knowledge lives in skills — this command sequences them.

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
# Auto-detect and run project setup (package.json, pyproject.toml, Cargo.toml, etc.)
# Run full test suite to verify clean baseline
# ALL tests must pass before we start making changes
```

**If baseline tests fail:** Stop immediately. Report failures. Ask the user how to proceed.

### 1.4 Create TodoWrite

Parse all tasks from the plan and create a TodoWrite with dependencies and ordering.

---

## Phase 2: Per-Task Execution

**Invoke the flowstate:subagent-driven-development skill.**

For each task in the plan, the skill handles:
- Dispatching an implementer subagent with full task text and context
- Spec compliance review (must pass before quality review)
- Code quality review (only after spec compliance passes)
- Incremental commits when logical units are complete
- Progress updates (TodoWrite + plan checkboxes + user notification)

The orchestrator's job during this phase:
1. **Provide context** — feed each task's full text, previous task summaries, and architecture context to the skill
2. **Answer questions** — if a subagent surfaces questions, answer them
3. **Handle escalations** — if spec review fails after 2 attempts, triage with the user
4. **Adapt the plan** — if a task is impossible or unnecessary, note it, update the plan, move on

---

## Phase 3: Verification Gate

**Invoke the flowstate:verification-before-completion skill.**

Before claiming all work is done, the verification gate requires:
1. Full test suite — run fresh, read complete output, zero failures
2. Linting — clean, no errors
3. Type checking — if applicable, passes
4. Requirements — line-by-line checklist against the plan

Only after all verification passes can you proceed to Phase 4.

---

## Phase 4: Review

**Invoke `/flowstate:review`** to run multi-agent code review on the completed work.

This is NOT optional. Do NOT skip to shipping. The pipeline is: Execute → Verify → **Review** → Compound → Ship.

The review dispatches 5 parallel agents (security, performance, simplicity, architecture, patterns) plus the learnings-researcher. Address all P1 findings before proceeding. Triage P2/P3 with the user.

---

## Phase 5: Compound

**Invoke `/flowstate:compound`** to capture learnings from this work.

This is NOT optional. Every non-trivial implementation session produces insights worth preserving. Skip only if the user explicitly declines.

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

### 6.2 Finish the Branch

**Invoke the flowstate:finishing-a-branch skill.**

The skill handles: presenting options (merge / PR / keep / discard), executing the chosen option, worktree cleanup, and branch cleanup.

### 6.3 Update Plan Status

Update the plan's YAML frontmatter: `status: active` to `status: completed`

### 6.4 Notify User

- Summarize what was completed
- Link to PR (if created)
- Report test results
- Note any follow-up work needed

---

## Key Principles

- **TDD is not optional** — invoke flowstate:tdd for every implementation task
- **Subagents do not self-certify** — spec reviewer reads actual code, not the implementer's report
- **Incremental commits build confidence** — small, tested, focused commits
- **The plan is your guide, not your prison** — adapt to reality, update the plan
- **Verification is the final word** — no task is done until tests prove it

---

## When Things Go Wrong

| Problem | Action |
|---------|--------|
| Baseline tests fail before starting | Stop. Report. Ask user. |
| Implementer can't pass spec review after 2 attempts | Escalate to user. Task spec may need refinement. |
| Quality reviewer flags critical issues after 2 fix attempts | Ask user to triage. |
| Full suite has unrelated failures | Identify and document. Ask user if pre-existing. |
| Plan task is impossible or contradicts codebase | Report to user. Suggest alternatives. Update plan. |
| Dependency between tasks creates circular requirement | Restructure order. Ask user to approve. |
