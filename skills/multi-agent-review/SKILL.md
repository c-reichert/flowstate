---
name: multi-agent-review
description: >
  Use when performing multi-agent code review after implementing features,
  before merging, or when reviewing PRs. Runs 5 core review agents in parallel
  plus a learnings researcher. Produces prioritized findings (P1/P2/P3) with
  todo files for tracking and resolution.
  Triggers: "review", "code review", "check before merge", "review PR",
  "run reviewers", "catch issues".
---

# Multi-Agent Code Review

## Introduction

Run 5 specialized review agents in parallel plus the learnings researcher to catch issues before they ship. Each agent brings a different lens — security, performance, simplicity, architecture, and patterns. Findings are synthesized, deduplicated, prioritized, and tracked as todo files.

## Review Target

Determine what to review from the provided argument (PR number, branch name, or file paths).

**If no argument was provided, auto-detect:**

```bash
# Check if we're on a feature branch with changes
current_branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
fi

# Get the diff
git diff $default_branch...$current_branch --stat
```

If there are changes, ask: "Review changes on `[branch]` against `[default_branch]`?"
If no changes found, ask: "What should I review? Provide a PR number, branch, or file paths."

---

## Phase 1: Spawn Reviewers in Parallel

Launch all 6 agents simultaneously. Each reviewer receives:

- **PR diff** — the complete set of changes being reviewed
- **File context** — surrounding code for modified files (not just the diff lines)
- **CLAUDE.md conventions** — project-specific rules, naming, patterns

### The 5 Core Reviewers + Learnings Researcher

```
Spawn in parallel:

├── Task security-reviewer(diff, file_context, conventions)
│   Model: Opus
│   Focus: OWASP top 10, injection attacks, authentication flaws,
│          authorization bypasses, secrets in code, sensitive data exposure,
│          CSRF/XSS/SSRF vectors, insecure deserialization, cryptographic
│          weaknesses, SQL injection, command injection
│   Output: Executive Summary, Detailed Findings (file:line), Risk Matrix,
│           Remediation guidance with code examples
│
├── Task performance-reviewer(diff, file_context, conventions)
│   Model: Opus
│   Focus: Algorithmic complexity (Big O), N+1 queries, missing indexes,
│          caching opportunities, memory usage patterns, unnecessary
│          allocations, network call optimization, lazy loading opportunities,
│          database query analysis, connection pooling
│   Output: Performance Summary, Critical Issues, Optimization Opportunities
│           with expected impact estimates
│
├── Task simplicity-reviewer(diff, file_context, conventions)
│   Model: Sonnet
│   Focus: YAGNI violations, unnecessary abstractions, over-engineering,
│          readability issues, unnecessary complexity, dead code, commented-out
│          code, premature optimization, abstract classes with one subclass,
│          factory patterns for one type, interfaces implemented once
│   CRITICAL: Never flag docs/plans/ or docs/solutions/ for removal
│   Output: Unnecessary Complexity Found, Code to Remove, YAGNI Violations,
│           Simplification suggestions with before/after examples
│
├── Task architecture-reviewer(diff, file_context, conventions)
│   Model: Opus
│   Focus: Component boundaries, dependency direction (no upward deps),
│          circular dependencies, abstraction levels, API contract stability,
│          separation of concerns, layer violations, coupling analysis,
│          cohesion assessment, design pattern consistency
│   Output: Architecture Overview, Change Assessment, Compliance Check,
│           Risk Analysis, dependency graph concerns
│
├── Task pattern-reviewer(diff, file_context, conventions)
│   Model: Sonnet
│   Focus: Anti-patterns (God objects, circular deps, primitive obsession),
│          naming convention consistency, code duplication (3+ occurrences),
│          design pattern misuse, inconsistent error handling, mixed
│          abstraction levels within functions, convention violations
│   Output: Pattern Usage Report, Anti-Pattern Locations, Naming Analysis,
│           Duplication Metrics
│
└── Task learnings-researcher(diff_summary, file_context)
    Model: Haiku
    Focus: Search docs/solutions/ for relevant past solutions that apply
           to this code change. Surface known patterns, past mistakes,
           and documented best practices.
    Always check: docs/solutions/patterns/critical-patterns.md
    Output: Relevant learnings with file paths and key insights,
            flagged as "Known Pattern" when applicable
```

---

## Phase 2: Synthesize Findings

Collect all agent outputs. For each finding:

### Priority Assignment

| Priority | Criteria | Action |
|----------|----------|--------|
| **P1 CRITICAL** | Blocks merge. Security vulnerability, data loss risk, correctness bug, breaking change. | **Must fix** before merge |
| **P2 IMPORTANT** | Should fix. Performance issue, maintainability concern, missing error handling, incomplete edge case. | **Should fix** — triage with user |
| **P3 NICE-TO-HAVE** | Could improve. Style suggestion, minor optimization, readability tweak, documentation gap. | **Optional** — address if time permits |

