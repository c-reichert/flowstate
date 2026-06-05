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

- DevonThink filing workflow rules (established during Downloads triage, sessions 01bc61e2 + ec5a8004, 2026-05-27/29):

**Import workflow:** Claude suggests destination + tags → Christian decides → Claude imports to DT → moves original to `/Users/cr/Dropbox/DevonThink Actions - Imported`.

**Key rules:**
- NEVER create new DT groups without explicit permission from Christian
- Tax-related items: add label `steuern` + label for each tax year referenced (e.g. `2024`, `2025`)
- Before trashing ANY file, show a numbered table first — don't trash without Christian reviewing
- Number all items in batch tables for easy reference (e.g. '1', '2', '3'...)
- Process in batches: started 5, escalated to 10, 15, then 20 files per batch
- DT Personal DB inbox also needs periodic tagging/filing using same suggest→decide workflow
- Imported originals go to: `/Users/cr/Dropbox/DevonThink Actions - Imported`

**DT folder structure hints:**
- Main DB: Finanzen, Versicherungen, Persönliches, MFH, EFH, Korrespondenz, Persönliche Dokumente
- Steffi has her own subfolders
- Sbroker has subfolders; file Sbroker docs into correct subfolder
- Jonas has own dental/medical subfolder

**Why:** Christian uses DT as raw-document archive (invoices, scans, contracts); Obsidian vault is curated knowledge. DT is the filing cabinet, vault is the brain.

**How to apply:** When triage/filing tasks come up for Downloads or DT inbox, follow this protocol. Always show numbered table, never auto-trash, never create groups without asking.
- Weekly reviews must be run interactively as a buddy session — NOT as a file-writing task.

Christian explicitly corrected this in session ec5a8004 (2026-05-29): 'I don't think that's what I had in mind. You should interactively run the review with me, not just write it into a file. Just do the review for us together interactively. I'll give you feedback, and you can update stuff: turn actions, create projects. That kind of one. You're my interactive weekly review buddy.'

**Format rules confirmed in same session:**
- Number all items — makes it easy to reference ('1', '2', '3'...)
- Before trashing/closing anything, show the item and let Christian decide
- Execute real changes: close Todoist tasks, create Jira tickets, update vault pages, move tasks to Someday

**Why:** File-writing is the wrong mode for weekly review — it becomes a one-way report. Buddy mode = collaborative, interactive, action-taking.

**How to apply:** When running /DailyReview, weekly-review, or any GTD review, always operate in interactive buddy mode. Never batch everything into a file and hand it over.
- Claude Code plugin install via SSH fails when SSH key not configured — use HTTPS via `gh` CLI instead.

Observed session 01bc61e2 (2026-05-27): `claude plugin install claude-obsidian@claude-obsidian-marketplace` failed with 'Permission denied (publickey)' even for public repos, because the Claude Code plugin installer clones via SSH (`git@github.com`). Fix: configure gh auth to use HTTPS (`gh config set git_protocol https`) or clone manually and install from local path.

Christian uses private repos via `gh` CLI — this overrides git SSH for gh commands but NOT for the Claude Code plugin installer's internal git clone.

**Why:** Non-obvious failure mode for plugin installs. Public repos fail too because the transport is SSH, not the repo visibility.

**How to apply:** If `claude plugin install` fails with SSH error, suggest: `gh config set git_protocol https && claude plugin install <name>` as the fix.

<!-- retro:managed:end -->
