---
title: "feat: Add Team Agent Parallel Execution to /workflow:work"
type: feat
status: completed
date: 2026-03-03
detail_level: more
---

# Add Team Agent Parallel Execution to /workflow:work

**Goal:** Enable parallel task execution in `/workflow:work` Phase 2 using Claude Code's team agents pattern with per-task worktree isolation, so independent plan tasks run simultaneously instead of sequentially.

**Architecture:** Wave-based execution model. Plan tasks declare dependencies via `depends_on` fields. A dependency DAG is computed and tasks are grouped into waves (topological layers). Independent tasks within a wave run in parallel as team agent teammates, each in its own git worktree. Reviews remain subagent-dispatched (not teammates). After each wave, worktrees merge sequentially to the feature branch.

**Tech Stack:** Claude Code team agents (TeamCreate, TaskCreate, SendMessage), git worktrees (`isolation: worktree`), existing flowstate skill/command infrastructure.

---

## Overview

Currently `/workflow:work` Phase 2 runs plan tasks **strictly sequentially** — one implementer subagent at a time, with two-stage review after each. The explicit red flag says "Never dispatch multiple implementation subagents in parallel (conflicts)."

With team agents + `isolation: worktree`, we can safely parallelize: each implementer gets its own worktree, eliminating file conflicts. For a 10-task plan where 6 tasks are independent, this cuts wall-clock time by ~50% at roughly the same token cost (work is identical, just concurrent).

The feature is **opt-in and backwards-compatible**: plans without `depends_on` metadata run sequentially (unchanged). Plans with dependency annotations enable wave-based parallel execution.

---

## Research Context

### Relevant Learnings
- [Parallel Subagent Execution Patterns](docs/solutions/best-practices/parallel-subagent-execution-patterns-20260227.md) — 4 parallel Opus agents hit rate limits. Batch by file independence, commit between batches. Cap at 3 simultaneous heavy agents.
- [Model Allocation Strategy](docs/solutions/best-practices/model-allocation-strategy-20260228.md) — Implementers on Sonnet (SWE-bench gap only 1.2pts vs Opus). TDD review loop compensates.

### Existing Patterns
- `skills/subagent-driven-development/SKILL.md` — Current sequential loop with two-stage review. This is the primary file to modify.
- `skills/multi-agent-review/SKILL.md` — Reference pattern for dispatching parallel agents with post-synthesis.
- `skills/compound/SKILL.md` — Reference pattern for 5 parallel sub-agents returning text for assembly.
- `skills/using-worktrees/SKILL.md` — Existing worktree creation/cleanup flow.

### Best Practices (External Research)
- Claude Code team agents: 3-5 teammates optimal, `isolation: worktree` for file conflict prevention
- Teams cost ~2x tokens vs subagents due to full context windows per teammate
- Sequential merge after wave (not mid-wave) is simpler and sufficient for independent tasks
- Reviewers should stay as subagents — review-fix loop is sequential per task, no parallelism gain from making them teammates

### Edge Cases
- Plan with no `depends_on` fields → all tasks sequential (backwards-compatible)
- Wave with >3 tasks → split into sub-waves of 3 (rate limit safety)
- One task fails in a wave → isolate failure, other tasks continue, failed task deferred
- Merge conflict after wave → resolve or ask user, re-run tests
- All tasks in single dependency chain → skip team creation, run sequential

---

## Acceptance Criteria

