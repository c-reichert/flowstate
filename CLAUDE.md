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

- Never create groups/folders in DevonThink without Christian's express permission. Only import files into existing groups he specifies.

**Why:** Christian interrupted mid-session explicitly: 'don't create groups without my express permission' (session ec5a8004, 2026-05-29).

**How to apply:** When filing documents into DevonThink via AppleScript/CLI, always ask which existing group to use. Never call `createGroup` or equivalent commands autonomously.
- DevonThink import workflow: after importing a file into DT, move the original file to '/Users/cr/Dropbox/DevonThink Actions - Imported'. This keeps Downloads clean and signals what has been processed.

**Why:** Christian established this in session ec5a8004 (2026-05-29): 'after anything has been imported into DT - move to the folder /Users/cr/Dropbox/DevonThink Actions - Imported'.

**How to apply:** Every DT import operation must be followed by a move of the source file to that Dropbox folder.
- When doing file triage and user requests more detail on a file, provide full detail and let Christian make the decision — do not truncate or make the call autonomously.

**Why:** Christian corrected this in session ec5a8004 (2026-05-29): 'if I want more detail, give me more detail and let me make the decision'.

**How to apply:** If a file looks ambiguous or user says 'more details please', expand the description fully (filename, content preview, dates, amounts, parties) before suggesting an action.

<!-- retro:managed:end -->
