# FlowState — Claude Code Plugin

## What This Is
A Claude Code plugin providing structured thinking workflows: brainstorming, planning, TDD, compound (incremental documentation), and multi-agent review.

## Architecture
- `/skills/` — each subdirectory is a skill (SKILL.md defines behavior)
- `/agents/` — agent definitions for research and review subagents (`research/` + `review/`)
- `/commands/workflow/` — workflow commands (brainstorm, write-plan, work, review, compound, etc.)
- `/hooks/` — session-start hook that injects core rules
- `/.claude-plugin/plugin.json` — plugin manifest + version (source of truth)
- `/.claude-plugin/marketplace.json` — marketplace manifest, must mirror plugin.json version

## Conventions
- Version lives in `.claude-plugin/plugin.json` — bump on every feature/fix commit
- Bumping version: edit `version` in `plugin.json` AND `marketplace.json` (both must match), commit as `chore: bump version to X.Y.Z`
- Skill bodies use **markdown**, not XML tags. Use `>` blockquotes for emphasis blocks. (Earlier guidance recommended XML — superseded by Anthropic's Opus 4.6 prompting research, which prefers markdown structure.)
- The `write-plan` skill exists because `plan` conflicts with Claude's built-in EnterPlanMode
- All commands set `disable-model-invocation: false` so Claude can dispatch workflows when contextually appropriate. The skill bodies themselves contain the user-approval gates.

## Defend Research Before Reverting
When you have completed research that supports a specific recommendation, and the user immediately overrides it without engaging with the evidence, present the key evidence before making changes. A single sentence like "My research found X — would you like to see the evidence before I revert?" prevents costly flip-flops where work gets done, undone, and redone. This applies to any researched recommendation, not just prompting conventions.

<!-- retro:managed:start -->
## Retro-Discovered Patterns

- DevonThink filing workflow rules (established sessions 01bc61e2 + ec5a8004, 2026-05-27/29):

Import destination: After importing any file to DT, move the original to `/Users/cr/Dropbox/DevonThink Actions - Imported`.

Tax documents: Add label `steuern` + year label(s) (e.g. `2024`, `2025`). If spans multiple years, add each year as separate label.

DT groups: NEVER create DT groups/folders without Christian's explicit permission — he decides the structure. User corrected mid-session: 'don't create groups without my express permission'.

Before trashing: Always show a table of files proposed for trash and let Christian confirm before executing.

DT vs Obsidian split: DT = raw document archive (invoices, scans, PDFs). Obsidian = knowledge/entities extracted from those docs (contract terms, policy numbers, suppliers, expiry dates, warranty info). Both layers serve different purposes — not duplication.

**Why:** Multiple explicit corrections in ec5a8004. The DT/Obsidian split was explicitly articulated by Christian as the intended architecture.

**How to apply:** Any file-triage or DT work must follow these rules. Extract entities (Kundennummer, Vertragslaufzeit, warranty details) into vault, not just file a pointer.

<!-- retro:managed:end -->
