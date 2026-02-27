---
date: 2026-02-27
topic: flowstate-plugin
status: active
origin: brainstorming session
---

# Flowstate: A Hybrid Claude Code Plugin

## What We're Building

A Claude Code plugin called **flowstate** that combines the best elements of two existing plugins:

- **Superpowers** (obra, 55.9k stars): TDD enforcement, guided brainstorming, git worktree isolation, subagent-per-task execution
- **Compound Engineering** (Every/Kieran Klaassen, 9.5k stars): Knowledge compounding, learnings persistence via `docs/solutions/`, parallel multi-agent review, plan deepening

The goal: a unified development workflow where every cycle produces not just working code, but accumulated knowledge that makes the next cycle easier.

## Why This Approach

**Superpowers** excels at discipline — strict TDD, guided brainstorming, worktree isolation — but all session learning is lost when the session ends. There is no mechanism to carry insights forward.

**Compound Engineering** excels at knowledge persistence — `docs/solutions/`, learnings-researcher, critical patterns — but lacks the strict TDD enforcement and guided brainstorming flow that makes Superpowers effective at producing quality code.

Neither plugin alone delivers both. Flowstate combines strict development discipline with compounding knowledge.

## Key Decisions

- **Plugin name**: `flowstate` — commands prefixed as `/flowstate:brainstorm`, `/flowstate:work`, etc.
- **Architecture**: Monolithic plugin (single install, integrated loop) — not modular skills
- **Target platform**: Claude Code only
- **Language**: Language-agnostic — test runner and conventions configured per project
- **TDD enforcement**: Skill-instructed (strong prompt language, rationalization defense) — no hooks for now, upgradeable later
- **Review agents**: 5 core by default + `/flowstate:deep-review` for full 14+ swarm
- **Compound trigger**: Manual `/flowstate:compound` — user decides when to capture learnings
- **Worktrees**: Built-in, auto-created at start of work phase (after plan approval)
- **Knowledge store**: `docs/solutions/` with YAML frontmatter, searchable by learnings-researcher agent
- **CLAUDE.md**: NOT auto-modified — learnings live in `docs/solutions/`; user can promote critical patterns to `docs/solutions/patterns/critical-patterns.md` via decision menu
- **Model strategy**: Opus-heavy for quality; Haiku only for mechanical tasks

---

## The Core Loop

```
Brainstorm → Plan → [Deepen Plan] → Work (TDD + Worktree) → Review → Compound
```

| Step | Command | Trigger |
|------|---------|---------|
| 1. Brainstorm | `/flowstate:brainstorm` | Manual |
| 2. Plan | `/flowstate:plan` | Auto after brainstorm, or manual |
| 3. Deepen Plan | `/flowstate:deepen-plan` | Optional, manual |
| 4. Work | `/flowstate:work` | Manual |
| 5. Review | `/flowstate:review` | Manual |
| 5b. Deep Review | `/flowstate:deep-review` | Manual (full swarm) |
| 6. Compound | `/flowstate:compound` | Manual |

Steps 1→2 chain automatically. All other steps are explicit.

---

## Step 1: Brainstorm (`/flowstate:brainstorm`)

### Purpose

Turn a rough idea into a validated design through guided dialogue. Prevent premature implementation.

### Sources

- Brainstorming flow: Superpowers `brainstorming` skill (hard gate, one-question-at-a-time, task checklist)
- Repo research + structured output: Compound Engineering `/workflows:brainstorm` (Phase 0 skip gate, AskUserQuestion enforcement, What/Why/Decisions/OpenQuestions template)
- Enforcement: Anthropic prompting research (AskUserQuestion as structural enforcement > guideline-based)

### Flow

