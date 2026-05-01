---
name: document-review
description: Use to review brainstorm or plan documents before proceeding to the next workflow step. Applies structured self-review for completeness, clarity, consistency, feasibility, and YAGNI.
---

# Document Review

Structured self-review for brainstorm and plan documents.

**Core principle:** Catch problems in documents before they become problems in code.

## Review Checklist

Evaluate every document against these criteria:

| Criterion | What to Check |
|-----------|---------------|
| **Completeness** | All required sections filled? No TBD placeholders left? Open questions flagged? |
| **Clarity** | Would someone with zero context understand this? No vague language ("probably", "consider", "try to")? |
| **Consistency** | Do decisions align with each other? No contradictions between sections? |
| **Feasibility** | Can this actually be built with available tools and constraints? Are estimates realistic? |
| **YAGNI** | Anything unnecessary? Hypothetical features? Over-engineered for current needs? |

---

## For Brainstorm Documents

In addition to the checklist above, verify:

- **Open questions resolved** -- every question raised during brainstorming has an answer or is explicitly deferred with rationale
- **Key decisions captured** -- each decision includes the rationale (why this, not that)
- **Alternatives documented** -- rejected approaches listed with reasons for rejection
- **Constraints stated** -- technical limitations, time constraints, dependencies identified
- **Scope bounded** -- clear statement of what is in scope and what is not
- **Assumptions explicit** -- nothing left implied; all assumptions written down

## For Plan Documents

In addition to the checklist above, verify:

- **Exact file paths** -- every task references specific files to create or modify, no vague "update the module"
- **TDD steps present** -- every implementation task has explicit test-first steps (write test, verify red, implement, verify green)
- **Acceptance criteria testable** -- each criterion can be verified with a specific command or test, not subjective judgment
- **Task ordering sound** -- dependencies between tasks are correct, no task requires output from a later task
- **Effort estimates present** -- each task has a size estimate (small/medium/large)
- **No gaps** -- walking through the plan end-to-end produces a complete implementation with no missing steps

---

## Output Format

Present findings as a prioritized list:

```
## Document Review: [document name]

### Issues Found

**Critical** (blocks next step):
- [Issue description] -- [suggestion to fix]

**Important** (should address):
- [Issue description] -- [suggestion to fix]

**Minor** (optional improvement):
- [Issue description] -- [suggestion to fix]

### Assessment
[Ready to proceed / Needs revision]
[One sentence summary of document quality]
```

---

## Making Changes

1. **Auto-fix** minor issues (vague language, formatting, typos) without asking
2. **Ask approval** before substantive changes (restructuring, removing sections, changing meaning)
3. **Update inline** -- no separate review files, no metadata sections added

## Simplification Guidance

**Simplify when:**
- Content serves hypothetical future needs, not current ones
- Sections repeat information covered elsewhere
- Detail exceeds what is needed for the next step

**Do not simplify:**
- Constraints or edge cases that affect implementation
- Rationale explaining why alternatives were rejected
- Open questions that need resolution

## Iteration

After 2 review passes, recommend completion -- diminishing returns are likely.

## What NOT to Do

- Do not rewrite the entire document or add requirements the user did not discuss
- Do not over-engineer, add complexity, or create separate review files
