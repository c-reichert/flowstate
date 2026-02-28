---
name: skill:tdd
description: Use when implementing any feature or bugfix, before writing implementation code. Enforces strict test-first development — no production code without a failing test.
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask your human partner):**
- Throwaway prototypes
- Generated code
- Configuration files

Thinking "skip TDD just this once"? Stop. That's rationalization.

---

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

---

## The Cycle: RED -> VERIFY RED -> GREEN -> VERIFY GREEN -> REFACTOR

Every piece of production code follows this cycle. No shortcuts. No reordering.

### Step 1: RED — Write the Failing Test

Write one minimal test that describes the behavior you want.

**Requirements:**
- One behavior per test
- Clear name that describes what should happen
- Real code paths (no mocks unless unavoidable)
- Write the assertion first, then work backward

```
# Test describes the WHAT, not the HOW
# Name states expected behavior clearly
# Tests real code, not mock behavior
```

**Bad tests:** vague names, multiple assertions testing unrelated things, mocking away the code under test.

### Step 2: VERIFY RED — Watch It Fail

**MANDATORY. Never skip.**

Run the project's test command targeting your new test.

Confirm:
- Test FAILS (not errors from syntax or imports)
- Failure message matches your expectation
- Fails because the feature is MISSING, not because of typos

**Test passes immediately?** You're testing existing behavior. Your test is wrong. Fix it.

**Test errors instead of failing?** Fix the error. Re-run until it fails correctly — a clean failure for the right reason.

### Step 3: GREEN — Write Minimal Code

Write the simplest possible code to make the test pass. Nothing more.

- No extra features
- No "while I'm here" improvements
- No refactoring other code
- No options, parameters, or generalization the test doesn't require

If the test asks for one thing, implement one thing.

### Step 4: VERIFY GREEN — Watch It Pass

**MANDATORY.**

Run the project's test command.

Confirm:
- Your new test passes
- ALL other tests still pass
- Output is pristine (no errors, no warnings, no deprecation notices)

**New test fails?** Fix your implementation, not the test.

**Other tests broke?** Fix them now. Do not proceed with broken tests.

### Step 5: REFACTOR — Clean Up (Tests Still Green)

Only after green:
- Remove duplication
- Improve names
- Extract helpers
- Simplify logic

Run the project's test command after every change. Stay green. If tests break during refactor, undo and try again.

Do NOT add behavior during refactor. Refactor changes structure, not functionality.

### Step 6: REPEAT

Next failing test. Next behavior. Same cycle. No exceptions.

---

## Delete-and-Restart Enforcement

Write code before the test? Delete it. Start over. No exceptions.

- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't glance at it for "inspiration"
- Don't copy-paste it into a test
- Delete means DELETE

You wrote 200 lines without a test? Delete 200 lines. You spent 4 hours? Those hours are gone regardless. Your choice now:

1. Delete and rewrite with TDD — high confidence, real tests
2. Keep it and bolt on tests after — false confidence, fragile tests

Option 2 is not TDD. It is rationalization wearing a lab coat.

---

## Common Rationalizations

Every excuse below is invalid. Every single one.

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. Write it. |
| "I'll test after" | Tests passing immediately prove nothing. You lost the proof. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" These are not the same question. |
| "Already manually tested" | Ad-hoc is not systematic. No record. Can't re-run. Can't trust. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. The time is gone. Keeping unverified code is debt. |
| "Keep as reference" | You'll adapt it. That's testing after with extra steps. Delete means delete. |
| "Need to explore first" | Fine. Explore. Then throw away ALL exploration code and start with TDD. |
| "Test is hard = design unclear" | Listen to the test. Hard to test = hard to use. Fix the design. |
| "TDD will slow me down" | TDD is faster than debugging. You'll pay the time either way — upfront or in production. |
| "Manual test is faster" | Manual doesn't prove edge cases. You'll re-test every change forever. |
| "Existing code has no tests" | You're improving it now. Add tests for the code you're touching. No excuse. |
| "This is different because..." | It's not. Delete the code. Start over with TDD. |

---

## Why Order Matters

**"I'll write tests after to verify it works"**

Tests written after code pass immediately. Passing immediately proves nothing:
- Might test the wrong thing
- Might test implementation details, not behavior
- Might miss edge cases you forgot
- You never saw the test catch the bug

Test-first forces you to see the test fail, proving it actually tests something real.

**"Tests after achieve the same goals — it's spirit not ritual"**

No. Tests-after are biased by your implementation. You test what you built, not what's required. You verify remembered edge cases, not discovered ones.

Tests-first force edge case discovery BEFORE implementing. Tests-after verify you remembered everything. You didn't.

**"Deleting X hours of work is wasteful"**

Sunk cost fallacy. The time is already spent. Your choice now:
- Delete and rewrite with TDD (X more hours, high confidence)
- Keep it and add tests after (30 min, low confidence, likely bugs later)

The "waste" is keeping code you can't trust.

**"TDD is dogmatic, being pragmatic means adapting"**

TDD IS pragmatic:
- Finds bugs before commit (faster than debugging in production)
- Prevents regressions (tests catch breaks immediately)
- Documents behavior (tests show how to use the code)
- Enables fearless refactoring (change freely, tests catch breaks)

"Pragmatic" shortcuts = debugging in production = slower.

---

## Red Flags — STOP and Start Over

If you catch yourself doing any of these, stop immediately. Delete the code. Restart with TDD.

1. Writing production code before a test exists
2. Writing tests after implementation is done
3. A new test passes immediately without writing new code
4. Unable to explain why a test failed
5. Planning to add tests "later"
6. Rationalizing "just this once"
7. Saying "I already manually tested it"
8. Claiming "tests after achieve the same purpose"
9. Arguing "it's about spirit not ritual"
10. Keeping code as "reference" or "adapting existing code"
11. Saying "already spent X hours, deleting is wasteful"
12. Claiming "TDD is dogmatic, I'm being pragmatic"
13. Thinking "this is different because..."
14. Expressing satisfaction or confidence before running verification

**All of these mean the same thing: Delete the code. Start over with TDD.**

No negotiation. No partial credit. Delete and restart.

---

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | Tests one thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes expected behavior | `test('test1')`, `test('it works')` |
| **Intent** | Demonstrates the desired API | Obscures what code should do |
| **Real** | Tests actual code paths | Tests mock behavior instead of real behavior |
| **Focused** | Assertion matches the test name | Asserts unrelated side effects |

---

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the API you wish existed. Write the assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify the interface. |
| Must mock everything | Code too coupled. Use dependency injection. Reduce coupling. |
| Test setup is huge | Extract test helpers. Still complex? Simplify the design. |
| Can't isolate the unit | Break dependencies. Inject them. Make the boundary explicit. |

---

## Debugging Integration

Bug found? Write a failing test that reproduces it FIRST. Then follow the TDD cycle. The test proves the fix works AND prevents regression.

Never fix bugs without a test. The test is the proof. Without proof, you're guessing.

---

## Verification Checklist

Before marking any task complete, confirm ALL of these:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for the expected reason (feature missing, not typo or syntax error)
- [ ] Wrote minimal code to pass each test — nothing extra
- [ ] All tests pass (not just new ones — the entire suite)
- [ ] Output is pristine (no errors, no warnings, no deprecation notices)
- [ ] Tests use real code (mocks only when absolutely unavoidable)
- [ ] Edge cases and error paths are covered

Can't check all boxes? You skipped TDD. Start over.

---

## Final Rule

```
Production code -> test exists and failed first
Otherwise -> not TDD
```

No exceptions without your human partner's explicit permission.