```
Phase 0: ASSESS CLARITY
         If requirements are already detailed (specific acceptance criteria,
         referenced patterns, exact expected behavior):
         → Offer to skip brainstorm and go directly to /flowstate:plan
         This is a skip gate, not a bypass — user must confirm.

Phase 1: LIGHTWEIGHT REPO RESEARCH
         Before asking questions, run a quick scan:
         - Existing patterns related to the feature
         - Similar implementations in the codebase
         - CLAUDE.md guidance and conventions
         This informs the questions we ask.
         Model: Sonnet (repo-research-analyst subagent)

Phase 2: COLLABORATIVE DIALOGUE
         Ask questions ONE AT A TIME using AskUserQuestion tool.
         - Prefer multiple choice when natural options exist
         - Start broad (purpose, users, constraints) then narrow (edge cases, error handling)
         - Validate assumptions explicitly
         - Ask about success criteria
         Continue until the idea is clear OR user says "proceed."

Phase 3: PROPOSE APPROACHES
         Present 2-3 different approaches with trade-offs.
         Lead with recommended option and explain why.
         Get user selection.

Phase 4: PRESENT DESIGN
         Present section by section, scaled to complexity:
         - Architecture, components, data flow
         - Error handling, testing approach
         - A few sentences if straightforward, up to 200-300 words if nuanced
         Ask after each section: "Does this look right so far?"

Phase 5: RESOLVE OPEN QUESTIONS (HARD GATE)
         Before proceeding, check for any Open Questions captured during dialogue.
         ALL open questions must be resolved via AskUserQuestion.
         Move resolved questions to a "Resolved Questions" section.
         Do NOT proceed to Phase 6 with unresolved questions.

Phase 6: SAVE DESIGN DOC
         Write to: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md
         Commit to git.

Phase 7: TRANSITION
         Offer options via AskUserQuestion:
         1. Proceed to planning → invoke /flowstate:plan (auto-detects brainstorm)
         2. Review and refine → improve the document
         3. Ask more questions → return to Phase 2
         4. Done for now → return later
```

### Hard Gate

```
<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until you have presented a design and the
user has approved it. This applies to EVERY project regardless of perceived
simplicity.
</HARD-GATE>
```

### Anti-Pattern Warning

Every project goes through brainstorming. A todo list, a single-function utility, a config change. "Simple" projects are where unexamined assumptions waste the most time. The design can be short, but it must exist and be approved.

### Output Template

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## What We're Building
[Concise description — 1-2 paragraphs max]

## Why This Approach
[Approaches considered and why this one was chosen]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Any unresolved questions for the planning phase]

## Resolved Questions
- [Question]: [Resolution]

## Next Steps
→ `/flowstate:plan` for implementation details
```

### Model

Orchestrator: Opus (inherited). Repo research subagent: Sonnet.

---

## Step 2: Plan (`/flowstate:plan`)

### Purpose

Transform a brainstorm into an actionable implementation plan with TDD-structured tasks, informed by past learnings.

### Sources

- Research agents + brainstorm carryforward + detail levels: Compound Engineering `/workflows:plan`
- TDD task structure + exact code + 2-5 min granularity: Superpowers `writing-plans` skill
- Learnings integration: Compound Engineering `learnings-researcher` agent
- Edge case analysis: Compound Engineering `spec-flow-analyzer` agent

### Flow

```
Phase 0: AUTO-DETECT BRAINSTORM
         Search docs/brainstorms/ for recent documents matching this feature.
         Relevance criteria:
         - Topic (filename or YAML frontmatter) semantically matches
         - Created within last 14 days
         - If multiple matches, use most recent

         If found:
         - Read thoroughly — every section matters
         - Announce: "Found brainstorm from [date]: [topic]. Using as foundation."
         - Extract ALL key decisions, rationale, constraints, success criteria
         - Skip idea refinement — brainstorm already answered WHAT to build
         - Reference decisions with: (see brainstorm: docs/brainstorms/<filename>)

         If not found:
         - Run lightweight idea refinement via AskUserQuestion

Phase 1: PARALLEL LOCAL RESEARCH
         Spawn in parallel:
         ├── learnings-researcher (Haiku)
         │   Search docs/solutions/ for relevant past solutions.
         │   Grep-first filtering: extract keywords → parallel grep calls
         │   → filter by frontmatter (module, tags, symptoms, root_cause)
         │   → full read of strong/moderate matches only
         │   Always check docs/solutions/patterns/critical-patterns.md
         │
         └── repo-research-analyst (Sonnet)
             Find existing patterns, CLAUDE.md guidance, similar implementations.

Phase 2: CONDITIONAL EXTERNAL RESEARCH
         Decision tree:
         - High-risk topics (security, payments, external APIs) → ALWAYS research
         - Strong local context (good patterns, CLAUDE.md, familiar tech) → skip
         - Uncertainty or new territory → research

         If research needed, spawn in parallel:
         ├── best-practices-researcher (Sonnet)
         │   Current industry standards and real-world examples
         │
         └── framework-docs-researcher (Haiku)
             Framework/library documentation via Context7 MCP