- [ ] Plans with `depends_on` fields execute independent tasks in parallel via team agents
- [ ] Plans without `depends_on` fields execute identically to current behavior (sequential)
- [ ] Each parallel implementer runs in its own git worktree (no file conflicts)
- [ ] Two-stage review (spec compliance → code quality) still runs per task
- [ ] Maximum 3 implementers per wave (rate limit safety)
- [ ] Worktrees merge cleanly to feature branch after each wave with test verification
- [ ] Failed tasks are isolated (don't block other tasks in the wave)
- [ ] Deferred tasks fall back to sequential execution after all waves complete
- [ ] Team resources cleaned up after execution (TeamDelete, worktree removal)
- [ ] `writing-plans` skill documents the `depends_on` field in its task template

---

## Implementation Tasks

### Task 1: Add `depends_on` Field to Plan Task Template

**Files:**
- Modify: `skills/writing-plans/SKILL.md:116-149` (TDD Task Structure section)
- Modify: `skills/writing-plans/SKILL.md:189-225` (Plan Output Template section)

**Step 1: Write the failing test**

This is a documentation-only change (skill instruction file). No automated test applies.
Manual verification: after editing, confirm the task template shows `depends_on` field.

**Step 2: Add `depends_on` to TDD Task Structure template**

In the task template block (line ~116), add after `### Task N: [Component Name]`:

```markdown
### Task N: [Component Name]

**depends_on:** [Task M, Task K]  <!-- optional: omit for independent tasks -->
```

Add guidance after the template:

```markdown
### Task Dependencies (Optional)

The `depends_on` field enables parallel execution during `/workflow:work`.

- **List dependencies** if a task requires output from earlier tasks (shared files, generated APIs, DB migrations)
- **Omit `depends_on`** if a task touches entirely different files with no shared state — this signals it can run in parallel
- **When ALL tasks omit `depends_on`**, the work phase runs all tasks sequentially (backwards-compatible default)
- **At least one task must have `depends_on`** to trigger parallel wave analysis

Example: In a plan with 5 tasks where Tasks 1-3 are independent and Task 4 depends on Tasks 1+2, Task 5 depends on Task 4:
- Wave 1: Tasks 1, 2, 3 (parallel)
- Wave 2: Task 4 (after 1+2 complete)
- Wave 3: Task 5 (after 4 completes)
```

**Step 3: Add `depends_on` to Plan Output Template**

In the Plan Output Template (line ~219), add the field to the task example.

**Step 4: Verify**

Read the modified file. Confirm `depends_on` appears in both the task structure template and the output template.

**Step 5: Commit**
```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add depends_on field for parallel task execution"
```

---

### Task 2: Create Team Task Execution Skill

**depends_on:** []

**Files:**
- Create: `skills/team-task-execution/SKILL.md`

**Step 1: Write the failing test**

Documentation-only (skill instruction file). Manual verification: after creating, confirm the file parses as valid YAML frontmatter + markdown.

**Step 2: Create the skill file**

Create `skills/team-task-execution/SKILL.md` with:

**YAML Frontmatter:**
```yaml
---
name: skill:team-task-execution
description: >
  Wave-based parallel task execution using team agents with worktree isolation.
  Invoked by subagent-driven-development when plan has parallelizable tasks.
  Spawns up to 3 implementer teammates per wave, each in its own worktree.
  Reviews stay subagent-dispatched. Merges worktrees after each wave.
---
```

**Sections to include:**

**A. Overview** — When this skill is invoked (from SDD skill), what it receives (dependency DAG, task list, feature name, project context), what it produces (completed tasks with merged code).

**B. Cost Guard** — Before creating a team, check: if only 1 parallelizable wave with only 1 task, return immediately and let caller use sequential flow. Parallelism ratio must justify team overhead.

**C. Team Creation Protocol:**
```
1. TeamCreate with name: "work-{feature-name}"
2. For each plan task, TaskCreate with:
   - subject: task title
   - description: full task text
   - addBlockedBy: [dependency task IDs]
3. Team lead = the workflow orchestrator (this session)
```

**D. Per-Wave Execution Loop:**
```
while unfinished tasks exist:
  1. Identify unblocked tasks (TaskList: pending, no blockedBy)
  2. Cap at 3 tasks per wave (split larger sets into sub-waves)
  3. For each task in wave:
     a. Spawn Agent with:
        - team_name: "work-{feature-name}"
        - name: "impl-{task-id}"
        - subagent_type: general-purpose
        - model: sonnet
        - isolation: worktree
        - mode: bypassPermissions
        - Prompt: [implementer template — see section F]
     b. TaskUpdate: owner = "impl-{task-id}", status = in_progress
  4. Monitor: receive SendMessage from implementers
  5. Per completed implementer:
     a. Dispatch spec reviewer SUBAGENT (not teammate) targeting worktree
     b. If APPROVED → dispatch quality reviewer SUBAGENT
     c. If both APPROVED → mark task reviewed
     d. If REJECTED → SendMessage fix instructions to implementer
     e. If 2x rejection → escalate to user, mark task deferred, continue wave
  6. Wave ends when all tasks: approved OR deferred
```

**E. Post-Wave Merge Protocol:**
```
1. Shutdown implementer teammates: SendMessage type shutdown_request
2. For each approved task (in task-ID order):
   a. git merge {task-branch} --no-ff -m "feat(scope): task description"
   b. If merge conflict → attempt auto-resolve, else ask user
   c. Run full test suite on merged result
   d. If tests fail → investigate, fix, re-test
   e. git worktree remove .worktrees/{task-worktree}
3. Build context summary of completed tasks (for next wave's implementers)
4. Update progress: TaskUpdate status=completed, plan checkboxes
```

**F. Implementer Teammate Prompt Template:**

Adapted from the existing implementer prompt in `subagent-driven-development/SKILL.md` with team-specific additions:

```
[Standard implementer template: task text, context, TDD rules, self-review checklist]

## Team Coordination

You are a teammate in a parallel execution team. Additional rules:

1. Work ONLY within your assigned worktree. Do not touch files outside it.
2. When you complete your task, send a message to the team lead:
   SendMessage(type: "message", recipient: "team-lead",
     content: "Task {id} complete. Files: {list}. Tests: {pass/fail count}.",
     summary: "Task {id} implementation complete")
3. If you receive fix instructions from the team lead, apply them and re-report.
4. If you have questions, message the team lead. Do not guess.
5. Follow the same TDD cycle and self-review checklist as a solo implementer.
```

**G. Deferred Task Handling:**
```
After all waves complete:
- Collect deferred tasks
- Execute sequentially using standard SDD flow (existing per-task loop)
- These tasks may have been deferred due to spec review failures
```

**H. Cleanup Protocol:**
```
1. Verify all teammates shut down
2. TeamDelete to remove team config and task files
3. git worktree prune (catch any stale entries)
4. Verify no leftover task branches
```

**I. Red Flags — Never Do:**
- Spawn >3 implementers simultaneously (rate limit danger — see parallel-subagent-execution-patterns learning)
- Make reviewers teammates (unnecessary overhead, review is sequential per task)
- Merge mid-wave while other implementers are still running (merge can change code state)
- Skip test suite after merge (merges can introduce regressions)
- Let implementers message each other (they work on independent tasks; cross-talk wastes tokens)

**Step 3: Verify**

Read the created file. Confirm valid YAML frontmatter, all sections present, prompt templates complete.

**Step 4: Commit**
```bash
git add skills/team-task-execution/SKILL.md
git commit -m "feat(skills): add team-task-execution skill for parallel wave execution"
```

---

### Task 3: Add Execution Mode Selection to SDD Skill

**depends_on:** [Task 2]

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:14-24` (before per-task loop)
- Modify: `skills/subagent-driven-development/SKILL.md:224-237` (Red Flags section)

**Step 1: Write the failing test**

Documentation-only. Manual verification: confirm mode selection section appears before the per-task loop, and parallel dispatch red flag is updated.

**Step 2: Add Execution Mode Selection section**

Insert before the Per-Task Execution Flow (before line 14), after the Two-Stage Review Checkpoint section:

```markdown
## Execution Mode Selection

Before starting the per-task loop, analyze the plan's dependency structure:

1. Parse each task for `depends_on` metadata
2. **If NO tasks have `depends_on`** → **SEQUENTIAL MODE** (default, all tasks run one-by-one in plan order)
3. **If `depends_on` fields exist:**
   a. Build a dependency directed acyclic graph (DAG)
   b. Compute wave layers via topological sort:
      - Wave 1: tasks with no dependencies (or depends_on: [])
      - Wave N: tasks whose dependencies all resolve in waves < N
   c. If any wave has 2+ tasks → invoke **flowstate:team-task-execution** skill with the DAG, task list, feature name, and project context
   d. If every wave has exactly 1 task → **SEQUENTIAL MODE** (no parallelism possible)

**Announce the decision:**
- Sequential: "All tasks are dependent — executing sequentially."
- Parallel: "Found {N} parallelizable waves. Using team agents for parallel execution."

The sequential path below is unchanged. The parallel path is handled entirely by the team-task-execution skill, which returns control after all tasks are complete (or deferred tasks remain for sequential cleanup).
```

**Step 3: Update Red Flags section**

Change line 229 from:
```
- Dispatch multiple implementation subagents in parallel (conflicts)
```
To:
```
- Dispatch multiple implementation subagents in parallel WITHOUT worktree isolation (file conflicts). Parallel execution requires the team-task-execution skill with per-task worktrees.
```

**Step 4: Verify**

Read the modified file. Confirm:
- Mode selection section appears before the per-task loop
- Red flag is updated (not deleted, just clarified)
- Sequential flow is completely untouched

**Step 5: Commit**
```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(sdd): add execution mode selection for parallel wave dispatch"
```

---

### Task 4: Update Work Command for Parallel Awareness

**depends_on:** [Task 3]

**Files:**
- Modify: `commands/workflow/work.md:66-82` (Phase 2 section)
- Modify: `commands/workflow/work.md:165-175` (error table)

**Step 1: Write the failing test**

Documentation-only. Manual verification: confirm Phase 2 mentions both modes, merge verification step exists, error table has new entries.

**Step 2: Update Phase 2 description**

Replace lines 66-82 with:

```markdown
## Phase 2: Per-Task Execution

**Invoke the flowstate:subagent-driven-development skill.**

The skill auto-detects execution mode based on plan dependency metadata:
- **Sequential** (default): Tasks processed one-by-one with two-stage review per task. Used when no `depends_on` fields exist in the plan.
- **Parallel** (wave-based): Independent tasks execute simultaneously via team agents, each in its own git worktree. Used when `depends_on` fields reveal parallelizable task waves.

For parallel mode, the skill internally invokes flowstate:team-task-execution.

For each task (in either mode), the skill handles:
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
```

**Step 3: Add merge verification between Phase 2 and Phase 3**

Insert after Phase 2, before Phase 3:

```markdown
### Phase 2.5: Merge Verification (parallel mode only)

If parallel mode was used, verify the merged feature branch before proceeding:
1. Confirm all task branches have been merged to the feature branch
2. Run full test suite on the merged feature branch
3. If failures exist, investigate whether merge introduced regressions
4. All tests must pass before proceeding to Phase 3
```

**Step 4: Add error table entries**

Add to the "When Things Go Wrong" table:

```markdown
| Merge conflict between parallel task branches | Attempt auto-resolve. If ambiguous, ask user. Re-run tests after resolution. |
| Rate limit during parallel execution | Degrade remaining wave tasks to sequential. Continue. |
| Implementer teammate unresponsive (>5 min) | Timeout, mark task deferred, continue wave. Retry after wave completes. |
| Team creation fails | Fall back to sequential execution for all tasks. |
```

**Step 5: Verify**

Read the modified file. Confirm Phase 2 mentions both modes, Phase 2.5 exists, error table has 4 new entries.

**Step 6: Commit**
```bash
git add commands/workflow/work.md
git commit -m "feat(work): update Phase 2 for parallel execution support"
```

---

### Task 5: Update README with Parallel Execution Note

**depends_on:** [Task 4]

**Files:**
- Modify: `README.md` (workflow description section)

**Step 1: Write the failing test**

Documentation-only. Manual verification: README mentions parallel execution capability.

**Step 2: Add note to workflow description**

In the `/workflow:work` description, add a brief note about parallel execution:

```markdown
Supports wave-based parallel execution via team agents when plan tasks declare
dependencies. Independent tasks run simultaneously in isolated worktrees.
```

**Step 3: Verify**

Read README.md. Confirm the note appears in the work command description.

**Step 4: Commit**
```bash
git add README.md
git commit -m "docs: note parallel execution support in workflow:work"
```

---

### Task 6: Bump Version

**depends_on:** [Task 5]

**Files:**
- Modify: `.claude-plugin/plugin.json` (version field)

**Step 1: Bump version from 0.4.2 to 0.5.0**

This is a feature addition (new capability), warranting a minor version bump.

**Step 2: Commit**
```bash
git add .claude-plugin/plugin.json
git commit -m "chore: bump version to 0.5.0"
```

---

## Sources
- Team agents research: Claude Code official docs, Addy Osmani deep dive, Qodo benchmark analysis
- Learnings: `docs/solutions/best-practices/parallel-subagent-execution-patterns-20260227.md`
- Learnings: `docs/solutions/best-practices/model-allocation-strategy-20260228.md`
- Existing patterns: `skills/subagent-driven-development/SKILL.md`, `skills/multi-agent-review/SKILL.md`
