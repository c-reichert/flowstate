---
name: skill:subagent-driven-development
description: Use when executing implementation plans with independent tasks — dispatches a fresh subagent per task with two-stage review (spec compliance then code quality) after each.
---

# Subagent-Driven Development

## Overview

Execute a plan by dispatching a fresh subagent per task, with two-stage review after each: spec compliance first, then code quality.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.

## Per-Task Execution Flow

```
for each task in plan:
  1. Dispatch implementer subagent (Sonnet)
  2. Spec compliance review (Sonnet) — MUST pass before step 3
  3. Code quality review (Opus) — only runs after step 2 passes
  4. Incremental commit (if logical unit complete)
  5. Mark task complete, update progress
  next task
```

## Two-Stage Review Checkpoint

**Order is mandatory: spec compliance FIRST, then code quality. Never reverse.**

Why: No point reviewing code quality on code that does not meet the spec. Fix what it does before evaluating how it does it.

**Review loop:** If a reviewer rejects, the implementer fixes and the reviewer re-reviews. Loop until approved. Do not skip re-review.

**Escalation:** If the implementer cannot pass spec review after 2 attempts, escalate to the user. The task spec may need refinement.

---

## Implementer Prompt Template

Dispatch with model: **Sonnet**

```
You are implementing a task from a plan. Follow TDD strictly.

## Task
[FULL task text pasted here — files, steps, test code, implementation code.
Do NOT reference a file. Paste the complete task.]

## Context
- Project: [brief description]
- Previous tasks completed: [list with summary of what each built]
- Architecture: [relevant context for where this task fits]
- Conventions: [from CLAUDE.md]

## TDD Rules (invoke flowstate:tdd skill)

THE IRON LAW: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Write code before the test? Delete it. Start over. No exceptions.

Cycle for this task:
1. RED: Write the failing test exactly as specified in the task
2. VERIFY RED: Run the test. Confirm it fails for the RIGHT reason
   - Feature missing = correct failure
   - Typo/syntax error = wrong failure -> fix the test first
3. GREEN: Write MINIMAL implementation to pass the test
   - Simplest code that makes the test pass
   - Do not add features the test does not require
4. VERIFY GREEN: Run the test. Confirm pass. Run full suite — no regressions.
5. REFACTOR: Clean up if needed. Verify tests still pass after refactoring.

## Self-Review Checklist (before reporting done)
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass (full suite, not just new tests)
- [ ] Output is pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and error paths covered
- [ ] Code follows project conventions (CLAUDE.md)
- [ ] No unnecessary features added (YAGNI)

## Learnings to Apply
[Any relevant docs/solutions/ references for this task]

Report: files created/modified, tests written, test results, implementation notes.
```

---

## Spec Reviewer Prompt Template

Dispatch with model: **Sonnet**

```
You are a spec compliance reviewer. Your job is to verify that the
implementation matches the task specification exactly.

CRITICAL INSTRUCTION: Do not trust the implementer's report. The
implementer finished suspiciously quickly. Read the actual code.

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
5. Verify tests actually test what they claim

## Output Format

For each requirement:
- Requirement: [what the spec says]
- Status: PASS or FAIL
- Evidence: [file:line reference]
- Notes: [if FAIL, what's wrong and how to fix]

## Final Assessment
- APPROVED: All requirements met, no extra features, tests are real
- REJECTED: [list of issues with file:line references]

If REJECTED, be specific about what needs to change. The implementer
will fix and you will re-review.
```

---

## Code Quality Reviewer Prompt Template

Dispatch with model: **Sonnet**

```
You are a code quality reviewer. The code has already passed spec
compliance review — it does what the task requires. Your job is to
evaluate HOW it does it.

## Code to Review
[List of files modified/created in this task]

## Review Criteria

### Code Cleanliness
- Clear naming (variables, functions, classes)
- Appropriate comments (why, not what)
- Consistent style with rest of codebase
- No dead code or commented-out code

### Testing Quality
- Tests are meaningful (not just "it doesn't crash")
- Edge cases covered
- Tests are readable and maintainable
- No excessive mocking

### Maintainability
- Single responsibility principle
- Appropriate abstraction level
- Dependencies are clear and minimal
- Future developers can understand this code

### YAGNI
- No features beyond what the spec requires
- No premature optimization
- No "just in case" code

## Output Format

### Strengths
- [What's done well]

### Issues
**Critical** (must fix before merge):
- [file:line] — [issue and fix]

**Important** (should fix):
- [file:line] — [issue and fix]

**Minor** (nice to have):
- [file:line] — [suggestion]

### Assessment
APPROVED / NEEDS WORK (critical issues exist)
```

---

## Incremental Commit Heuristic

| Commit when... | Don't commit when... |
|----------------|---------------------|
| Logical unit complete (model, service, component) | Small part of a larger unit |
| Tests pass + meaningful progress | Tests failing |
| About to switch contexts (backend to frontend) | Purely scaffolding with no behavior |
| About to attempt risky/uncertain changes | Would need a "WIP" commit message |

**Rule of thumb:** Can you write a commit message that describes a complete, valuable change? If yes, commit. If it would be "WIP" or "partial X", wait.

```bash
# 1. Verify tests pass
[project test command]

# 2. Stage only files related to this logical unit (NOT git add .)
git add <specific files for this task>

# 3. Commit with conventional message
git commit -m "feat(scope): description of this unit"
```

---

## Progress Updates

After each task: mark completed in TodoWrite, update plan checkboxes (`- [ ]` to `- [x]`), brief user update on what was completed and what's next.

---

## Red Flags — Never Do

- Start implementation on main/master without explicit user consent
- Skip either review stage (spec compliance OR code quality)
- Proceed with unfixed issues from a reviewer
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make a subagent read a plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance
- Skip re-review after implementer fixes issues
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance passes** (wrong order)
- Move to next task while either review has open issues

## When Things Go Wrong

| Problem | Action |
|---------|--------|
| Implementer fails spec review after 2 attempts | Escalate to user |
| Quality reviewer flags critical issues after 2 fixes | Ask user to triage |
| Task impossible or contradicts codebase | Report to user, suggest alternatives |
| Circular dependency between tasks | Restructure order, ask user to approve |
| Subagent asks questions | Answer clearly and completely before proceeding |
| Subagent fails | Dispatch fix subagent with specific instructions (no manual fixes) |