Phase 3: SPEC-FLOW ANALYSIS
         Spawn spec-flow-analyzer (Opus):
         - Map all user flows and permutations
         - Identify missing error handling
         - Find edge cases and ambiguities
         - Validate acceptance criteria

Phase 4: CONSOLIDATE RESEARCH
         Merge all agent outputs:
         - Relevant file paths from repo: path/to/file.py:42
         - Institutional learnings from docs/solutions/ with key insights
         - External documentation URLs and best practices
         - Edge cases discovered by spec-flow-analyzer
         - CLAUDE.md conventions

Phase 5: WRITE PLAN
         Choose detail level based on complexity:

         MINIMAL (quick fix, small bug):
         - Brief description + acceptance criteria + context + MVP code

         MORE (standard feature):
         - MINIMAL + background + technical considerations + implementation suggestions
         - System-wide impact analysis (callbacks, error propagation, state lifecycle)

         A LOT (complex feature, architectural change):
         - MORE + detailed implementation phases + alternatives considered
         - Risk mitigation + documentation requirements

         REGARDLESS of detail level, each implementation task follows TDD structure:

         ### Task N: [Component Name]

         **Files:**
         - Create: `exact/path/to/file.py`
         - Modify: `exact/path/to/existing.py:123-145`
         - Test: `tests/exact/path/to/test.py`

         **Step 1: Write the failing test**
         ```python
         def test_specific_behavior():
             result = function(input)
             assert result == expected
         ```

         **Step 2: Run test to verify it fails**
         Run: `pytest tests/path/test.py::test_name -v`
         Expected: FAIL with "function not defined"

         **Step 3: Write minimal implementation**
         ```python
         def function(input):
             return expected
         ```

         **Step 4: Run test to verify it passes**
         Run: `pytest tests/path/test.py::test_name -v`
         Expected: PASS

         **Step 5: Commit**
         ```bash
         git add tests/path/test.py src/path/file.py
         git commit -m "feat: add specific feature"
         ```

         Include learnings references where relevant:
         "Avoid X pattern — see docs/solutions/performance-issues/n-plus-one-fix.md"

Phase 6: SAVE PLAN
         Write to: docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md
         Commit to git.

Phase 7: OFFER OPTIONS
         Via AskUserQuestion:
         1. Run /flowstate:deepen-plan — enhance with parallel research
         2. Start /flowstate:work — begin implementation
         3. Review and refine — improve the plan
         4. Done for now — return later
```

### Output Template

```markdown
---
title: [Plan Title]
type: [feat|fix|refactor]
status: active
date: YYYY-MM-DD
origin: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md
detail_level: [minimal|more|a_lot]
---

# [Plan Title]

## Overview
[Problem/feature description]

## Research Context

### Relevant Learnings
- [Title] (docs/solutions/[category]/[file].md) — [key insight]

### Existing Patterns
- [file:line] — [what pattern to follow]

### Best Practices
- [recommendation from research]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Tasks

### Task 1: [Component]
[TDD-structured steps as above]

### Task 2: [Component]
[TDD-structured steps as above]

## Edge Cases
[From spec-flow-analyzer]

## Sources
- Brainstorm: docs/brainstorms/[file]
- Learnings: docs/solutions/[files]
- External: [URLs]
```

### Models

Orchestrator: Opus. Subagents: see model table in Key Decisions.

---

## Step 3: Deepen Plan (`/flowstate:deepen-plan`) — Optional

### Purpose

Enhance an existing plan with parallel research agents per section. For when you want more depth, best practices, and implementation details before starting work.

### Sources

- Compound Engineering `/deepen-plan` (parallel skill discovery, section-by-section enhancement, Context7, web search)

### Flow

```
Phase 1: PARSE PLAN STRUCTURE
         Extract: overview, solution sections, technical approach,
         implementation phases, code examples, technologies mentioned.
         Create section manifest.

Phase 2: PARALLEL RESEARCH (per section)
         For each section, spawn research agent (Sonnet):
         - Industry standards and conventions
         - Performance considerations
         - Common pitfalls and how to avoid them
         - Concrete code examples

         Also query:
         - Context7 MCP for framework documentation
         - Web search for current best practices (2025-2026)

Phase 3: LEARNINGS DISCOVERY
         Search docs/solutions/ for relevant documented learnings.
         Grep-first filter → read frontmatter → score relevance → full read.
         Spawn subagent per relevant learning (Haiku).

