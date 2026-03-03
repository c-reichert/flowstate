---
name: skill:team-task-execution
description: >
  Wave-based parallel task execution using team agents with worktree isolation.
  Invoked by subagent-driven-development when plan has parallelizable tasks.
  Spawns up to 3 implementer teammates per wave, each in its own worktree.
  Reviews stay subagent-dispatched. Merges worktrees after each wave.
---

# Team Task Execution

## Overview

Execute plan tasks in parallel using Claude Code's team agents pattern. This skill is invoked by the subagent-driven-development skill when dependency analysis reveals parallelizable waves.

**Receives from caller:**
- Dependency DAG (tasks with `depends_on` relationships)
- Full task list with task text
- Feature name (for team/branch naming)
- Project context (CLAUDE.md, architecture, previous task summaries)

**Produces:**
- Completed tasks with code merged to the feature branch
- Deferred tasks list (if any failed review and need sequential retry)

**Announce:** "Using team agents for parallel execution. {N} waves identified, up to 3 implementers per wave."

---

## Cost Guard

Before creating a team, verify parallelism justifies the overhead:

1. Count total parallelizable tasks (waves with 2+ tasks)
2. If only 1 parallelizable wave with only 1 task → **return immediately**, let caller use sequential flow
3. If parallelism ratio (parallelizable tasks / total tasks) < 0.3 → warn user: "Limited parallelism ({ratio}). Proceed with team agents or fall back to sequential?"

Team overhead is ~10-15% additional tokens for TeamCreate, TaskCreate, SendMessage, and merge operations. Only worth it when 2+ tasks genuinely run simultaneously.

---

## Team Creation Protocol

```
1. TeamCreate:
   - team_name: "work-{feature-name}"

2. For each plan task, TaskCreate:
   - subject: "Task {id}: {title}"
   - description: full task text (pasted, never file-referenced)
   - activeForm: "Implementing {title}"

3. Set dependencies via TaskUpdate:
   - For each task with depends_on: addBlockedBy with the IDs of dependency tasks

4. Team lead = this session (the workflow orchestrator)
```

---

## Per-Wave Execution Loop

```
while unfinished tasks exist in TaskList:

  Step 1: Identify unblocked tasks
    - TaskList → find tasks with status: pending, no blockedBy
    - These form the current wave

  Step 2: Cap wave size
    - Maximum 3 tasks per wave
    - If more than 3 unblocked: take first 3 (by task ID order)
    - Remaining unblocked tasks wait for next iteration

  Step 3: Spawn implementer teammates
    For each task in wave (up to 3):

      Spawn via Agent tool with:
        - team_name: "work-{feature-name}"
        - name: "impl-{task-id}"
        - subagent_type: general-purpose
        - model: sonnet
        - isolation: worktree
        - mode: bypassPermissions
        - Prompt: [Implementer Teammate Template — see below]

      TaskUpdate:
        - taskId: {task-id}
        - owner: "impl-{task-id}"
        - status: in_progress

  Step 4: Monitor implementer progress
    - Teammates send messages when they complete their task
    - Messages arrive automatically (no polling needed)
    - Wait for implementers to report completion

  Step 5: Review completed tasks
    For each implementer that reports completion:

      a. Dispatch SPEC COMPLIANCE reviewer as a SUBAGENT (not teammate):
         - Model: Sonnet
         - Target: the implementer's worktree path
         - Prompt: standard spec reviewer template from subagent-driven-development skill
         - Input: full task spec + worktree path to read actual code from

      b. If spec review APPROVED:
         Dispatch CODE QUALITY reviewer as a SUBAGENT:
         - Model: Sonnet
         - Prompt: standard quality reviewer template
         - Input: list of files modified in the worktree

      c. If both APPROVED:
         Mark task as reviewed and ready for merge

      d. If REJECTED (spec or quality):
         Send fix instructions to implementer teammate via SendMessage:
         - type: "message"
         - recipient: "impl-{task-id}"
         - content: reviewer feedback with specific file:line issues
         - summary: "Review feedback for task {id}"
         Implementer applies fixes and re-reports completion

      e. If 2x rejection on same review stage:
         - Escalate to user: "Task {id} failed {review-type} review twice. Issues: {details}"
         - Mark task as DEFERRED
         - Continue processing other tasks in the wave (do NOT block)

  Step 6: Wave completion
    Wave ends when all tasks in the wave are either:
    - Reviewed and approved (ready for merge)
    - Deferred (failed review, will retry sequentially later)
```

---

## Post-Wave Merge Protocol

After all tasks in a wave are resolved (approved or deferred):

