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

- DevonThink triage workflow rules (established in session ec5a8004, 2026-05-29/30):

1. After importing a file into DT, move it to `/Users/cr/Dropbox/DevonThink Actions - Imported`
2. Tax-related files: always add `steuern` label + the tax year(s) as additional labels (e.g., `2024`, `2025`)
3. NEVER create DT groups/folders without Christian's explicit permission — he interrupted to correct this
4. Before trashing items, always show the table/list first so Christian can review; don't silently delete
5. Present files in numbered batches (started at 5, expanded to 10, then 20 — batch size grows as workflow is confirmed)
6. When Christian asks for 'more detail', provide it and let him decide — don't make assumptions

**Why:** Christian explicitly stopped and corrected each of these behaviors in the same session. The workflow is semi-automated but decision authority stays with Christian.
**How to apply:** Any Downloads/DT triage session must follow these rules from the start.
- Christian explicitly consented to extracting and storing personal medical data in the Obsidian vault and providing it to AI (session ec5a8004, 2026-05-29):

'my medical stuff and my kid's medical stuff you can extract — I am using AI as health advisor and share this sensitive stuff and the more info you have the better you can help me'

Additionally: medical history over time is valuable — extract changes/history, not just current state.

**Why:** Christian actively uses AI as a health advisor and wants complete context available.
**How to apply:** When processing DT documents or other sources containing medical information about Christian, Niklas, or Jonas — extract it into vault health notes. Don't skip or redact.

<!-- retro:managed:end -->