Phase 4: ENHANCE PLAN SECTIONS
         For each section, add:

         ### Research Insights

         **Best Practices:**
         - [Concrete recommendation]

         **Performance Considerations:**
         - [Optimization opportunity]

         **Edge Cases:**
         - [Edge case and handling strategy]

         **References:**
         - [Documentation URL]

Phase 5: ADD ENHANCEMENT SUMMARY
         At top of plan:

         ## Enhancement Summary
         **Deepened on:** [Date]
         **Sections enhanced:** [Count]
         **Key Improvements:**
         1. [Major improvement]
         2. [Major improvement]

Phase 6: UPDATE PLAN FILE
         Preserve original filename. Update in place.
```

### What This Does NOT Do

- Does NOT run review agents (save for `/flowstate:review`)
- Does NOT rewrite the plan — only adds research context
- Does NOT replace existing content — only enhances

### Models

Research agents: Sonnet. Learnings subagents: Haiku.

---

## Step 4: Work (`/flowstate:work`)

### Purpose

Execute the plan task-by-task with strict TDD discipline, worktree isolation, subagent-per-task dispatch, and two-stage review.

### Sources

- TDD enforcement + rationalization defense: Superpowers `test-driven-development` skill
- Subagent dispatch + two-stage review: Superpowers `subagent-driven-development` skill
- Verification before completion: Superpowers `verification-before-completion` skill
- Worktree creation + incremental commits + PR creation: Compound Engineering `/workflows:work`

### Flow

```
Phase 1: SETUP
         1. Read the plan document completely
         2. If anything is unclear, ask clarifying questions NOW
         3. Create git worktree:
            git worktree add .worktrees/<feature> -b feature/<feature-name>
         4. Install dependencies in worktree
         5. Run tests to verify clean baseline (all green before we start)
         6. Create TodoWrite with all tasks from plan

Phase 2: PER-TASK EXECUTION LOOP

         For each task:

         2a. DISPATCH IMPLEMENTER (Opus subagent)
             Provide:
             - Full task text (pasted, not file reference)
             - Context: where this fits, dependencies, architecture
             - TDD instructions (see TDD Enforcement below)

             Implementer executes:
             ├── RED: Write failing test
             ├── VERIFY RED: Run test, confirm failure for RIGHT reason
             │   (feature missing, not typo/syntax error)
             ├── GREEN: Write MINIMAL implementation to pass test
             ├── VERIFY GREEN: Run test, confirm pass + no regressions
             ├── REFACTOR: Clean up if needed, verify still green
             └── Self-review: completeness, quality, YAGNI, patterns

         2b. SPEC COMPLIANCE REVIEW (Sonnet subagent)
             - Reads ACTUAL CODE, not implementer's report
             - Compares implementation to task spec line by line
             - Checks for missing pieces AND extra features
             - Returns: ✅ or ❌ with file:line references
             - If ❌: implementer fixes → spec reviewer re-reviews

             CRITICAL: "Do not trust the report. The implementer finished
             suspiciously quickly. Read the actual code."

         2c. CODE QUALITY REVIEW (Opus subagent)
             - Only runs AFTER spec compliance passes
             - Reviews: cleanliness, testing, maintainability
             - Returns: Strengths, Issues (Critical/Important/Minor), Assessment
             - If Critical issues: implementer fixes → re-review

         2d. INCREMENTAL COMMIT
             Evaluate: "Can I write a commit message that describes a complete,
             valuable change? If yes, commit. If message would be 'WIP', wait."

             When committing:
             - Verify tests pass
             - Stage only files related to this logical unit (not git add .)
             - Conventional commit message: feat(scope): description

         2e. UPDATE PROGRESS
             - Mark task completed in TodoWrite
             - Update plan checkboxes: [ ] → [x]

Phase 3: VERIFICATION GATE

         Before claiming work is done:

         THE IRON LAW: No completion claims without fresh verification evidence.

         1. IDENTIFY: What command proves this claim?
         2. RUN: Execute the FULL command (fresh, not cached)
         3. READ: Full output, check exit code, count failures
         4. VERIFY: Does output actually confirm the claim?
         5. ONLY THEN: Make the claim

         RED FLAGS (stop immediately if you catch yourself):
         - Using "should", "probably", "seems to"
         - Expressing satisfaction before running verification
         - About to commit without running tests
         - Trusting a subagent's success report without checking
         - Thinking "just this once"

