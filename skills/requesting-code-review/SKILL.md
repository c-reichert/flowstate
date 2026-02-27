---
name: requesting-code-review
description: Use when requesting code review after implementing features, before merging, when stuck, or after fixing complex bugs. Structures what to provide reviewers and what output to expect.
---

# Requesting Code Review

**Core principle:** Give reviewers everything they need to evaluate your changes without follow-up questions.

## When to Request Review

**Mandatory:** after completing a feature, before merging to main, after fixing complex bugs.

**Optional but valuable:** when stuck, before refactoring, after architectural changes.

## What to Provide Reviewers

Every review request includes:

### 1. Git SHA Range

```bash
BASE_SHA=$(git merge-base origin/main HEAD)
HEAD_SHA=$(git rev-parse HEAD)
git diff --stat $BASE_SHA..$HEAD_SHA
```

### 2. Description of Changes

- What was implemented (one paragraph)
- Why it was done this way (design decisions)
- What alternatives were considered and rejected

### 3. Plan or Requirements Reference

- Link to the plan, task, or issue being addressed
- Which acceptance criteria this satisfies
- Any deviations from the original plan and why

### 4. Known Concerns

- Areas you are uncertain about
- Trade-offs you made deliberately
- Anything you want specific feedback on

## Expected Output Format from Reviewers

Reviewers should return findings in this structure:

### Strengths
What is well done, with specific file:line references.

### Issues

**Critical (Must Fix):**
Bugs, security vulnerabilities, data loss risks, broken functionality.

**Important (Should Fix):**
Architecture problems, missing error handling, test gaps, performance issues.

**Minor (Nice to Have):**
Code style, minor optimizations, documentation improvements.

Each issue includes:
- `file:line` reference
- What is wrong
- Why it matters
- How to fix (if not obvious)

### Assessment

**Ready to merge?** Yes / No / With fixes

**Reasoning:** One to two sentences of technical justification.

## Acting on Feedback

1. Fix Critical issues immediately -- these block merge
2. Fix Important issues before proceeding
3. Note Minor issues for later or address if quick
4. Push back with technical reasoning if the reviewer is wrong

See the `receiving-code-review` skill for the full feedback-handling protocol.

## Integration with Workflows

| Workflow | When to Review |
|----------|---------------|
| Subagent-driven development | After each task |
| Executing plans | After each batch of 3 tasks |
| Ad-hoc development | Before merge, or when stuck |

## Red Flags

- Skipping review because "it's simple"
- Ignoring Critical issues
- Proceeding with unfixed Important issues
- Providing no context -- just "review this diff"
