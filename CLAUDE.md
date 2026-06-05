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

- DevonThink integration rules (LifeOS sessions, 2026-05-29):

1. **Never create new DT groups without Christian's express permission** — user interrupted tool use specifically to block unsolicited group creation: 'don't create groups without my express permission'
2. **After importing a file into DT, move the original to `/Users/cr/Dropbox/DevonThink Actions - Imported`** — this is the post-import staging folder
3. **DT OSA calls via parallel subagents may not work** — user noted 'not sure if parallel osa to DT would work'; use sequential subagents or main-session OSA calls for DT operations
4. **DT EFH Nebenkosten group UUID**: `x-devonthink-item://96CCE59B-97C4-42C6-949F-EC3A5075587E`

**Why:** DT is the raw document store; accidental group creation pollutes the taxonomy Christian has built up. Post-import move prevents double-processing.
**How to apply:** Always ask before creating new groups. After every DT import via AppleScript, move the source file to the Imported folder.
- Downloads triage protocol (established session ec5a8004, 2026-05-29 to 05-30):

1. **Number every item** — present as a numbered table so Christian can reply '5 review, 7 trash, rest as suggested'
2. **Show the table before executing any destructive actions** — do not trash/move until Christian approves. User corrected: 'before you trash things give me the table in the future'
3. **Batch size**: start at 10, increase to 15–20 as Christian approves larger batches
4. **Tax-related items**: add label `steuern` plus the tax year(s) they cover (e.g., `steuern-2024`). Items spanning multiple years get multiple labels
5. **Poorly-named files** (e.g., 'Rechnung (1).pdf'): suggest a sensible rename before import
6. **After DT import**: move original file to `/Users/cr/Dropbox/DevonThink Actions - Imported`
7. **When uncertain about detail**, show more detail and let Christian decide — do not silently drop or assume
8. **Also update LifeOS 2nd Brain** when documents contain extractable entities (addresses, Kundennummern, contract dates, people)

**Why:** Triage sessions are long and interactive; numbering makes back-references fast. Destructive-first approach caused interruptions.

<!-- retro:managed:end -->
