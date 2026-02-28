# Flowstate

A Claude Code plugin that combines **strict development discipline** with **compounding knowledge**. Every cycle produces working code *and* accumulated insights that make the next cycle easier.

## Philosophy

Flowstate is inspired by ideas from several sources:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD enforcement, guided brainstorming, worktree isolation
- **[Compound Engineering](https://github.com/EveryInc/every-marketplace)** — Knowledge persistence, parallel multi-agent review, plan deepening
- **[Anthropic's prompting research](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering)** — Enforcement spectrum, progressive disclosure, context engineering, anti-rationalization patterns

None of these alone delivered what we wanted: strict development discipline *and* knowledge that compounds across sessions. Flowstate takes the ideas we liked from each and builds its own opinionated workflow.

## The Workflow

```
    ┌───────────────────────────────────────────────────────────────┐
    │                                                               │
    │  brainstorm → write-plan → [deepen] → work → review → compound
    │       ▲                       ▲                           │
    │       │                       │                           │
    │       └───────────────────────┴───────────────────────────┘
    │              knowledge feeds back into
    │           planning, reviewing, and building
    └───────────────────────────────────────────────────────────────┘
```

| Step | Command | What It Does |
|------|---------|--------------|
| 1 | `/workflow:brainstorm` | Guided design — one question at a time, explore approaches, validate decisions |
| 2 | `/workflow:write-plan` | Research agents + TDD implementation plan with exact file paths and test steps |
| 3 | `/workflow:deepen-plan` | *(optional)* Per-section parallel research to add depth, examples, edge cases |
| 4 | `/workflow:work` | Worktree isolation → subagent-per-task TDD → two-stage review → ship |
| 5 | `/workflow:review` | 5 parallel review agents (security, performance, simplicity, architecture, patterns) |
| 5b | `/workflow:deep-review` | Extended 14+ agent swarm with conditional reviewers |
| 6 | `/workflow:compound` | Capture learnings to `docs/solutions/` — searchable by future sessions |
| | `/workflow:debug` | 6-step systematic debugging with 3-strike escalation |
| | `/workflow:setup` | Show workflow pipeline, commands, and getting-started guide |
| | `/workflow:remind` | Re-inject core rules when Claude drifts from the workflow |

Every command can be used independently or as part of the full loop.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    COMMANDS (orchestrators)              │
│  brainstorm · write-plan · deepen-plan · work · review ·│
│  deep-review · compound · debug · setup · remind        │
│                         │                               │
│                    invoke ▼                              │
│              ┌──────────────────────┐                    │
│              │   SKILLS (16)        │                    │
│              │   Process knowledge  │                    │
│              │   HOW to do things   │                    │
│              └──────────────────────┘                    │
│                         │                               │
│                    dispatch ▼                            │
│              ┌──────────────────────┐                    │
│              │   AGENTS (10)        │                    │
│              │   Expert personas    │                    │
│              │   WHO does what      │                    │
│              └──────────────────────┘                    │
│                         │                               │
│                    enforced by ▼                         │
│              ┌──────────────────────┐                    │
│              │   HOOKS              │                    │
│              │   Session start:     │                    │
│              │   core rules always  │                    │
│              │   in context         │                    │
│              └──────────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

**Commands** are lean orchestrators (~8 lines each) that sequence skill invocations.
**Skills** contain all process knowledge — reusable, discoverable, independently invocable.
**Agents** are expert personas dispatched by skills for parallel work.
**Hooks** inject core rules (TDD, verification, brainstorm-before-build) into every session via `additionalContext`.

## The Compounding Flywheel

```
  ┌──────────────────────────────────────────────┐
  │                                              │
  │   BUILD ──────── solve problem ──────►       │
  │     ▲                                │       │
  │     │                                ▼       │
  │     │                           COMPOUND     │
  │     │                          write to      │
  │     │                        docs/solutions/ │
  │     │                                │       │
  │     │                                ▼       │
  │   LEARN ◄──── learnings-researcher ──┘       │
  │   check docs/solutions/ and                  │
  │   critical-patterns.md                       │
  │   before starting work                       │
  │                                              │
  └──────────────────────────────────────────────┘

  Each cycle makes the next one faster and better.
  Past mistakes become documented patterns.
  Solutions are searchable by problem type.
```

## Core Rules (Always Active)

These are injected into every session via the session-start hook:

- **TDD Iron Law** — No production code without a failing test first
- **Verification Before Completion** — No completion claims without fresh evidence
- **Brainstorm Before Build** — No implementation without exploring the design first
- **Subagent Distrust** — Reviewers read actual code, never trust implementer reports
- **Knowledge Compounding** — Check `docs/solutions/` before starting; capture learnings after finishing

## Installation

**Quick test** (single session):
```bash
claude --plugin-dir /path/to/flowstate
```

**Permanent install:**
```bash
# Add as a local marketplace
claude plugin marketplace add /path/to/flowstate

# Install
claude plugin install flowstate@flowstate-marketplace
```

**From GitHub:**
```bash
claude plugin marketplace add owner/flowstate
claude plugin install flowstate@flowstate-marketplace
```

**Update after changes:**
```bash
claude plugin update flowstate@flowstate-marketplace
```

## What It Creates In Your Project

```
your-project/
├── docs/
│   ├── brainstorms/          # Design documents from /workflow:brainstorm
│   ├── plans/                # Implementation plans from /workflow:write-plan
│   └── solutions/            # Captured learnings from /workflow:compound
│       ├── bugs/
│       ├── performance/
│       ├── best-practices/
│       └── patterns/
│           └── critical-patterns.md   # Promoted WRONG/CORRECT patterns
└── .worktrees/               # Git worktrees for isolated feature work
```

## Stats

- **16 skills** — brainstorming, TDD, planning, verification, debugging, code review, knowledge capture, and more
- **10 agents** — 5 research (repo analyst, learnings, best practices, framework docs, spec flow) + 5 review (security, performance, simplicity, architecture, patterns)
- **10 commands** — lean orchestrators that sequence the workflow
- **Language-agnostic** — works with any tech stack

## Model Allocation

| Role | Model | Count | Why |
|------|-------|-------|-----|
| Security review, spec-flow analysis, code quality review, solution extraction, prevention strategy | Opus | 5 | High-consequence reasoning where mistakes are costly |
| Implementer, architecture review, performance review, best practices, plan deepening | Sonnet | 8 | Strong structured analysis at 2-3x speed, near-Opus SWE-bench |
| Simplicity review, pattern review, repo research, learnings search, framework docs, brainstorm research, compound research, session-start, spec research | Haiku | 9 | Checklist-driven review + grep/classify — Haiku 4.5 matches or beats Sonnet on structured code review (Qodo benchmark) |

## License

[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — free for non-commercial use with attribution. Share-alike required for derivative works.
