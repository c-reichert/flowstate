---
name: deep-code-review
description: >
  Use for extended multi-agent review with 14+ agents including conditional
  and language-specific reviewers. Appropriate for large changes, architectural
  shifts, migrations, or when standard review is not thorough enough.
  Triggers: "deep review", "thorough review", "full review", "extended review",
  "review everything", "maximum coverage".
---

# Deep Multi-Agent Code Review

## Introduction

Extends the standard multi-agent review to 14+ agents by discovering all available reviewers and spawning conditional agents based on PR content. Use this for large changes, architectural shifts, migrations, or when you want maximum review coverage.

## Review Target

Determine what to review from the provided argument (PR number, branch name, or file paths).

**If no argument was provided, auto-detect:**

```bash
current_branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
fi
git diff $default_branch...$current_branch --stat
```

---

## Phase 1: Run Core Review

First, execute the full standard review process:

**Invoke the `multi-agent-review` skill** with the same review target. This spawns:
- security-reviewer (Opus)
- performance-reviewer (Opus)
- simplicity-reviewer (Sonnet)
- architecture-reviewer (Opus)
- pattern-reviewer (Sonnet)
- learnings-researcher (Haiku)

Collect all findings from the core review before proceeding.

---

## Phase 2: Discover Available Agents

Scan for all available review agents:

1. **Plugin agents** — check `agents/review/` for all agent files:
   ```bash
   ls agents/review/*.md 2>/dev/null
   ```

2. **Project-specific agents** — check for project-local agent configurations:
   ```bash
   ls .claude/agents/review/*.md 2>/dev/null
   ls .flowstate/agents/review/*.md 2>/dev/null
   ```

3. **CLAUDE.md configuration** — check for configured review agents:
   - Look for `review_agents:` or `deep_review_agents:` in CLAUDE.md
   - These may specify additional agents or disable default ones

Build a manifest of all available agents beyond the 5 core ones.

---

## Phase 3: Analyze PR Content for Conditional Agents

Analyze the diff to determine which conditional agents should run:

```bash
# Get list of changed files
git diff $default_branch...$current_branch --name-only
```

### Conditional Agent Triggers

| Trigger Condition | Agent to Spawn | Focus |
|-------------------|----------------|-------|
| Migration files present (`**/migrations/**`, `**/migrate/**`, schema changes) | **data-integrity-guardian** | Data loss risk, rollback safety, migration ordering, idempotency |
| Migration files present | **schema-drift-detector** | Schema consistency across environments, missing migrations, column type mismatches |
| Migration files present | **deployment-verification-agent** | Deploy ordering, zero-downtime migration strategy, feature flag requirements |
| Frontend files changed (`*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.css`) | **frontend-race-condition-reviewer** | Race conditions in state updates, stale closure bugs, unmounted component updates, concurrent fetch handling |
| Agent/tool/MCP files changed | **agent-native-reviewer** | Tool safety, prompt injection defense, context window management, error recovery |
| API endpoint changes | **api-contract-reviewer** | Breaking changes, versioning, backward compatibility, documentation drift |
| Test files only or test config changes | **test-quality-reviewer** | Flaky test patterns, mock overuse, missing edge cases, test isolation |

### Detection Logic

```bash
# Check for migrations
git diff $default_branch...$current_branch --name-only | grep -iE 'migrat|schema|\.sql'

# Check for frontend
git diff $default_branch...$current_branch --name-only | grep -iE '\.(tsx|jsx|vue|svelte|css|scss)$'

# Check for agent/tool changes
git diff $default_branch...$current_branch --name-only | grep -iE 'agent|tool|mcp|skill|prompt'

# Check for API changes
git diff $default_branch...$current_branch --name-only | grep -iE 'route|controller|endpoint|api|handler'

# Check for test-only changes
git diff $default_branch...$current_branch --name-only | grep -iE 'test|spec|__tests__'
```

---

## Phase 4: Spawn Extended Agents

