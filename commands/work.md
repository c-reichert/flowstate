---
name: work
description: "Execute an implementation plan task-by-task with strict TDD discipline, worktree isolation, subagent dispatch, and two-stage code review. Produces tested, committed, PR-ready code."
disable-model-invocation: true
argument-hint: "[path to plan file in docs/plans/]"
---

# Execute a Plan with TDD

## Introduction

Execute a plan systematically with strict test-driven development, worktree isolation, subagent-per-task dispatch, and two-stage review (spec compliance + code quality). The focus is on **shipping complete, tested features** — every line of production code is backed by a test that failed first.

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
- **Do not skip this** — better to ask questions now than build the wrong thing

### 1.2 Create Worktree

Invoke the **flowstate:using-worktrees** skill to create an isolated workspace:

```bash
# Derive feature name from plan title
feature_name="<kebab-case-feature-name>"

# Create worktree
mkdir -p .worktrees
git worktree add .worktrees/$feature_name -b feature/$feature_name

# Switch to worktree
cd .worktrees/$feature_name
```

If the user prefers not to use a worktree, ask: "Continue on current branch, or create a new branch?"
- If new branch: `git checkout -b feature/$feature_name`
- If current branch: Require explicit confirmation before proceeding

### 1.3 Install Dependencies and Verify Baseline

```bash
# Auto-detect and run project setup
# Look for: package.json → npm install
#           requirements.txt → pip install -r requirements.txt
#           pyproject.toml → uv sync / pip install -e .
#           Gemfile → bundle install
#           go.mod → go mod download
#           Cargo.toml → cargo build

# Run full test suite to verify clean baseline
# ALL tests must pass before we start making changes
# Use project's test command from CLAUDE.md or auto-detect
```

**If baseline tests fail:** Stop immediately. Report failures. Ask the user how to proceed. Do NOT start implementation on a broken baseline.

### 1.4 Create TodoWrite

Parse all tasks from the plan and create a TodoWrite:

```
TodoWrite:
  - Task 1: [Component Name] — status: pending
  - Task 2: [Component Name] — status: pending
  - Task 3: [Component Name] — status: pending
  ...
```

Include dependencies between tasks. Prioritize based on plan ordering.

---

## Phase 2: Per-Task Execution Loop

For each task in order:

```
while (tasks remain):
  2a. Dispatch Implementer
  2b. Spec Compliance Review
  2c. Code Quality Review (only if spec passes)
  2d. Incremental Commit (if appropriate)
  2e. Update Progress
```

### 2a. Dispatch Implementer (Opus Subagent)

Spawn an implementer subagent for each task. Provide:

1. **Full task text** — paste the complete task from the plan (not a file reference)
2. **Context** — where this fits in the overall architecture, what was built in previous tasks, dependencies
3. **TDD instructions** — invoke the flowstate:tdd skill rules
4. **Relevant learnings** — any `docs/solutions/` references from the plan for this task

**Implementer Prompt Template:**

```
You are implementing a task from a plan. Follow TDD strictly.

## Task
[Full task text pasted here — files, steps, test code, implementation code]

## Context
- Project: [brief description]
- Previous tasks completed: [list]
- Architecture: [relevant context]
- Conventions: [from CLAUDE.md]

## TDD Rules (from flowstate:tdd skill)

THE IRON LAW: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Write code before the test? Delete it. Start over. No exceptions.

Cycle for this task:
1. RED: Write the failing test exactly as specified in the task
2. VERIFY RED: Run the test. Confirm it fails for the RIGHT reason
   - Feature missing = correct failure
   - Typo/syntax error = wrong failure → fix the test first
3. GREEN: Write MINIMAL implementation to pass the test
   - Minimal means: simplest code that makes the test pass
   - Do not add features the test does not require
4. VERIFY GREEN: Run the test. Confirm pass. Run full suite — no regressions.
5. REFACTOR: Clean up if needed. Verify tests still pass after refactoring.

COMMON RATIONALIZATIONS (all invalid):
| Excuse                              | Reality                                      |
|-------------------------------------|----------------------------------------------|
| "Too simple to test"                | Simple code breaks. Test takes 30 seconds.   |
| "I'll test after"                   | Tests passing immediately prove nothing.     |
| "Already manually tested"           | Ad-hoc is not systematic. Can't re-run.      |
| "Deleting work is wasteful"         | Sunk cost fallacy. Keeping unverified = debt. |
| "This is different because..."      | It's not. Delete code. Start over with TDD.  |

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

### 2b. Spec Compliance Review (Sonnet Subagent)

After the implementer reports completion, spawn a spec compliance reviewer.

**Spec Reviewer Prompt Template:**

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

**If rejected:** Send issues back to implementer subagent → implementer fixes → spec reviewer re-reviews. Loop until approved.

### 2c. Code Quality Review (Opus Subagent)

**Only runs AFTER spec compliance passes.** No point reviewing code quality on code that doesn't meet spec.

**Quality Reviewer Prompt Template:**

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
- Appropriate abstraction level (not too abstract, not too concrete)
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

**If critical issues found:** Implementer fixes → quality reviewer re-reviews. Loop until approved.

### 2d. Incremental Commit

After both reviews pass, evaluate whether to commit:

| Commit when... | Don't commit when... |
|----------------|---------------------|
| Logical unit complete (model, service, component) | Small part of a larger unit |
| Tests pass + meaningful progress | Tests failing |
| About to switch contexts (backend to frontend) | Purely scaffolding with no behavior |
| About to attempt risky/uncertain changes | Would need a "WIP" commit message |

**Heuristic:** "Can I write a commit message that describes a complete, valuable change? If yes, commit. If the message would be 'WIP' or 'partial X', wait."

**Commit workflow:**

```bash
# 1. Verify tests pass
[project test command]

