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

<!-- retro:managed:start -->
## Retro-Discovered Patterns

- Flowstate rules, directives, and skill instructions should always include a 'Why' explanation — not just the rule itself. Christian stated this explicitly in session 4704fd03: 'Another one I think was to include the why in rules.' This is consistent with Anthropic's Opus 4.6 prompting recommendation to provide reasoning context.

**Why:** Rules with 'why' help agents make better edge-case judgments instead of blindly following instructions they don't understand.

**How to apply:** When writing or updating any flowstate SKILL.md rule, add a **Why:** line after the rule statement, explaining the motivation or the incident that prompted it.
- When adding comments to Jira via MCP (addCommentToJiraIssue), the call frequently times out. If the comment fails or times out, provide the full comment text as output so Christian can paste it manually.

**Why:** Christian explicitly noted 'The MCP always seems to time out' when trying to add a comment in session 68f7c469. Retrying blindly wastes time.

**How to apply:** After any failed Jira comment MCP call, immediately output the formatted comment text with an instruction to paste it manually.

<!-- retro:managed:end -->
