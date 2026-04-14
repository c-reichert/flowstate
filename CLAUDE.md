# FlowState — Claude Code Plugin

## What This Is
A Claude Code plugin providing structured thinking workflows: brainstorming, planning, TDD, compound (incremental documentation), and multi-agent review.

## Architecture
- `/skills/` — each subdirectory is a skill (SKILL.md defines behavior)
- `/agents/` — agent definitions for research and review subagents
- `/commands/` — workflow commands (brainstorm, write-plan, work, review, compound, etc.)
- `/hooks/` — session-start hook that injects core rules
- `/package.json` — plugin metadata + version

## Conventions
- Version lives in `package.json` — bump on every feature/fix commit
- Bumping version: edit `version` field in `package.json`, commit as `chore: bump version to X.Y.Z`
- Skill files use XML tags for structural sections (per Anthropic Opus 4.6 best practices)
- The `write-plan` skill exists because `plan` conflicts with Claude's built-in EnterPlanMode

## Defend Research Before Reverting
When you have completed research that supports a specific recommendation, and the user immediately overrides it without engaging with the evidence, present the key evidence before making changes. A single sentence like "My research found X — would you like to see the evidence before I revert?" prevents costly flip-flops where work gets done, undone, and redone. This applies to any researched recommendation, not just prompting conventions.