```
Step 1: Shutdown implementer teammates
  For each implementer in this wave:
    SendMessage:
      - type: "shutdown_request"
      - recipient: "impl-{task-id}"
      - content: "Wave complete, shutting down"
  Wait for shutdown confirmations

Step 2: Merge approved tasks to feature branch
  For each approved task (in task-ID order):

    a. Merge the task worktree branch:
       git merge {task-branch} --no-ff -m "feat({scope}): {task description}"

    b. If merge conflict:
       - Attempt auto-resolution for trivial conflicts
       - If ambiguous, ask user to resolve
       - After resolution, stage and commit the merge

    c. Run full test suite on merged result:
       - If tests pass → continue to next task merge
       - If tests fail → investigate, fix, re-test
       - If unfixable → ask user

    d. Clean up:
       git worktree remove .worktrees/{task-worktree}

Step 3: Build context summary
  Create a summary of all completed tasks for next wave's implementers:
  - Which tasks completed (IDs + titles)
  - Which files were created/modified
  - Key patterns established (imports, naming, structure)
  - Any conventions that emerged

Step 4: Update progress
  For each merged task:
    - TaskUpdate: status = completed
    - Update plan checkboxes: - [ ] → - [x]
    - Brief user update: "Wave {N} complete: {task summaries}"
```

---

## Implementer Teammate Prompt Template

Adapted from the standard implementer prompt in `subagent-driven-development/SKILL.md` with team-specific coordination instructions:

```
You are implementing a task from a plan as part of a parallel execution team.
Follow TDD strictly.

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

Cycle for this task:
1. RED: Write the failing test exactly as specified in the task
2. VERIFY RED: Run the test. Confirm it fails for the RIGHT reason
3. GREEN: Write MINIMAL implementation to pass the test
4. VERIFY GREEN: Run the test. Confirm pass. Run full suite — no regressions.
5. REFACTOR: Clean up if needed. Verify tests still pass.

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

## Team Coordination

You are a teammate in a parallel execution team. Additional rules:

1. Work ONLY within your assigned worktree. Do not touch files outside it.
2. When you complete your task, report to the team lead:
   - Use SendMessage with type: "message", recipient: the team lead name
   - Include: "Task {id} complete. Files created/modified: {list}. Tests: {pass/fail count}."
3. If you receive fix instructions from the team lead, apply them and re-report completion.
4. If you have questions, message the team lead. Do not guess or make assumptions.
5. Do NOT message other implementers. Your task is independent of theirs.
6. Commit your work within your worktree before reporting completion.

## Learnings to Apply
[Any relevant docs/solutions/ references for this task]
```

---

## Deferred Task Handling

After all waves complete:

```
1. Collect deferred tasks (failed review 2x during parallel execution)
2. If none → skip to Cleanup
3. Execute deferred tasks SEQUENTIALLY using the standard subagent-driven-development
   per-task loop (existing flow):
   - Dispatch implementer subagent
   - Spec compliance review
   - Code quality review
   - Incremental commit
4. These tasks run on the feature branch (already has all wave merges)
5. If deferred tasks also fail sequentially → escalate to user
```

---

## Cleanup Protocol

After all tasks (waves + deferred) complete:

```
1. Verify all teammates have shut down
   - Check that no Agent processes are still running
   - If any linger, send additional shutdown_request

2. TeamDelete to remove team config and task files
   - Removes ~/.claude/teams/work-{feature-name}/
   - Removes ~/.claude/tasks/work-{feature-name}/

3. Clean up git state
   - git worktree prune (catch any stale entries)
   - git worktree list (verify only main worktree remains)
   - Verify no leftover task branches:
     git branch | grep "task-" (should be empty after merges)

4. Return control to the calling skill (subagent-driven-development)
   - Report: completed task count, deferred task count, total waves executed
```

---

## Red Flags — Never Do

- Spawn >3 implementers simultaneously (rate limit danger — see `docs/solutions/best-practices/parallel-subagent-execution-patterns-20260227.md`)
- Make reviewers teammates (unnecessary overhead; review-fix loop is sequential per task)
- Merge mid-wave while other implementers are still running (merge changes code state that other worktrees branched from)
- Skip test suite after merge (merges can introduce regressions even with independent files)
- Let implementers message each other (independent tasks; cross-talk wastes tokens and creates confusion)
- Skip the cost guard (creating a team for 1 parallelizable task adds overhead with zero benefit)
- Forget to shut down teammates before TeamDelete (TeamDelete fails with active members)
- Use `git merge` without `--no-ff` (fast-forward merges lose the per-task commit boundary)