# 2. Stage only files related to this logical unit (NOT git add .)
git add <specific files for this task>

# 3. Commit with conventional message
git commit -m "feat(scope): description of this unit"
```

### 2e. Update Progress

After each task completes:

1. **Mark task completed in TodoWrite** — update status to `completed`
2. **Update plan checkboxes** — use Edit tool to change `- [ ]` to `- [x]` for completed items
3. **Brief progress update** — inform the user what was completed and what's next

---

## Phase 3: Verification Gate

**THE IRON LAW: No completion claims without fresh verification evidence.**

Before claiming all work is done:

### Verification Protocol

1. **IDENTIFY:** What command proves this claim?
   - Full test suite command
   - Linting command
   - Type checking command (if applicable)

2. **RUN:** Execute the FULL command (fresh, not cached)
   ```bash
   # Run the project's full test suite
   # Run linting
   # Run type checks if applicable
   ```

3. **READ:** Full output, check exit code, count any failures
   - Read COMPLETE output — do not skim
   - Check exit code explicitly
   - Count passing vs failing vs skipped tests

4. **VERIFY:** Does output actually confirm the claim?
   - All tests pass (not "most" or "the important ones")
   - No warnings that indicate real issues
   - Linting is clean

5. **ONLY THEN:** Make the claim that work is complete

### Red Flags (Stop Immediately If You Catch Yourself)

- Using "should", "probably", "seems to" about test results
- Expressing satisfaction before running verification
- About to commit without running tests
- Trusting a subagent's success report without checking independently
- Thinking "just this once, I don't need to verify"
- Skipping the full suite because "I only changed one file"
- Assuming cached results are still valid after changes

**If any red flag triggers:** Stop. Run the actual verification. Then proceed.

---

## Phase 4: Ship

### 4.1 Final Commit

```bash
# Verify clean state
git status

# If any uncommitted changes remain
git add <remaining files>
git commit -m "$(cat <<'EOF'
feat(scope): description of what and why

Brief explanation of the complete feature.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 4.2 Push Branch

```bash
git push -u origin feature/$feature_name
```

### 4.3 Create Pull Request

```bash
gh pr create --title "feat(scope): [Description]" --body "$(cat <<'EOF'
## Summary
- What was built and why
- Key decisions made during implementation

## Testing
- Tests added: [count]
- All tests pass: [yes/no with evidence]
- Test coverage: [brief summary of what's covered]

## Implementation Notes
- [Notable implementation decisions]
- [Any deviations from the plan and why]

## Post-Deploy Monitoring
- [What to monitor after deployment]
- [Expected healthy signals]
- [Failure signals and rollback triggers]

## Plan
- Plan: docs/plans/[filename]
- Origin brainstorm: docs/brainstorms/[filename] (if applicable)

---

Built with [flowstate](https://github.com/cr/flowstate) using strict TDD
EOF
)"
```

### 4.4 Update Plan Status

Update the plan's YAML frontmatter:
```
status: active  →  status: completed
```

### 4.5 Notify User

- Summarize what was completed
- Link to PR
- Report test results
- Note any follow-up work needed
- Suggest: "Run `/flowstate:review` for multi-agent code review, or `/flowstate:compound` to capture learnings from this work."

---

## Key Principles

### TDD Is Not Optional

Every task follows RED → GREEN → REFACTOR. No exceptions. The flowstate:tdd skill defines the full enforcement protocol. If you catch yourself writing production code before a test — delete the code and start over.

### Subagents Do Not Self-Certify

The implementer's report is input to the spec reviewer, not evidence of completion. The spec reviewer reads actual code. The quality reviewer only runs after spec compliance. Trust is verified, not assumed.

### Incremental Commits Build Confidence

Small, tested, focused commits are easier to review, easier to revert, and easier to understand. Never batch all changes into a single commit.

### The Plan Is Your Guide, Not Your Prison

Follow the plan, but adapt to reality. If you discover the plan missed something, note it, implement it, and update the plan. If a task is unnecessary, skip it with a note.

### Verification Is The Final Word

No task is done until tests prove it. No feature is done until the full suite passes. No PR is ready until you have fresh evidence of a clean build.

---

## When Things Go Wrong

| Problem | Action |
|---------|--------|
| Baseline tests fail before starting | Stop. Report. Ask user. |
| Implementer can't pass spec review after 2 attempts | Escalate to user. The task spec may need refinement. |
| Quality reviewer flags critical issues after 2 fix attempts | Ask user to triage. Some issues may be deferred. |
| Full suite has unrelated failures | Identify and document. Ask user if pre-existing or caused by changes. |
| Plan task is impossible or contradicts codebase | Report to user. Suggest alternatives. Update plan. |
| Dependency between tasks creates circular requirement | Restructure task order. Ask user to approve revised sequence. |

---

## Reminders

- **Invoke flowstate:tdd** skill rules for every implementation task
- **Invoke flowstate:using-worktrees** skill for workspace isolation
- **"Do not trust the report"** — spec reviewer must read actual code
- **Quality review only after spec passes** — no point polishing wrong code
- **Fresh verification evidence** — no claims without proof
- **Update the plan** as tasks complete — keep it as a living progress document
