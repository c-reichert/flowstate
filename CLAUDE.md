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

- resolution.de dev AWS account SSM Parameter Store secrets are in **us-east-1** (NOT eu-central-1). The dev account holds replicas of IT/prod secrets specifically for testing destructive Kubernetes cluster changes: prod secrets are copied to dev SSM, a temporary cluster replica is spun up in dev, changes are tested, then the cluster is removed.

**Why:** Christian explained: 'The SSM parameter store in the dev account in us-east-1 contains most of the same secrets as IT account us-east-1. That is where we pull up the cluster replica for development when needed.'

**How to apply:** When investigating resolution.de AWS secrets, always check dev account SSM in us-east-1. Don't query eu-central-1 for these secrets.

<!-- retro:managed:end -->