### Deduplication

- Multiple agents may flag the same issue from different angles
- Merge overlapping findings into a single finding with the highest priority
- Note which agents flagged it (increases confidence)

### Learnings Integration

- When learnings-researcher finds a relevant past solution, mark the finding as:
  ```
  **Known Pattern:** See docs/solutions/[path] — [one-line summary]
  ```
- This helps the team see that the issue has been encountered and solved before

### Effort Estimation

For each finding, estimate fix effort:
- **Small** — under 30 minutes, localized change
- **Medium** — 1-2 hours, touches multiple files
- **Large** — half day+, architectural change needed

---

## Phase 3: Create Todo Files

For each finding, create a tracking file:

```bash
mkdir -p todos/
```

**Filename format:** `{id}-pending-{priority}-{description}.md`

Examples:
- `001-pending-p1-sql-injection-user-input.md`
- `002-pending-p2-missing-index-orders-table.md`
- `003-pending-p3-rename-helper-method.md`

**Todo file structure:**

```markdown
---
status: pending
priority: p1|p2|p3
issue_id: NNN
tags: [code-review, security|performance|simplicity|architecture|patterns]
reviewer: [which agent(s) flagged this]
effort: small|medium|large
---

## Problem Statement
[Clear description of the issue]

## Findings
[Detailed evidence with file:line references]

### Evidence
- `file.py:42` — [specific issue observed]
- `file.py:78` — [related issue]

### Impact
[What happens if this isn't fixed]

## Proposed Solutions

### Option A: [Preferred approach]
- Pros: [advantages]
- Cons: [disadvantages]
- Effort: [estimate]

### Option B: [Alternative approach]
- Pros: [advantages]
- Cons: [disadvantages]
- Effort: [estimate]

## Acceptance Criteria
- [ ] [Specific verifiable criterion]
- [ ] [Test that proves the fix works]

## Known Patterns
[If learnings-researcher found related docs/solutions/ entries, reference them here]
```

---

## Phase 4: Present Summary

```markdown
## Code Review Complete

**Branch:** [branch name]
**Reviewers:** 5 core agents + learnings researcher
**Files reviewed:** [count]

### Findings Summary

| Priority | Count | Description |
|----------|-------|-------------|
| P1 CRITICAL | [count] | [brief list] |
| P2 IMPORTANT | [count] | [brief list] |
| P3 NICE-TO-HAVE | [count] | [brief list] |
| **Total** | **[total]** | |

### Created Todo Files
**P1 (must fix):**
- `todos/001-pending-p1-[description].md`

**P2 (should fix):**
- `todos/002-pending-p2-[description].md`

**P3 (nice to have):**
- `todos/003-pending-p3-[description].md`

### Known Patterns from Past Work
- [Learning title] (docs/solutions/[path]) — [applies to finding #N]

### Next Steps
1. **Address P1 findings** (MUST fix before merge)
2. **Triage P2/P3 findings** with reviewer
3. **Run `/workflow:compound`** to capture any new learnings
```

---

## Phase 5: Resolve Findings

### Fix P1s Immediately

P1 findings block merge. Fix them now:

1. For each P1 finding, implement the fix
2. Run tests to verify the fix
3. Update the todo file: `status: pending` to `status: resolved`
4. Rename the file: `pending` to `resolved`
5. Commit the fix

### Triage P2/P3 with User

Present P2 and P3 findings. For each, the user decides:
- **Fix now** — implement the fix in this PR
- **Create follow-up** — track as a separate task for later
- **Won't fix** — mark as `status: wont-fix` with reason

### Re-Verify After Fixes

After fixing P1s (and any P2/P3 the user chose to fix):
- Re-run the affected reviewer(s) on the fixed code
- Verify the finding is resolved
- Update todo files

---

## Applying Review Findings

When applying findings from the review agents, use the **`receiving-code-review`** skill for the full protocol:
- READ -> UNDERSTAND -> VERIFY -> EVALUATE -> RESPOND -> IMPLEMENT
- YAGNI check before implementing any suggestion
- Push back with technical reasoning when warranted
- Implementation order: clarify first, blocking issues, simple fixes, complex fixes

When structuring what reviewers need, see the **`requesting-code-review`** skill for:
- What to provide (SHA range, description, plan reference)
- Expected output format (Strengths, Issues by severity, Assessment)

---

## Reminders

- **5 core reviewers + learnings researcher** — always run all 6 in parallel
- **P1 blocks merge** — no exceptions
- **Learnings integration** — flag known patterns from docs/solutions/
- **Todo files** — every finding becomes a trackable file in todos/
- **Push back is healthy** — not every suggestion improves the code (see `receiving-code-review` skill)
- **YAGNI check** — verify code is actually used before "improving" it (see `receiving-code-review` skill)
- **Re-verify after fixes** — fixes can introduce new issues
