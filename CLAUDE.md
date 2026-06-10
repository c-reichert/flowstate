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

- LifeOS vault + DevonThink split architecture — clarified in ec5a8004 sessions:

**DevonThink (DT):** Raw document archive — scans, invoices, legal docs, financial statements, correspondence. Source of truth for documents.

**Obsidian LifeOS Vault:** Structured knowledge extracted from DT — entities (people, accounts, contracts), facts (policy numbers, account balances, key dates), summaries, relationships, action items.

**Key rule:** Linking to a DT item alone is insufficient. The vault note must also contain the key details (account number, expiry, contract terms, etc.) so the AI can answer questions without opening DT.

**Relationship:** DT is the archive; vault is the queryable knowledge layer on top of it. They complement, not duplicate.

**How to apply:** When ingesting DT content into the vault — extract the actual facts, not just the DT link. When Christian says 'I don't think just linking is enough', extract details inline.
- DevonThink operational rules — confirmed across LifeOS sessions (ec5a8004, 7de02925):

1. **Move after import:** After any file is successfully imported into DT, move the original to `/Users/cr/Dropbox/DevonThink Actions - Imported`. Then delete the original.
2. **No group creation without permission:** Never create DT groups/folders without Christian's explicit approval.
3. **Tax document tagging:** Documents relating to taxes must get label `steuern` plus a label for each relevant tax year (e.g. `2024`, `2025`). If multi-year, add all years.
4. **Sequential AppleScript:** DT AppleScript operations must run sequentially — parallel DT calls are unreliable and risk corruption.
5. **Table before bulk trash:** Before executing any batch delete/trash action, always show Christian a numbered table of what will be trashed. Never trash silently.
6. **DT paths are deep-links:** When referencing DT items in vault notes, use the `x-devonthink-item://` deep-link format for direct navigation.

**Why:** Rules 2 and 5 came from explicit mid-session corrections (ec5a8004). Rule 4 from Christian noting 'probably not parallel' for OSA calls.

**How to apply:** Whenever running DT operations during LifeOS sessions, downloads triage, or DT inbox processing.

<!-- retro:managed:end -->
