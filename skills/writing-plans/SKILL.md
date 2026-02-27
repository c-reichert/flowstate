---
name: writing-plans
description: >
  Structure implementation plans with TDD-structured tasks, bite-sized granularity,
  and learnings integration. Use when converting research/specs into an actionable plan document.
---

# Writing Implementation Plans

## Overview

Write implementation plans assuming the engineer has zero codebase context. Document
everything: which files to touch, complete code, exact test commands, expected output.
Every task is bite-sized and TDD-structured. DRY. YAGNI. TDD. Frequent commits.

Assume the implementer is a skilled developer but knows nothing about the toolset,
problem domain, or local conventions. Assume they don't know good test design.

**Announce at start:** "I'm using the writing-plans skill to structure the plan."

---

## Plan Document Header

Every plan starts with this header:

```markdown
# [Plan Title]

**Goal:** [One sentence — what this builds or fixes]

**Architecture:** [2-3 sentences about the approach]

**Tech Stack:** [Key technologies and libraries involved]

---
```

---

## YAML Frontmatter

Every plan file begins with:

```yaml
---
title: [Plan Title]
type: [feat|fix|refactor]
status: active
date: YYYY-MM-DD
origin: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md  # if from brainstorm
detail_level: [minimal|more|a_lot]
---
```

**Title and filename:** Draft a clear title (e.g., `feat: Add user authentication`).
Convert to filename: `YYYY-MM-DD-<type>-<descriptive-name>-plan.md`
(e.g., `2026-02-27-feat-add-user-authentication-plan.md`). Keep 3-5 words after prefix.

**Save location:** `docs/plans/YYYY-MM-DD-<type>-<name>-plan.md`

---

## Detail Levels

Choose based on complexity -- simpler is mostly better:

| Level | When to Use | Includes |
|-------|-------------|----------|
| **MINIMAL** | Quick fix, small bug, clear single-file change | Overview + acceptance criteria + research context + tasks |
| **MORE** | Standard feature, multi-file change | MINIMAL + problem statement + technical considerations + system-wide impact + dependencies |
| **A LOT** | Complex feature, architectural change, multi-phase work | MORE + implementation phases + alternatives considered + risk analysis + resource requirements |

### Sections by Level

**MINIMAL** includes:
- Overview (problem/feature description)
- Acceptance Criteria
- Research Context (learnings, existing patterns)
- Implementation Tasks (TDD-structured)
- Sources

**MORE** adds:
- Problem Statement / Motivation
- Technical Considerations
- System-Wide Impact (interaction graph, error propagation, state lifecycle, API surface parity)
- Dependencies and Risks

**A LOT** adds:
- Detailed Implementation Phases
- Alternative Approaches Considered
- Risk Analysis and Mitigation
- Resource Requirements
- Documentation Plan

---

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" -- one step
- "Run it to make sure it fails" -- one step
- "Implement the minimal code to make it pass" -- one step
- "Run the tests and make sure they pass" -- one step
- "Commit" -- one step

Never combine these. Each is its own numbered step with its own expected output.

---

## TDD Task Structure

**Every implementation task follows this structure. No exceptions.**

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/new_file.py`
- Modify: `exact/path/to/existing_file.py:123-145`
- Test: `tests/exact/path/to/test_file.py`

**Step 1: Write the failing test**
```[language]
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**
Run: `[test command] tests/path/test_file.py::test_name -v`
Expected: FAIL with "[specific failure reason — e.g., function not defined]"

**Step 3: Write minimal implementation**
```[language]
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**
Run: `[test command] tests/path/test_file.py::test_name -v`
Expected: PASS

**Step 5: Commit**
```bash
git add tests/path/test_file.py src/path/file.py
git commit -m "feat(scope): add specific feature"
```
````

### Task Quality Rules

- **Exact file paths always** -- never "the config file" or "the test directory"
- **Complete code in plan** -- never "add validation" or "implement the handler"
- **Exact commands with expected output** -- never "run the tests"
- **One behavior per task** -- if you write "and" in the task name, split it

---

## Learnings Integration

Reference past learnings wherever they apply. This is how the compounding flywheel works.

**Pattern:** Inline references at the point of relevance within tasks:
- "Avoid N+1 queries here -- see `docs/solutions/performance-issues/n-plus-one-fix.md`"
- "Use the retry pattern from `docs/solutions/integration-issues/api-retry-strategy.md`"
- "Watch for the timezone edge case in `docs/solutions/runtime-errors/timezone-conversion.md`"

**Research Context section** (placed after Overview, before tasks):

```markdown
## Research Context

### Relevant Learnings
- [Title] (docs/solutions/[category]/[file].md) -- [key insight]

### Existing Patterns
- [file:line] -- [what pattern to follow]

### Best Practices
- [recommendation from external research]

### Edge Cases
- [edge case] -- [handling strategy]
```

---

## Plan Output Template

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
**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
---
## Overview
[Problem/feature description]
## Research Context
### Relevant Learnings
- [Title] (docs/solutions/[category]/[file].md) -- [key insight]
### Existing Patterns
- [file:line] -- [what pattern to follow]
### Best Practices
- [recommendation from research]
### Edge Cases
- [edge case] -- [handling strategy]
## Acceptance Criteria
- [ ] Criterion 1
## Implementation Tasks
### Task 1: [Component]
[TDD steps: test -> verify fail -> implement -> verify pass -> commit]
## Sources
- Brainstorm: docs/brainstorms/[file]
- Learnings: docs/solutions/[files]
- External: [URLs]
```

---

## Principles and Reminders

- **DRY** -- Extract shared setup into helpers. Don't repeat yourself.
- **YAGNI** -- Plan only what's required now. Nothing speculative.
- **TDD** -- Every task is test-first. No production code without a failing test.
- **Frequent commits** -- One commit per task. Small, reviewable, revertible.
- **Brainstorm is the origin** -- Honor all brainstorm decisions. Reference with `(see brainstorm: docs/brainstorms/<filename>)`.
- **Exact file paths always** -- never vague references.
- **Complete code in plan** -- never "add validation" or "implement the handler."
- **Exact commands with expected output** -- never "run the tests."
- **Reference learnings inline** where they apply.
