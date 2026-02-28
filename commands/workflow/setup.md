---
name: workflow:setup
description: "Learn how Flowstate works — shows the workflow pipeline, available commands, and getting-started guide."
disable-model-invocation: true
---

Present the following information to the user clearly and concisely:

## What is Flowstate?

Flowstate is a Claude Code plugin that combines strict development discipline with compounding knowledge. It enforces TDD, multi-agent code review, and structured brainstorming across every development cycle. Each cycle produces working code *and* accumulated insights that make the next cycle faster and better.

## Workflow Pipeline

```
brainstorm → write-plan → [deepen-plan] → work → review → compound
```

Each step feeds into the next. Knowledge captured during compounding flows back into future planning, reviewing, and building.

## Available Commands

| Command | Description |
|---------|-------------|
| `/workflow:brainstorm` | Guided design session — explores requirements through one-at-a-time questions, proposes approaches, validates decisions |
| `/workflow:write-plan` | Transform a brainstorm into an actionable TDD implementation plan with research agents |
| `/workflow:deepen-plan` | *(optional)* Enhance a plan with parallel research per section — adds depth, examples, edge cases |
| `/workflow:work` | Execute a plan with TDD, worktree isolation, subagent dispatch, two-stage review, and shipping |
| `/workflow:review` | 5 parallel review agents (security, performance, simplicity, architecture, patterns) |
| `/workflow:deep-review` | Extended 14+ agent review swarm with conditional and language-specific reviewers |
| `/workflow:compound` | Capture learnings to `docs/solutions/` — searchable by future sessions |
| `/workflow:debug` | 6-step systematic debugging with 3-strike escalation |
| `/workflow:setup` | This guide — shows the workflow pipeline and available commands |
| `/workflow:remind` | Re-inject core rules if Claude drifts from the workflow |

## Getting Started

Run `/workflow:brainstorm` to start a guided design session for a new feature, or `/workflow:debug` if you're fixing a bug.

## Core Rules

The session-start hook automatically injects core rules (TDD Iron Law, Verification Before Completion, Brainstorm Before Build, Subagent Distrust, Knowledge Compounding) into every session. You don't need to do anything — they're always active.

**Tip:** Run `/workflow:remind` if I start drifting from the workflow or forget the pipeline order.
