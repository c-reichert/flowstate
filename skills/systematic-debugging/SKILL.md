---
name: skill:systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior. Enforces a disciplined reproduce-isolate-diagnose-fix-verify cycle. No guessing allowed.
---

# Systematic Debugging

Random fixes waste time and create new bugs. Guessing is not debugging.

**Core principle:** Find the root cause before attempting any fix. Symptom fixes are failure.

## When to Use

Use for ANY unexpected behavior: test failures, runtime bugs, performance problems, build failures, integration issues.

**Especially when:**
- The fix seems "obvious" (obvious fixes mask root causes)
- You have already tried one fix that did not work
- You are under time pressure (systematic is faster than thrashing)

---

## Step 1: REPRODUCE

Confirm the bug exists. Get exact steps.

1. **Read error messages carefully** -- full stack traces, line numbers, error codes
2. **Find exact reproduction steps** -- can you trigger it reliably? Minimal sequence?
3. **Document expected vs actual behavior** -- the specific delta

**If not reproducible:** Gather more data. Add logging. Do NOT guess.

## Step 2: ISOLATE

Narrow the scope. Find the smallest reproduction.

1. **Binary search through code paths** -- add logging at component boundaries, trace where good data becomes bad
2. **Reduce to minimal failing case** -- strip unrelated code, identify the exact divergence point
3. **Check recent changes** -- `git diff`, new dependencies, config or environment differences

## Step 3: DIAGNOSE

Form hypotheses and test them. One at a time.

1. **Form a single hypothesis** -- "I think X is the root cause because Y"
2. **Test minimally** -- smallest possible change, one variable at a time
3. **Trace the execution path** -- where does the bad value originate? Trace backward to the source.
4. **Compare against working examples** -- what differs between working and broken code?

**Hypothesis confirmed?** Proceed to Step 4.
**Hypothesis rejected?** Form a NEW hypothesis. Do not pile fixes.

## Step 4: FIX

Write a failing test first. Then fix the root cause.

1. **Write a failing test** -- use the `tdd` skill; test must fail for the RIGHT reason (the bug, not a typo)
2. **Implement a single fix** -- address root cause, ONE change, no "while I'm here" improvements
3. **Verify the test passes** -- your new test passes, no other tests broke

## Step 5: VERIFY

1. **Run the full test suite** -- not just your new test
2. **Confirm the original symptom is gone** -- reproduce the original steps
3. **Check for regressions** -- did the fix break anything adjacent?

If anything fails, return to Step 3 with new information.

## Step 6: COMPOUND

If the bug was non-trivial (multiple attempts, non-obvious, or could recur):
- Run the `compound` skill to capture the learning
- Document root cause, why it was not obvious, and what did NOT work

---

## 3-Strike Error Protocol

| Attempt | Approach |
|---------|----------|
| **Strike 1** | Diagnose root cause, implement fix |
| **Strike 2** | Alternative diagnosis, different approach |
| **Strike 3** | Broader rethink -- question assumptions, architecture, environment |
| **After 3** | **STOP. Escalate to user.** |

After 3 failed fixes, do NOT attempt fix #4. Instead:
- Summarize what you tried and why each attempt failed
- Present your current understanding of the problem
- Ask the user for direction

**Escalate earlier if:** each fix reveals a new problem in a different place, fixes require massive refactoring, or each fix creates new symptoms. These indicate an architectural problem, not a bug.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|-------------|
| Guess-and-check | Creates new bugs, masks root cause |
| Fix symptom instead of root cause | Bug returns in different form |
| Skip reproduction | You do not know what you are fixing |
| Multiple changes at once | Cannot isolate what worked |
| "Quick fix now, investigate later" | Later never comes |
| Proposing fixes before tracing data flow | Guessing with extra steps |

## Red Flags -- STOP and Return to Step 1

If you catch yourself thinking:
- "Just try changing X and see if it works"
- "I don't fully understand but this might work"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"

**All of these mean: STOP. You are guessing. Return to Step 1.**

---

## Quick Reference

| Step | Key Activity | Done When |
|------|-------------|-----------|
| **1. REPRODUCE** | Exact steps, expected vs actual | Bug confirmed and repeatable |
| **2. ISOLATE** | Binary search, minimal repro | Failure narrowed to specific code |
| **3. DIAGNOSE** | Hypothesize, test one at a time | Root cause identified with evidence |
| **4. FIX** | Failing test first, then minimal fix | Test passes, root cause addressed |
| **5. VERIFY** | Full suite, regressions | Everything green, symptom gone |
| **6. COMPOUND** | Capture learning if non-trivial | Knowledge documented for reuse |