Phase 4: SHIP
         1. Final commit with conventional message
         2. Push branch
         3. Create PR with:
            - Summary of what was built and why
            - Testing performed
            - Post-deploy monitoring plan (if applicable)
         4. Update plan status: active → completed
         5. Notify user with PR link
```

### TDD Enforcement

```
THE IRON LAW:
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Write code before the test? Delete it. Start over.
No exceptions:
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

COMMON RATIONALIZATIONS (all invalid):
| Excuse                              | Reality                                      |
|-------------------------------------|----------------------------------------------|
| "Too simple to test"               | Simple code breaks. Test takes 30 seconds.   |
| "I'll test after"                  | Tests passing immediately prove nothing.     |
| "Tests after achieve same goals"   | Tests-after = "what does this do?"           |
|                                     | Tests-first = "what should this do?"         |
| "Already manually tested"          | Ad-hoc is not systematic. Can't re-run.      |
| "Deleting X hours is wasteful"     | Sunk cost fallacy. Keeping unverified = debt. |
| "Keep as reference"                | You'll adapt it. That's testing after.        |
| "Test hard = design unclear"       | Hard to test = hard to use. Listen to test.  |
| "TDD will slow me down"            | TDD is faster than debugging.                |
| "This is different because..."     | It's not. Delete code. Start over with TDD.  |

VERIFICATION CHECKLIST (before marking task done):
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.
```

### Subagent Prompt Templates

Subagent prompts are inlined in `skills/subagent-driven-development/SKILL.md`.

### Models

Orchestrator: Opus. Implementer: Opus. Spec reviewer: Sonnet. Code quality reviewer: Opus.

---

## Step 5: Review (`/flowstate:review`)

### Purpose

Catch issues before they ship AND surface past learnings relevant to this change.

### Sources

- Parallel agent spawning + severity-based findings + todo files: Compound Engineering `/workflows:review`
- Receiving-code-review protocol + pushback + YAGNI check: Superpowers `receiving-code-review` skill
- Verification before completion: Superpowers `verification-before-completion` skill

### The 5 Core Reviewers

| Agent | Focus | Model |
|-------|-------|-------|
| `security-reviewer` | OWASP top 10, injection, auth flaws, secrets in code | Opus |
| `performance-reviewer` | Algorithmic complexity, N+1 queries, caching, memory | Opus |
| `simplicity-reviewer` | YAGNI violations, unnecessary abstractions, readability | Sonnet |
| `architecture-reviewer` | Component boundaries, dependency direction, separation of concerns | Opus |
| `pattern-reviewer` | Anti-patterns, code smells, naming consistency, duplication | Sonnet |

Plus `learnings-researcher` (Haiku) always runs alongside to surface relevant past solutions.

### Flow

```
Phase 1: SPAWN REVIEWERS IN PARALLEL
         All 5 core reviewers + learnings-researcher run simultaneously.
         Each reviewer receives: PR diff, file context, CLAUDE.md conventions.

Phase 2: SYNTHESIZE FINDINGS
         Collect all agent outputs. For each finding:
         - Assign severity: P1 (blocks merge) / P2 (should fix) / P3 (nice to have)
         - Deduplicate overlapping findings
         - Flag learnings-researcher matches as "Known Pattern" with links
         - Estimate effort: Small / Medium / Large

Phase 3: CREATE TODO FILES
         For each finding, create:
         todos/{id}-pending-{priority}-{description}.md

         Todo structure:
         ---
         status: pending
         priority: p1|p2|p3
         issue_id: NNN
         tags: [code-review, ...]
         ---
         ## Problem Statement
         ## Findings (with evidence and file:line)
         ## Proposed Solutions (2-3 options with pros/cons)
         ## Acceptance Criteria

Phase 4: PRESENT SUMMARY
         ## Code Review Complete

         **Findings Summary:**
         - Total: [X]
         - P1 CRITICAL (blocks merge): [count]
         - P2 IMPORTANT (should fix): [count]
         - P3 NICE-TO-HAVE: [count]

         **Created Todo Files:**
         [list by severity]

         **Next Steps:**
         1. Address P1 findings (MUST fix before merge)
         2. Triage P2/P3 findings
         3. Run /flowstate:compound to capture learnings

Phase 5: RESOLVE FINDINGS
         Fix P1s immediately. Triage P2/P3 with user.
         After fixing, re-run affected reviewers to verify.
