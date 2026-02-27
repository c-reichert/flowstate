---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing — requires running verification commands and confirming output before making any success claims. Evidence before assertions, always.
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, not cached)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output actually confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Verification Requirements

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, "logs look good" |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Requirements met | Line-by-line checklist against spec | "Tests passing" alone |

## Red Flags — STOP Immediately

If you catch yourself doing any of these, stop. Run the actual verification. Then proceed.

- Using "should", "probably", "seems to" about results
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit/push/PR without running tests
- Trusting a subagent's success report without checking independently
- Thinking "just this once, I don't need to verify"
- Skipping the full suite because "I only changed one file"
- Assuming cached results are still valid after changes
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter is not the test suite |
| "Agent said success" | Verify independently |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Evidence Patterns

**Tests:**
```
Correct:  [Run test command] -> [See: 34/34 pass] -> "All tests pass"
Wrong:    "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
Correct:  Write test -> Run (FAIL) -> Implement fix -> Run (PASS) -> Revert fix -> Run (FAIL) -> Restore -> Run (PASS)
Wrong:    "I've written a regression test" (without red-green verification)
```

**Build:**
```
Correct:  [Run build] -> [See: exit 0] -> "Build passes"
Wrong:    "Linter passed" (linter does not check compilation)
```

**Requirements:**
```
Correct:  Re-read spec -> Create checklist -> Verify each item -> Report gaps or completion
Wrong:    "Tests pass, phase complete"
```

**Agent delegation:**
```
Correct:  Agent reports success -> Check VCS diff -> Verify changes -> Report actual state
Wrong:    Trust agent report at face value
```

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction about work state
- Committing, PR creation, task completion
- Moving to the next task
- Delegating to agents

**Rule applies to:**
- Exact phrases, paraphrases, synonyms
- Implications of success
- ANY communication suggesting completion or correctness

## The Bottom Line

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
