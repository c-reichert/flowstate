---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions. Requires technical rigor and verification -- not performative agreement or blind implementation.
---

# Receiving Code Review Feedback

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Protocol

```
1. READ      — Read complete feedback without reacting
2. UNDERSTAND — Restate the issue in plain language
3. VERIFY    — Check against the actual codebase
4. EVALUATE  — Technically sound for THIS codebase?
5. RESPOND   — Fix it, or push back with technical reasoning
6. IMPLEMENT — One item at a time, test each fix
```

If an issue cannot be explained clearly, understanding is incomplete — return to step 2. Why: implementing on shaky understanding is how reviewer-suggested fixes introduce new bugs.

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP — do not implement anything yet
  ASK for clarification on the unclear items
  WAIT until clear before implementing anything
```

Items may be related. Partial understanding leads to wrong implementation.

**Example:** Feedback says "Fix items 1-6". Items 1, 2, 3, 6 are clear; 4 and 5 are not.
- WRONG: Implement 1, 2, 3, 6 now. Ask about 4, 5 later.
- RIGHT: "Items 1, 2, 3, 6 are clear. Need clarification on 4 and 5 before proceeding."

## YAGNI Check Before Implementing

Before implementing any reviewer suggestion, verify it is needed:

```bash
grep -r "function_name\|ClassName\|method_name" --include="*.py" .
```

- Unused or zero callers: "This code is not called. Remove it (YAGNI)?"
- One caller, no plans for more: is the improvement actually needed?
- Actively used: implement the improvement properly.

## When to Push Back

Push back when:
- **Breaks existing functionality** -- the suggestion does not account for callers or side effects
- **Reviewer lacks full context** -- the reviewer sees a diff, not the full system
- **Violates YAGNI** -- the suggestion improves unused or rarely-used code
- **Technically incorrect for this stack** -- generic advice that does not apply
- **Conflicts with prior architectural decisions** -- discuss with the human partner first

How: technical reasoning, reference working tests/code, ask specific questions.

## Implementation Order

1. **Clarify** anything unclear FIRST
2. **Blocking issues** -- security flaws, broken functionality
3. **Simple fixes** -- typos, imports, naming
4. **Complex fixes** -- refactoring, logic changes

Test each fix individually. Verify no regressions after each one.

## Acknowledging Correct Feedback

```
DO:    "Fixed. [Brief description of what changed]"
DO:    "Good catch -- [specific issue]. Fixed in [location]."
DO:    [Just fix it and show the change in code]

DON'T: "You're absolutely right!" / "Great point!" / "Thanks for catching that!"
DON'T: Any performative agreement or gratitude expression
```

Actions speak. The fix itself shows the feedback was heard.

## Correcting Wrong Pushback

After pushing back and turning out to be wrong:
```
DO:    "Checked [X] and it does [Y]. Implementing now."
DON'T: Long apology, defending the original pushback, over-explaining.
```

State the correction factually. Move on.

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Performative agreement | State the requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One fix at a time, test each |
| Assuming reviewer is right | Check if it breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify ALL items first |

## The Bottom Line

Review feedback = suggestions to evaluate, not orders to follow.
Verify. Question. Then implement. No performative agreement.