```

### Receiving Review Feedback Protocol

When applying review findings:
1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate the issue in your own words
3. VERIFY: Check against actual codebase — is this accurate?
4. EVALUATE: Is this technically sound for THIS codebase?
5. RESPOND: Fix it, or push back with technical reasoning
6. IMPLEMENT: One item at a time, test each fix

**Push back when:**
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature being "improved")
- Technically incorrect for this stack

**YAGNI check:** Before implementing a reviewer's suggestion, grep for actual usage. If unused, don't "improve" dead code — remove it.

### `/flowstate:deep-review`

Extends to 14+ agents. Additional reviewers are configured per project and can include:
- Language-specific reviewers (Python, TypeScript, Rails, etc.)
- Data integrity guardian
- Data migration expert
- Deployment verification agent
- Schema drift detector
- Frontend race condition reviewer
- Agent-native reviewer

Conditional agents trigger based on PR content:
- DB migrations present → data integrity + schema drift + deployment verification
- Frontend changes → frontend race condition reviewer
- Agent/tool changes → agent-native reviewer

### Models

Core reviewers: see table above. Deep-review extras: Sonnet.

---

## Step 6: Compound (`/flowstate:compound`)

### Purpose

Capture what you learned from the current work cycle as searchable, reusable documentation. This is the step that makes every future cycle easier.

### Sources

- Compound Engineering `/workflows:compound` (5 parallel subagents, YAML schema, decision menu, critical pattern promotion)
- Compound Engineering `compound-docs` skill (resolution template, critical-pattern template)

### Flow

```
Phase 1: PARALLEL CAPTURE (5 subagents)

         ├── Context Analyzer (Haiku)
         │   Extract: problem type, component, symptoms
         │   Return: YAML frontmatter skeleton
         │
         ├── Solution Extractor (Opus)
         │   Analyze: investigation steps, what worked, what didn't
         │   Return: root cause, solution with code examples
         │
         ├── Related Docs Finder (Haiku)
         │   Search: docs/solutions/ for related documentation
         │   Return: links to related solutions
         │
         ├── Prevention Strategist (Opus)
         │   Develop: prevention strategies, best practices
         │   Return: how to avoid this class of problem in future
         │
         └── Category Classifier (Haiku)
             Determine: optimal directory category
             Validate: against schema
             Return: category + filename suggestion

         All agents return TEXT ONLY — no files written.

Phase 2: ASSEMBLE AND WRITE
         Orchestrator collects all text results.
         Validates YAML frontmatter against schema.
         Creates directory: mkdir -p docs/solutions/[category]/
         Writes single file: docs/solutions/[category]/[filename].md

Phase 3: DECISION MENU
         Present via AskUserQuestion:

         1. Continue workflow (recommended)
         2. Add to Required Reading — promote to critical-patterns.md
         3. Link related documentation
         4. View documentation
         5. Other

         If severity is critical, affects multiple modules, or solution is non-obvious:
         → Suggest "This might be worth adding to Required Reading (Option 2)"
         → But NEVER auto-promote. User decides.

Phase 4: CRITICAL PATTERN PROMOTION (if user selects Option 2)
         Extract pattern from documentation.
         Format as:

         ## N. [Pattern Name]

         ### WRONG ([Will cause X error])
         ```[language]
         [code showing wrong approach]
         ```

         ### CORRECT
         ```[language]
         [code showing correct approach]
         ```

         **Why:** [Technical explanation]
         **Documented in:** docs/solutions/[category]/[filename].md

         Append to: docs/solutions/patterns/critical-patterns.md
         This file is ALWAYS checked by learnings-researcher before any work.
```

### YAML Schema (Language-Agnostic)

```yaml
module: string          # Module or area (e.g., "Authentication", "API Layer")
date: string            # YYYY-MM-DD
problem_type: enum
  - build_error
  - test_failure
  - runtime_error
  - performance_issue
  - database_issue
  - security_issue
  - ui_bug
  - integration_issue
  - logic_error
  - developer_experience
  - workflow_issue
  - best_practice
  - documentation_gap

symptoms:               # 1-5 observable symptoms
  - string

root_cause: string      # Free-text (language-agnostic, not enum)

resolution_type: enum
  - code_fix
  - config_change
  - test_fix
  - dependency_update
  - environment_setup
  - workflow_improvement
  - documentation_update

