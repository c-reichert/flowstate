---
name: workflow:remind
description: "Re-inject Flowstate's core rules and workflow summary. Use when Claude drifts from the workflow or forgets the pipeline order."
disable-model-invocation: true
---

CONTEXT INJECTION — Read and internalize the following rules immediately.

## Workflow Pipeline

```
brainstorm → write-plan → [deepen-plan] → work → review → compound
```

Each step feeds into the next. Do not skip steps. Review and compound are mandatory after work.

## Core Rules (Always Active)

### TDD Iron Law
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.
Cycle: RED (write failing test) → VERIFY RED (run it, see it fail) → GREEN (minimal code to pass) → VERIFY GREEN (run it, see it pass) → REFACTOR.
If you didn't watch the test fail, you don't know if it tests the right thing.
Exceptions ONLY with explicit user permission: throwaway prototypes, generated code, config files.

### Verification Before Completion
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.
Before claiming any status: (1) Identify verification command, (2) Run it fresh, (3) Read complete output, (4) Only then state results.
If you haven't run the command in THIS message, you cannot claim it passes.

### Brainstorm Before Build
Do NOT implement, write code, scaffold, or create files until the user's idea has been explored through brainstorming and a design exists. Every project goes through the process — "too simple" is rationalization.

### Subagent Distrust
Do not trust implementer reports. Read actual code. The implementer may have finished suspiciously quickly. Spec reviewers must independently verify.

### Knowledge Compounding
After solving non-trivial problems, capture learnings in docs/solutions/ via `/workflow:compound`. Check docs/solutions/ and critical-patterns.md before starting work — past solutions prevent repeated mistakes.

## Available Commands

| Command | Description |
|---------|-------------|
| `/workflow:brainstorm` | Guided design session |
| `/workflow:write-plan` | Create TDD implementation plan |
| `/workflow:deepen-plan` | Enhance plan with parallel research |
| `/workflow:work` | Execute plan with TDD and subagents |
| `/workflow:review` | 5-agent parallel code review |
| `/workflow:deep-review` | Extended 14+ agent review |
| `/workflow:compound` | Capture learnings |
| `/workflow:debug` | Systematic debugging |
| `/workflow:setup` | Show workflow guide |
| `/workflow:remind` | This command — re-inject rules |

IMPORTANT: The `/workflow:write-plan` command is NOT Claude Code's built-in plan mode. Do NOT call EnterPlanMode or ExitPlanMode. The write-plan command invokes the flowstate:planning skill to create a TDD implementation plan document.

Acknowledge these rules and confirm you understand the current workflow state.
