# Flowstate

A Claude Code plugin that combines **strict development discipline** with **compounding knowledge**. Every cycle produces working code *and* accumulated insights that make the next cycle easier.

## Philosophy

Two existing plugins each solve half the problem:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD enforcement, guided brainstorming, worktree isolation. Excellent discipline, but all session learning is lost when the context ends.
- **[Compound Engineering](https://github.com/EveryInc/every-marketplace)** — Knowledge persistence via `docs/solutions/`, parallel multi-agent review, plan deepening. Excellent compounding, but no strict TDD or guided design flow.

Flowstate merges both: the discipline to write quality code *and* the infrastructure to learn from every session.

## The Workflow

```
brainstorm → plan → [deepen] → work → review → compound
                                          ↑           |
                                          └───────────┘
                                        knowledge feeds back
```

| Step | Command | What It Does |
|------|---------|--------------|
| 1 | `/flowstate:brainstorm` | Guided design — one question at a time, explore approaches, validate decisions |
| 2 | `/flowstate:plan` | Research agents + TDD implementation plan with exact file paths and test steps |
| 3 | `/flowstate:deepen-plan` | *(optional)* Per-section parallel research to add depth, examples, edge cases |
| 4 | `/flowstate:work` | Worktree isolation → subagent-per-task TDD → two-stage review → ship |
| 5 | `/flowstate:review` | 5 parallel review agents (security, performance, simplicity, architecture, patterns) |
| 5b | `/flowstate:deep-review` | Extended 14+ agent swarm with conditional reviewers |
| 6 | `/flowstate:compound` | Capture learnings to `docs/solutions/` — searchable by future sessions |
| | `/flowstate:debug` | 6-step systematic debugging with 3-strike escalation |

Every command can be used independently or as part of the full loop.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    COMMANDS (orchestrators)              │
│  brainstorm · plan · deepen-plan · work · review ·      │
│  deep-review · compound · debug                         │
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
│   ├── brainstorms/          # Design documents from /flowstate:brainstorm
│   ├── plans/                # Implementation plans from /flowstate:plan
│   └── solutions/            # Captured learnings from /flowstate:compound
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
- **8 commands** — lean orchestrators that sequence the workflow
- **Language-agnostic** — works with any tech stack

## Model Allocation

| Role | Model | Why |
|------|-------|-----|
| User-facing dialogue, code writing | Opus | Quality matters for creative work |
| Security, performance, architecture review | Opus | Deep reasoning required |
| Simplicity, pattern review | Sonnet | Bounded judgment calls |
| Learnings search, framework docs | Haiku | Mechanical grep + classify |

## License

MIT