severity: enum
  - critical            # Blocks production/development, data loss
  - high                # Impairs core functionality, security issue
  - medium              # Affects specific feature, performance
  - low                 # Minor issue, edge case

tags:                   # 1-8 searchable keywords
  - string
```

### Category Mapping

```
problem_type → directory:
build_error         → docs/solutions/build-errors/
test_failure        → docs/solutions/test-failures/
runtime_error       → docs/solutions/runtime-errors/
performance_issue   → docs/solutions/performance-issues/
database_issue      → docs/solutions/database-issues/
security_issue      → docs/solutions/security-issues/
ui_bug              → docs/solutions/ui-bugs/
integration_issue   → docs/solutions/integration-issues/
logic_error         → docs/solutions/logic-errors/
developer_experience → docs/solutions/developer-experience/
workflow_issue      → docs/solutions/workflow-issues/
best_practice       → docs/solutions/best-practices/
documentation_gap   → docs/solutions/documentation-gaps/
```

### Resolution Document Template

```markdown
---
module: [Module or "System"]
date: [YYYY-MM-DD]
problem_type: [from enum]
symptoms:
  - [Observable symptom 1]
  - [Observable symptom 2]
root_cause: [Free text description]
resolution_type: [from enum]
severity: [critical|high|medium|low]
tags: [keyword1, keyword2, keyword3]
---

# [Clear Problem Title]

## Problem
[1-2 sentence clear description]

## Symptoms
- [Observable symptom 1]
- [Observable symptom 2]

## What Didn't Work
**Attempted Solution 1:** [Description]
- **Why it failed:** [Technical reason]

## Solution
[The actual fix that worked]

**Code changes:**
```[language]
# Before (broken):
[problematic code]

# After (fixed):
[corrected code]
```

## Why This Works
1. What was the ROOT CAUSE?
2. Why does the solution address this root cause?

## Prevention
- [Specific coding practice to avoid recurrence]
- [What to watch out for]
- [How to catch early]

