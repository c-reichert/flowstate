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

- DevonThink (DT) is Christian's raw document store; Obsidian LifeOS vault is the knowledge/entity layer. Workflow for processing Downloads into DT:

- After DT import → move original file to `/Users/cr/Dropbox/DevonThink Actions - Imported`
- Tax-related docs → add `steuern` label + year label(s) (e.g., `steuern`, `2024`) — add each applicable year separately
- **Never create DT groups/folders without explicit permission** — Christian interrupted and corrected this
- Present files as a numbered table (with suggested action) BEFORE executing any deletes/moves
- Process in numbered batches — started at 5, escalated to 10, then 15, then 20
- When uncertain, give more detail and let Christian decide — he corrected 'if you want more detail, give me more detail and let me make the decision'
- Stale DT folders (no docs newer than 2 years) can be flagged for removal
- Personal DB is the primary DT database; structured subfolders: Finanzen, Versicherungen, Persönliches, etc.
- Glenny trader must stay in live trading mode — do NOT switch it to paper mode.

**Why:** Christian explicitly corrected this in session 0063be88: 'sorry glenny should stay in live mode my fault' when it was about to be moved to paper alongside Cha trader.

**How to apply:** When making mode changes to the trading system, only Cha trader goes to paper. Glenny stays live. Always confirm which trader is being targeted before flipping paper/live flags.
- Trading bot review workflow: after major analysis session, write REVIEW_BRIEF.md (with full context + review prompts) to /tmp/glenny-analysis/ or similar temp dir, then start a NEW session with /effort ultracode and `read REVIEW_BRIEF.md and execute`. The new session runs an adversarial multi-agent code review across multiple dimensions.

**Observed:** Session 5c70e412 ended with Christian asking for a 'context and prompt for that new session'. Session 0063be88 opened with `read /tmp/glenny-analysis/REVIEW_BRIEF.md and execute` + ultracode effort.

**How to apply:** When finishing a deep analysis session on a trader, offer to write the REVIEW_BRIEF.md handoff document. The review session should use ultracode for adversarial multi-agent coverage.

<!-- retro:managed:end -->