### Language-Specific Reviewers

Detect primary languages from changed files and spawn language-specific reviewers:

```bash
# Detect languages from file extensions
git diff $default_branch...$current_branch --name-only | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

| Language | Reviewer Focus | Model |
|----------|---------------|-------|
| Python | Type safety, import organization, async patterns, Pythonic idioms | Sonnet |
| TypeScript/JavaScript | Type narrowing, null safety, promise handling, bundle size | Sonnet |
| Ruby/Rails | N+1 queries, callback complexity, concern organization, Rails conventions | Sonnet |
| Go | Error handling patterns, goroutine leaks, interface compliance, context propagation | Sonnet |
| Rust | Ownership patterns, lifetime management, unsafe usage, error handling | Sonnet |
| SQL | Query optimization, index usage, injection risk, transaction safety | Sonnet |

Only spawn reviewers for languages that appear in the diff.

### Conditional Agents

Spawn each triggered conditional agent in parallel:

```
For each triggered agent:
  Task [agent-name](diff, file_context, conventions)
    Model: Sonnet
    Provide: full diff, surrounding file context, CLAUDE.md conventions
    Return: findings with file:line references, severity, remediation
```

### All Extended Agents Run with Sonnet

Extended agents use Sonnet for bounded, focused checks. The core reviewers (Phase 1) already provide Opus-level depth for security, performance, and architecture.

---

## Phase 5: Synthesize Extended Findings

Merge extended agent findings with core review findings:

1. **Deduplicate** across all agents (core + extended may flag same issues)
2. **Assign priorities** using the same P1/P2/P3 scale from the multi-agent-review skill
3. **Create todo files** for new findings in `todos/` directory
4. **Flag cross-cutting concerns** that multiple agents independently identified

### Extended Summary

```markdown
## Deep Code Review Complete

**Branch:** [branch name]
**Core reviewers:** 5 agents (Opus/Sonnet)
**Extended reviewers:** [count] agents (Sonnet)
**Total reviewers:** [total count]
**Conditional agents triggered:** [list which and why]

### All Findings

| Priority | Core Review | Extended Review | Total |
|----------|-------------|-----------------|-------|
| P1 CRITICAL | [count] | [count] | [total] |
| P2 IMPORTANT | [count] | [count] | [total] |
| P3 NICE-TO-HAVE | [count] | [count] | [total] |

### Extended Agent Highlights
[Notable findings from conditional/language-specific agents that core review missed]

### Cross-Cutting Concerns
[Issues flagged by 3+ agents independently — high confidence]
```

---

## Phase 6: Resolve

Follow the same resolution protocol as the multi-agent-review skill:

1. **Fix P1s immediately** — blocks merge
2. **Triage P2/P3 with user** — fix now, defer, or won't fix
3. **Re-verify after fixes** — re-run affected agents
4. **Apply the Receiving Review Feedback Protocol** — READ, UNDERSTAND, VERIFY, EVALUATE, RESPOND, IMPLEMENT
5. **YAGNI check** on all suggestions — verify code is used before "improving" it

---

## Phase 7: Next Steps

After resolution is complete, suggest the following:

1. **Run `/workflow:compound`** to capture learnings from this review — document new patterns discovered, solutions applied, and any recurring issues for future sessions
2. **Run `/workflow:review`** on the fixes if substantial changes were made during resolution — fixes can introduce new issues
3. If the branch is ready, use the **`finishing-a-branch`** skill to merge or create a PR

---

## Reminders

- **Core review runs first** — deep review extends, not replaces
- **Conditional agents are smart** — they only run when relevant content is detected
- **Sonnet for extended agents** — Opus depth already covered by 5 core reviewers
- **Cross-cutting concerns deserve attention** — if 3+ agents flag the same issue, it's real
- **Language-specific reviewers** add precision that generalist agents miss
- **All findings go to todos/** — same tracking system as standard review
- **Capture learnings** — always run `/workflow:compound` after resolving review findings