## Related Issues
- See also: [related-issue.md](../category/related-issue.md)
```

### Models

Context analyzer: Haiku. Solution extractor: Opus. Related docs finder: Haiku. Prevention strategist: Opus. Category classifier: Haiku.

---

## Model Allocation Summary

| Task | Model | Rationale |
|------|-------|-----------|
| **Main orchestrator** | Opus | Full context, user-facing |
| **Brainstorming** | Opus | Creative, nuanced dialogue |
| **Plan writing** | Opus | Architecture decisions |
| | | |
| **Research agents** | | |
| repo-research-analyst | Sonnet | Search + summarize |
| learnings-researcher | Haiku | Grep + frontmatter filter |
| best-practices-researcher | Sonnet | Synthesize external info |
| framework-docs-researcher | Haiku | Context7 lookup |
| spec-flow-analyzer | Opus | Edge case reasoning |
| | | |
| **Work phase** | | |
| Implementer | Opus | Writes actual code |
| Spec compliance reviewer | Sonnet | Compare code vs spec |
| Code quality reviewer | Opus | Quality judgment |
| | | |
| **Review (5 core)** | | |
| security-reviewer | Opus | Security requires deep reasoning |
| performance-reviewer | Opus | Algorithmic analysis |
| simplicity-reviewer | Sonnet | Simpler judgment |
| architecture-reviewer | Opus | Structural reasoning |
| pattern-reviewer | Sonnet | Pattern matching |
| Deep-review extras | Sonnet | Bounded checks |
| | | |
| **Compound subagents** | | |
| context-analyzer | Haiku | Extract metadata |
| solution-extractor | Opus | Identify what worked |
| related-docs-finder | Haiku | Grep + match |
| prevention-strategist | Opus | Prevention reasoning |
| category-classifier | Haiku | Simple classification |

---

## Plugin File Structure

```
flowstate/
├── .claude-plugin/
│   └── plugin.json
├── skills/                        # 16 skills
│   ├── brainstorming/
│   │   └── SKILL.md
│   ├── tdd/
│   │   └── SKILL.md
│   ├── compound/
│   │   ├── SKILL.md
│   │   ├── schema.yaml
│   │   └── assets/
│   │       ├── resolution-template.md
│   │       └── critical-pattern-template.md
│   ├── using-worktrees/
│   │   └── SKILL.md
│   ├── verification-before-completion/
│   │   └── SKILL.md
│   ├── writing-plans/
│   │   └── SKILL.md
│   ├── subagent-driven-development/
│   │   └── SKILL.md
│   ├── finishing-a-branch/
│   │   └── SKILL.md
│   ├── receiving-code-review/
│   │   └── SKILL.md
│   ├── requesting-code-review/
│   │   └── SKILL.md
│   ├── systematic-debugging/
│   │   └── SKILL.md
│   ├── document-review/
│   │   └── SKILL.md
│   ├── planning/
│   │   └── SKILL.md
│   ├── plan-deepening/
│   │   └── SKILL.md
│   ├── multi-agent-review/
│   │   └── SKILL.md
│   └── deep-code-review/
│       └── SKILL.md
├── agents/                        # 10 agents
│   ├── research/
│   │   ├── repo-research-analyst.md
│   │   ├── learnings-researcher.md
│   │   ├── best-practices-researcher.md
│   │   ├── framework-docs-researcher.md
│   │   └── spec-flow-analyzer.md
│   └── review/
│       ├── security-reviewer.md
│       ├── performance-reviewer.md
│       ├── simplicity-reviewer.md
│       ├── architecture-reviewer.md
│       └── pattern-reviewer.md
├── commands/                      # 8 commands
│   ├── brainstorm.md              # /flowstate:brainstorm
│   ├── plan.md                    # /flowstate:plan
│   ├── deepen-plan.md             # /flowstate:deepen-plan
│   ├── work.md                    # /flowstate:work
│   ├── review.md                  # /flowstate:review
│   ├── deep-review.md             # /flowstate:deep-review
│   ├── compound.md                # /flowstate:compound
│   └── debug.md                   # /flowstate:debug
├── hooks/
│   └── hooks.json                 # Session start hooks
└── README.md
```

---

## Project Directory Structure (User's Project)

After using flowstate, a project will have:

```
your-project/
├── CLAUDE.md                      # Project conventions (user maintains)
├── .worktrees/                    # Active worktrees (gitignored)
├── docs/
│   ├── brainstorms/               # /flowstate:brainstorm output
│   │   └── 2026-02-27-auth-brainstorm.md
│   ├── plans/                     # /flowstate:plan output
│   │   └── 2026-02-27-feat-auth-plan.md
│   └── solutions/                 # /flowstate:compound output
│       ├── patterns/
│       │   └── critical-patterns.md
│       ├── performance-issues/
│       ├── security-issues/
│       ├── runtime-errors/
│       └── ...
└── todos/                         # /flowstate:review findings
    ├── 001-pending-p1-sql-injection.md
    └── 002-pending-p2-missing-index.md
```

---

## The Compounding Flywheel

```
                    ┌─────────────────────────────┐
                    │                             │
                    ▼                             │
              ┌──────────┐                  ┌──────────┐
              │ BRAINSTORM│                  │ COMPOUND │
              │ (design)  │                  │ (learn)  │
              └─────┬─────┘                  └─────┬────┘
                    │                              │
                    ▼                              │
              ┌──────────┐     writes to      ┌────┴─────┐
              │   PLAN    │ ◄─── reads ──────│  docs/    │
              │ (research)│                   │ solutions/│
              └─────┬─────┘                   └──────────┘
                    │
                    ▼
              ┌──────────┐
              │   WORK   │
              │  (TDD)   │
              └─────┬────┘
                    │
                    ▼
              ┌──────────┐
              │  REVIEW  │
              │ (agents) │
              └─────┬────┘
                    │
                    ▼
              ┌──────────┐
              │ COMPOUND │──── writes to docs/solutions/
              │ (learn)  │
              └──────────┘

Each cycle: Plan reads learnings → Work produces code → Compound writes learnings
Next cycle: Plan reads MORE learnings → better code → better learnings → ...
```

---

## Future Upgrades (Not In Scope Now)

- **Hook-enforced TDD**: PreToolUse hook blocks Write/Edit on non-test files if no failing test exists
- **Stop hook**: Agent-based hook runs full test suite before allowing Claude to finish
- **Compaction survival hook**: SessionStart hook re-injects critical context after context compaction
- **Configurable review agents**: Setup skill to choose which reviewers run per project
- **Swarm mode**: Parallel teammate execution for large plans
- **`/flowstate:lfg`**: Full autonomous chain (brainstorm → plan → deepen → work → review → compound)

---

## Open Questions

None — all resolved during brainstorming.

## Next Steps

→ Implementation plan via the writing-plans workflow
