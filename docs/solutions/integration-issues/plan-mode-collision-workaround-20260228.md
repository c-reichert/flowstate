---
module: claude-code-plugins
date: 2026-02-28
problem_type: integration_issue
symptoms:
  - Claude enters built-in plan mode instead of invoking custom plan command
  - EnterPlanMode called unexpectedly during plugin workflow
  - Custom planning skill never executes when command name contains "plan"
root_cause: Claude conflates custom commands named "plan" with built-in EnterPlanMode (known bug #6109)
resolution_type: workflow_improvement
severity: critical
tags: [claude-code, plan-mode, enterplanmode, plugin-collision, bug-6109, disable-model-invocation]
---

# Plan Mode Collision with Custom Plugin Commands

## Problem
A Claude Code plugin had a `/flowstate:plan` command that creates TDD implementation plans. Claude would interpret this as a request to enter its built-in plan mode (EnterPlanMode/ExitPlanMode) instead of invoking the custom planning skill.

## Symptoms
- User invokes `/flowstate:plan` but Claude calls EnterPlanMode instead
- The planning skill never executes — Claude enters its built-in plan mode
- Plan mode's "thinking" output replaces the expected TDD plan document
- Users confused about why the workflow behaves differently than expected

## What Didn't Work
**Attempted Solution 1:** `disable-model-invocation: true` in skill frontmatter
- **Why it failed:** This flag is broken for plugin-defined skills (issue #22345). It's silently ignored — no error, no warning, just doesn't work. Cannot prevent Claude from calling EnterPlanMode via this mechanism.

**Attempted Solution 2:** Relying on the command description to distinguish from built-in plan mode
- **Why it failed:** Claude reads the command name "plan" and activates built-in plan mode BEFORE fully processing the command content. The name triggers the association.

**Attempted Solution 3:** `disable-model-invocation: true` on the skill (not command)
- **Why it failed:** This flag on a SKILL prevents the Skill tool from invoking it entirely. The compound skill had this flag and returned "cannot be used with Skill tool due to disable-model-invocation". Only use this flag on commands, never on skills you want to invoke programmatically.

## Solution
Three-layer defense — no single layer is sufficient alone:

**Layer 1: Rename the command**
```yaml
# Before (collides):
name: workflow:plan

# After (avoids trigger word):
name: workflow:write-plan
```

**Layer 2: Warning at top of planning skill**
```markdown
<IMPORTANT>
This is NOT Claude Code's built-in plan mode.
Do NOT call EnterPlanMode or ExitPlanMode.
The write-plan command invokes the flowstate:planning skill
to create a TDD implementation plan document.
</IMPORTANT>
```

**Layer 3: Warning in session-start hook (always in context)**
```
NOTE: /workflow:write-plan is NOT Claude Code's built-in plan mode.
Never call EnterPlanMode/ExitPlanMode during flowstate workflows.
```

**Optional Layer 4:** User can deny EnterPlanMode in Claude Code settings:
```json
// .claude/settings.json
{ "deny": ["EnterPlanMode"] }
```

## Why This Works
1. **Renaming removes the trigger.** Claude's association between "plan" and EnterPlanMode is name-based. "write-plan" doesn't trigger it.
2. **The skill warning catches edge cases** where Claude might still consider plan mode during the planning workflow.
3. **The session-start hook ensures the warning is always in context** — even after compaction or session resume.
4. **All three layers together** provide redundancy. Any single layer might fail (Claude ignores warnings, name still partially triggers), but together they reliably prevent the collision.

## Prevention
- Never name a plugin command "plan" — use "write-plan", "create-plan", or "draft-plan"
- Avoid other built-in tool names as command names: "plan", "edit", "read", "search"
- `disable-model-invocation: true` only works on commands, NOT on plugin-defined skills
- `disable-model-invocation: true` on a skill blocks the Skill tool from invoking it — only use on commands
- When a built-in feature collides with a plugin feature, use explicit warnings in BOTH the skill AND the session-start hook
- Test with fresh sessions — plan mode collision may not appear in the session where the command was created

## Related Issues
- See also: [plugin-namespace-design-20260228.md](../developer-experience/plugin-namespace-design-20260228.md)
- See also: [claude-code-plugin-architecture-20260227.md](../best-practices/claude-code-plugin-architecture-20260227.md)
