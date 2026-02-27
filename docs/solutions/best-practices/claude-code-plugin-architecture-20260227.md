---
module: System
date: 2026-02-27
problem_type: best_practice
symptoms:
  - "Commands grew to 400+ lines with baked-in process knowledge"
  - "Process knowledge not reusable outside the command that contained it"
  - "Skills count was 4 when comparable plugins have 12-19"
root_cause: "Baked process knowledge directly into command orchestrators instead of extracting into reusable skills"
resolution_type: workflow_improvement
severity: medium
tags: [plugin-architecture, skills-vs-commands, separation-of-concerns, claude-code]
---

# Claude Code Plugin Architecture: Skills vs Commands

## Problem
When building the flowstate plugin, initial implementation baked process knowledge (TDD enforcement, verification gates, subagent dispatch patterns, review protocols) directly into command files. This led to 482-line commands that were monolithic and non-reusable.

## Symptoms
- `commands/work.md` grew to 482 lines
- TDD verification logic couldn't be used outside `/flowstate:work`
- Code review protocols were duplicated or unavailable standalone
- Plugin had only 4 skills vs 12-19 in comparable plugins (Superpowers, Compound Engineering)

## What Didn't Work
**Initial approach:** Write commands as self-contained orchestrators with all process knowledge inline.
- **Why it failed:** Commands became bloated, process knowledge was trapped inside specific workflows, users couldn't invoke individual capabilities independently.

## Solution
Extract reusable process knowledge into standalone skills, keep commands as lean orchestrators.

**Architecture principle:**
- **Skills** = reusable process knowledge (HOW to do something). Can be invoked from multiple commands or standalone.
- **Commands** = orchestration entry points (WHEN to invoke skills and in what order). Should be lean.
- **Agents** = expert personas (WHO reviews/analyzes). Invoked by commands as subagents.

**Extraction results:**
- `commands/work.md`: 482 → 157 lines (68% reduction)
- Skills: 4 → 12
- Each skill independently invokable

## Why This Works
1. Skills are loaded into context when their description matches the task — standalone skills get discovered and used automatically
2. Commands stay focused on orchestration (phase sequencing, agent spawning, user interaction)
3. Process knowledge is defined once, used in multiple workflows
4. Users can invoke individual skills without running the full workflow loop

## Prevention
- When writing a command that exceeds ~150 lines, ask: "Is there process knowledge here that should be a standalone skill?"
- If a block of instructions could be useful outside this specific command, extract it
- Commands should read like a recipe index (invoke skill A, then skill B), not like the full recipe

## Related Issues
None yet — first documentation in this project.
