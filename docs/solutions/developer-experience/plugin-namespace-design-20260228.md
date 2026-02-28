---
module: claude-code-plugins
date: 2026-02-28
problem_type: developer_experience
symptoms:
  - Users confuse commands and skills in Claude Code plugins
  - No visual distinction between invokable commands and background skills
  - Flat namespace creates naming collisions with built-in features
root_cause: Single-level namespace makes it impossible to distinguish command types from skill types at a glance
resolution_type: workflow_improvement
severity: medium
tags: [claude-code, plugin-architecture, namespace, commands, skills, developer-experience]
---

# Plugin Namespace Design for Commands and Skills

## Problem
A Claude Code plugin with both commands (user-invokable slash commands) and skills (reusable process knowledge) used a flat `flowstate:X` namespace for everything. Users couldn't tell commands from skills.

## Symptoms
- Commands and skills both appear as `flowstate:X` — no visual distinction
- Users try to invoke skills as commands and vice versa
- The `/flowstate:plan` command collided with Claude's built-in plan mode
- Autocomplete shows a confusing mix of commands and skills

## What Didn't Work
**Attempted Solution 1:** `name: skill:X` in skill frontmatter to create `flowstate:skill:X` Skill tool names
- **Why it failed:** The Skill tool registers skills by directory name, not the `name` field. `flowstate:skill:brainstorming` was "Unknown skill" in the Skill tool. However, the `name` field DOES control autocomplete display — `/skill:tdd` appears correctly.

**Attempted Solution 2:** Subdirectory `skills/skill/X/SKILL.md` to create `flowstate:skill:X`
- **Why it failed:** The Skill tool still didn't recognize the nested name. Autocomplete showed it, but programmatic invocation failed.

## Solution
Two-layer approach — different mechanisms for commands vs skills:

**Commands:** Put in `commands/workflow/` directory with `name: workflow:X` in frontmatter.

```yaml
# commands/workflow/brainstorm.md
---
name: workflow:brainstorm
description: "Start a guided design session..."
disable-model-invocation: true
---
Invoke the flowstate:brainstorming skill for: $ARGUMENTS
```

Result: surfaces as `/workflow:brainstorm` in both autocomplete AND the Skill tool.

**Skills:** Set `name: skill:X` in frontmatter for autocomplete, but reference by directory name in code.

```yaml
# skills/brainstorming/SKILL.md
---
name: skill:brainstorming
description: "..."
---
```

Result: shows as `/skill:brainstorming` in autocomplete, but Skill tool uses `flowstate:brainstorming`.

**Cross-references in commands must use directory-based names:**
```markdown
# CORRECT — Skill tool can find this
Invoke the flowstate:brainstorming skill for: $ARGUMENTS

# WRONG — Skill tool returns "Unknown skill"
Invoke the flowstate:skill:brainstorming skill for: $ARGUMENTS
```

## Why This Works
1. **Commands use the `name` field for everything** — both autocomplete and Skill tool respect it. The subdirectory approach (`commands/workflow/`) creates the colon-separated namespace.
2. **Skills use the `name` field only for autocomplete** — the Skill tool always registers by directory path. Setting `name: skill:X` gives users visual clarity without breaking programmatic invocation.
3. **The split is invisible to users** — they see `/workflow:brainstorm` and `/skill:tdd` in autocomplete, which clearly distinguishes commands from skills.

## Prevention
- For commands: use subdirectories + `name` field (both mechanisms agree)
- For skills: use `name` field for display only, always reference by directory name in code
- Never assume `name` field controls Skill tool registration for skills — it doesn't
- Test both autocomplete AND programmatic invocation after namespace changes
- Pattern borrowed from Compound Engineering plugin's `commands/workflows/` approach

## Related Issues
- See also: [plan-mode-collision-workaround-20260228.md](../integration-issues/plan-mode-collision-workaround-20260228.md)
- See also: [claude-code-plugin-architecture-20260227.md](../best-practices/claude-code-plugin-architecture-20260227.md)
