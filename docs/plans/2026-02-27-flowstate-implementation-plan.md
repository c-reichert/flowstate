# Flowstate Plugin Implementation Plan

> **For Claude:** Implement this plan task-by-task. Each task is self-contained. Verify each step before moving on.

**Goal:** Build a complete Claude Code plugin called `flowstate` that combines Superpowers' TDD discipline with Compound Engineering's knowledge compounding.

**Architecture:** Claude Code plugin with skills (process guides), agents (expert personas), commands (entry points), and hooks (lifecycle events). All files are markdown with YAML frontmatter — this is prompt engineering, not traditional code.

**Tech Stack:** Markdown, YAML, JSON, shell scripts. No runtime dependencies.

**Design doc:** `docs/plans/2026-02-27-flowstate-plugin-design.md`

---

## Task 1: Plugin Scaffolding

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

**Step 1: Create plugin manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "flowstate",
  "version": "0.1.0",
  "description": "Hybrid development workflow combining TDD discipline with knowledge compounding. 10 agents, 7 commands, 4 skills for brainstorming, planning, TDD execution, multi-agent review, and learning capture.",
  "author": {
    "name": "Christian"
  },
  "repository": "https://github.com/cr/flowstate",
  "license": "MIT",
  "keywords": [
    "tdd", "compound-engineering", "workflow-automation",
    "code-review", "knowledge-management", "brainstorming",
    "git-worktrees", "multi-agent"
  ]
}
```

**Step 2: Create marketplace manifest**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "flowstate-marketplace",
  "description": "Marketplace for the Flowstate plugin",
  "owner": {
    "name": "Christian"
  },
  "plugins": [
    {
      "name": "flowstate",
      "description": "Hybrid development workflow combining TDD discipline with knowledge compounding.",
      "version": "0.1.0",
      "source": "./"
    }
  ]
}
```

**Step 3: Create directory structure**

```bash
mkdir -p skills/brainstorming
mkdir -p skills/tdd
mkdir -p skills/compound/assets
mkdir -p skills/using-worktrees
mkdir -p agents/research
mkdir -p agents/review
mkdir -p commands
mkdir -p hooks
```

**Step 4: Verify**

```bash
find . -type d | sort
```

Expected: all directories exist.

**Step 5: Commit**

```bash
git add .claude-plugin/ skills/ agents/ commands/ hooks/
git commit -m "chore: scaffold flowstate plugin directory structure"
```

---

## Task 2: Brainstorming Skill

**Files:**
- Create: `skills/brainstorming/SKILL.md`

**Step 1: Write the brainstorming skill**

This is the longest skill — it defines the 7-phase guided design process. Source from design doc Section "Step 1: Brainstorm".

Key elements to include:
- YAML frontmatter: `name: brainstorming`, `description` with trigger words
- Hard gate on implementation (using `<HARD-GATE>` tags)
- Anti-pattern warning ("too simple to need a design")
- Phase 0: Assess clarity (skip gate)
- Phase 1: Lightweight repo research (Sonnet subagent)
- Phase 2: Collaborative dialogue (one question at a time via AskUserQuestion)
- Phase 3: Propose 2-3 approaches
- Phase 4: Present design section by section
- Phase 5: Open Questions hard gate
- Phase 6: Save to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`
- Phase 7: Transition options (plan / refine / ask more / done)
- Output template (What/Why/Decisions/Open Questions/Resolved Questions)
- Checklist of tasks to create via TaskCreate

Reference: Superpowers `brainstorming` skill for hard gate pattern, Compound Engineering `/workflows:brainstorm` for phase structure and AskUserQuestion enforcement.

**Step 2: Verify YAML frontmatter is valid**

```bash
head -5 skills/brainstorming/SKILL.md
```

Expected: valid `---` delimited YAML with `name` and `description`.

**Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: add brainstorming skill with guided design workflow"
```

---

## Task 3: TDD Skill

**Files:**
- Create: `skills/tdd/SKILL.md`

**Step 1: Write the TDD skill**

This defines the strict test-driven development enforcement. Source from design doc "TDD Enforcement" section.

Key elements to include:
- YAML frontmatter: `name: tdd`, `description` referencing when to use
- The Iron Law: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
- RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR cycle
- Full rationalization defense table (9 excuses + rebuttals)
- Red flags requiring restart (14 items)
- Verification checklist (8 items)
- Delete-and-restart enforcement language
- Final rule: "Production code → test exists and failed first. Otherwise → not TDD."

Reference: Superpowers `test-driven-development` skill (adopt wholesale, this is the strongest part of Superpowers).

**Step 2: Verify YAML frontmatter**

```bash
head -5 skills/tdd/SKILL.md
```

**Step 3: Commit**

```bash
git add skills/tdd/SKILL.md
git commit -m "feat: add TDD skill with strict test-first enforcement"
```

---

## Task 4: Using-Worktrees Skill

**Files:**
- Create: `skills/using-worktrees/SKILL.md`

**Step 1: Write the worktrees skill**

Defines worktree creation and management for feature isolation. Source from design doc work phase + Superpowers `using-git-worktrees` skill.

Key elements to include:
- YAML frontmatter: `name: using-worktrees`, `description`
- When to create a worktree (start of work phase, after plan approval)
- Creation flow:
  1. Create `.worktrees/` directory
  2. Verify `.worktrees/` is in `.gitignore`
  3. `git worktree add .worktrees/<feature> -b feature/<feature-name>`
  4. Auto-detect and run project setup (npm install, pip install, uv sync, etc.)
  5. Run tests to verify clean baseline
- Cleanup flow:
  1. Verify all tests pass
  2. `git worktree remove .worktrees/<feature>`
  3. Optionally delete branch: `git branch -d feature/<feature-name>`
- The golden rule: one branch per worktree
- Gotchas: submodules, dependency re-install, disk space

Reference: Superpowers `using-git-worktrees` skill + Compound Engineering `git-worktree` skill.

**Step 2: Verify YAML frontmatter**

```bash
head -5 skills/using-worktrees/SKILL.md
```

**Step 3: Commit**

```bash
git add skills/using-worktrees/SKILL.md
git commit -m "feat: add worktree skill for isolated feature development"
```

---

## Task 5: Compound Skill + Schema + Templates

**Files:**
- Create: `skills/compound/SKILL.md`
- Create: `skills/compound/schema.yaml`
- Create: `skills/compound/assets/resolution-template.md`
- Create: `skills/compound/assets/critical-pattern-template.md`

**Step 1: Write the compound skill**

Defines the knowledge capture process. Source from design doc "Step 6: Compound".

Key elements to include:
- YAML frontmatter: `name: compound`, `description`
- Phase 1: Parallel capture (5 subagents with model assignments)
  - Context Analyzer (Haiku): extract problem type, component, symptoms → YAML skeleton
  - Solution Extractor (Opus): root cause, solution with code examples
  - Related Docs Finder (Haiku): grep docs/solutions/ for related docs
  - Prevention Strategist (Opus): prevention strategies, best practices
  - Category Classifier (Haiku): category, filename suggestion
  - All return TEXT ONLY — no files written by subagents
- Phase 2: Assemble and write
  - Validate frontmatter against schema.yaml
  - Create directory: `docs/solutions/[category]/`
  - Write single file using resolution template
- Phase 3: Decision menu via AskUserQuestion
  1. Continue workflow
  2. Add to Required Reading (promote to critical-patterns.md)
  3. Link related documentation
  4. View documentation
  5. Other
- Smart suggestion for promotion (severity: critical, multi-module, non-obvious)
- Phase 4: Critical pattern promotion (if selected)
  - Extract pattern → format as WRONG vs CORRECT → append to critical-patterns.md
- Reference to schema.yaml for validation
- Reference to templates in assets/

**Step 2: Write the YAML schema**

Create `skills/compound/schema.yaml` with all enum definitions from design doc:
- problem_type (13 values)
- resolution_type (7 values)
- severity (4 values)
- Category mapping (problem_type → directory path)

**Step 3: Write the resolution template**

Create `skills/compound/assets/resolution-template.md` with the full document template from design doc.

**Step 4: Write the critical pattern template**

Create `skills/compound/assets/critical-pattern-template.md` with the WRONG vs CORRECT format.

**Step 5: Verify all files exist**

```bash
ls -la skills/compound/SKILL.md skills/compound/schema.yaml skills/compound/assets/
```

**Step 6: Commit**

```bash
git add skills/compound/
git commit -m "feat: add compound skill with schema and templates for knowledge capture"
```

---

## Task 6: Research Agents (5 agents)

**Files:**
- Create: `agents/research/repo-research-analyst.md`
- Create: `agents/research/learnings-researcher.md`
- Create: `agents/research/best-practices-researcher.md`
- Create: `agents/research/framework-docs-researcher.md`
- Create: `agents/research/spec-flow-analyzer.md`

**Step 1: Write repo-research-analyst agent**

YAML frontmatter: `name`, `description`, `model: sonnet`. Expert persona that scans the codebase for existing patterns, conventions, and similar implementations. Returns: relevant file paths, patterns found, CLAUDE.md guidance.

**Step 2: Write learnings-researcher agent**

YAML frontmatter: `name`, `description`, `model: haiku`. Grep-first filtering strategy:
1. Extract keywords from feature description
2. Parallel grep calls on docs/solutions/ (by title, tags, module, component)
3. Always check docs/solutions/patterns/critical-patterns.md
4. Read frontmatter of grep-matched files
5. Score and rank relevance (strong/moderate/weak)
6. Full read of relevant files only
7. Return distilled summaries with file paths, relevance, key insights

This is the most critical agent for the compounding flywheel. Source from Compound Engineering `learnings-researcher` agent.

**Step 3: Write best-practices-researcher agent**

YAML frontmatter: `name`, `description`, `model: sonnet`. Searches external sources for industry standards, real-world examples, community best practices. Uses WebSearch and WebFetch tools.

**Step 4: Write framework-docs-researcher agent**

YAML frontmatter: `name`, `description`, `model: haiku`. Uses Context7 MCP to look up framework documentation. Resolve library ID → query docs → return relevant snippets.

**Step 5: Write spec-flow-analyzer agent**

YAML frontmatter: `name`, `description`, `model: opus`. Maps user flows, identifies missing error handling, finds edge cases and ambiguities, validates acceptance criteria. Returns: flow map, edge cases, missing handling, questions for clarification.

**Step 6: Verify all agents exist**

```bash
ls agents/research/
```

Expected: 5 .md files.

**Step 7: Commit**

```bash
git add agents/research/
git commit -m "feat: add 5 research agents (repo, learnings, best-practices, framework-docs, spec-flow)"
```

---

## Task 7: Review Agents (5 core agents)

**Files:**
- Create: `agents/review/security-reviewer.md`
- Create: `agents/review/performance-reviewer.md`
- Create: `agents/review/simplicity-reviewer.md`
- Create: `agents/review/architecture-reviewer.md`
- Create: `agents/review/pattern-reviewer.md`

**Step 1: Write security-reviewer agent**

YAML frontmatter: `name`, `description`, `model: opus`. Expert persona: Elite Application Security Specialist. Scans for: OWASP top 10, injection attacks, auth flaws, secrets in code, sensitive data exposure. Output: Executive Summary, Detailed Findings (with file:line), Risk Matrix, Remediation guidance.

Reference: Compound Engineering `security-sentinel` agent.

**Step 2: Write performance-reviewer agent**

YAML frontmatter: `name`, `description`, `model: opus`. Expert persona: Performance Optimization Expert. Analyzes: algorithmic complexity (Big O), N+1 queries, missing indexes, caching opportunities, memory usage, network optimization. Output: Performance Summary, Critical Issues, Optimization Opportunities.

Reference: Compound Engineering `performance-oracle` agent.

**Step 3: Write simplicity-reviewer agent**

YAML frontmatter: `name`, `description`, `model: sonnet`. Expert persona: Code Simplicity Expert. Enforces: YAGNI, flags unnecessary abstractions, checks readability, questions every line's necessity, challenges premature abstractions. CRITICAL: Never flag docs/plans/ or docs/solutions/ for removal. Output: Unnecessary Complexity Found, Code to Remove, YAGNI Violations.

Reference: Compound Engineering `code-simplicity-reviewer` agent.

**Step 4: Write architecture-reviewer agent**

YAML frontmatter: `name`, `description`, `model: opus`. Expert persona: System Architecture Expert. Evaluates: component boundaries, dependency direction, circular dependencies, abstraction levels, API contract stability, design pattern consistency. Output: Architecture Overview, Change Assessment, Compliance Check, Risk Analysis.

Reference: Compound Engineering `architecture-strategist` agent.

**Step 5: Write pattern-reviewer agent**

YAML frontmatter: `name`, `description`, `model: sonnet`. Expert persona: Code Pattern Analysis Expert. Detects: design patterns (Factory, Singleton, Observer), anti-patterns (God objects, circular deps), naming convention consistency, code duplication. Output: Pattern Usage Report, Anti-Pattern Locations, Naming Analysis, Duplication Metrics.

Reference: Compound Engineering `pattern-recognition-specialist` agent.

**Step 6: Verify all agents exist**

```bash
ls agents/review/
```

Expected: 5 .md files.

**Step 7: Commit**

```bash
git add agents/review/
git commit -m "feat: add 5 core review agents (security, performance, simplicity, architecture, patterns)"
```

---

## Task 8: Brainstorm Command

**Files:**
- Create: `commands/brainstorm.md`

**Step 1: Write the brainstorm command**

```markdown
---
name: brainstorm
description: "Start a guided design session. Explores requirements through one-at-a-time questions, proposes approaches, and produces a validated design document. Use before any implementation work."
disable-model-invocation: true
argument-hint: "[feature description or idea]"
---

Invoke the flowstate:brainstorming skill for: $ARGUMENTS
```

**Step 2: Verify**

```bash
cat commands/brainstorm.md
```

**Step 3: Commit**

```bash
git add commands/brainstorm.md
git commit -m "feat: add /flowstate:brainstorm command"
```

---

## Task 9: Plan Command

**Files:**
- Create: `commands/plan.md`

**Step 1: Write the plan command**

This is the most complex command — it orchestrates multiple agents and produces TDD-structured tasks. Source from design doc "Step 2: Plan".

Key elements:
- YAML frontmatter: `name: plan`, `description`, `disable-model-invocation: true`
- Phase 0: Auto-detect brainstorm from docs/brainstorms/
- Phase 1: Spawn parallel local research (learnings-researcher + repo-research-analyst)
- Phase 2: Conditional external research decision tree
- Phase 3: Spec-flow analysis (Opus subagent)
- Phase 4: Consolidate research
- Phase 5: Write plan with TDD-structured tasks (detail level: MINIMAL/MORE/A LOT)
- Phase 6: Save to docs/plans/
- Phase 7: Offer options (deepen / work / refine / done)
- Task template with RED→GREEN→REFACTOR steps
- Learnings integration ("avoid X, see docs/solutions/...")

**Step 2: Verify**

```bash
head -10 commands/plan.md
```

**Step 3: Commit**

```bash
git add commands/plan.md
git commit -m "feat: add /flowstate:plan command with learnings integration and TDD tasks"
```

---

## Task 10: Deepen-Plan Command

**Files:**
- Create: `commands/deepen-plan.md`

**Step 1: Write the deepen-plan command**

Source from design doc "Step 3: Deepen Plan". Orchestrates parallel research agents per plan section.

Key elements:
- YAML frontmatter: `name: deepen-plan`, `description`
- Phase 1: Parse plan structure into section manifest
- Phase 2: Per-section parallel research (Sonnet agents)
- Phase 3: Learnings discovery from docs/solutions/ (Haiku agents)
- Phase 4: Enhance plan sections (add best practices, edge cases, code examples)
- Phase 5: Add enhancement summary to top of plan
- Phase 6: Update plan file in place
- Context7 MCP usage for framework docs
- WebSearch for current best practices
- Does NOT run review agents (save for /flowstate:review)
- Does NOT rewrite — only adds

**Step 2: Verify**

```bash
head -10 commands/deepen-plan.md
```

**Step 3: Commit**

```bash
git add commands/deepen-plan.md
git commit -m "feat: add /flowstate:deepen-plan command for parallel research enhancement"
```

---

## Task 11: Work Command

**Files:**
- Create: `commands/work.md`

**Step 1: Write the work command**

The main execution orchestrator. Source from design doc "Step 4: Work".

Key elements:
- YAML frontmatter: `name: work`, `description`, `disable-model-invocation: true`
- Phase 1: Setup
  - Read plan completely, ask clarifying questions
  - Invoke using-worktrees skill → create worktree, install deps, verify baseline
  - Create TodoWrite with all tasks from plan
- Phase 2: Per-task execution loop
  - Dispatch implementer subagent (Opus) with full task text
  - TDD cycle: RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR
  - Reference tdd skill for enforcement rules
  - Spec compliance review (Sonnet subagent) — "do not trust the report"
  - Code quality review (Opus subagent) — only after spec passes
  - Incremental commit heuristic
  - Update plan checkboxes and TodoWrite
- Phase 3: Verification gate
  - verification-before-completion pattern
  - Fresh evidence required, no premature claims
  - Red flag detection
- Phase 4: Ship
  - Final commit, push, create PR
  - Update plan status to completed
- Subagent prompt templates (inline or referenced):
  - Implementer: full task text + context + TDD instructions + self-review checklist
  - Spec reviewer: "read actual code, not implementer report" + distrust pattern
  - Quality reviewer: strengths/issues/assessment format

**Step 2: Verify**

```bash
head -10 commands/work.md
```

**Step 3: Commit**

```bash
git add commands/work.md
git commit -m "feat: add /flowstate:work command with TDD execution and two-stage review"
```

---

## Task 12: Review + Deep-Review Commands

**Files:**
- Create: `commands/review.md`
- Create: `commands/deep-review.md`

**Step 1: Write the review command**

Source from design doc "Step 5: Review".

Key elements:
- YAML frontmatter: `name: review`, `description`
- Phase 1: Spawn 5 core reviewers in parallel + learnings-researcher
  - Each reviewer gets: PR diff, file context, CLAUDE.md conventions
  - Model assignments per agent
- Phase 2: Synthesize findings → P1/P2/P3
  - Deduplicate, flag known patterns from learnings-researcher
  - Estimate effort per finding
- Phase 3: Create todo files in todos/ directory
  - Naming: `{id}-pending-{priority}-{description}.md`
  - Structure: problem, findings, proposed solutions, acceptance criteria
- Phase 4: Present summary with counts per severity
- Phase 5: Resolve findings (P1 first, triage P2/P3)
- Receiving review feedback protocol (READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND)
- YAGNI check on reviewer suggestions
- Push-back guidance

**Step 2: Write the deep-review command**

Same as review but spawns all available review agents (14+), including conditional agents based on PR content:
- DB migrations → data integrity checks
- Frontend changes → race condition checks
- Additional language-specific reviewers
- Model: Sonnet for extras

**Step 3: Verify**

```bash
ls commands/review.md commands/deep-review.md
```

**Step 4: Commit**

```bash
git add commands/review.md commands/deep-review.md
git commit -m "feat: add /flowstate:review and /flowstate:deep-review commands"
```

---

## Task 13: Compound Command

**Files:**
- Create: `commands/compound.md`

**Step 1: Write the compound command**

Source from design doc "Step 6: Compound".

Key elements:
- YAML frontmatter: `name: compound`, `description`, `disable-model-invocation: true`
- Invoke the compound skill: `Invoke the flowstate:compound skill for: $ARGUMENTS`
- Or inline the full orchestration:
  - Spawn 5 parallel subagents (with model assignments)
  - Assemble output, validate against schema
  - Write to docs/solutions/[category]/
  - Present decision menu
  - Handle critical pattern promotion

**Step 2: Verify**

```bash
cat commands/compound.md
```

**Step 3: Commit**

```bash
git add commands/compound.md
git commit -m "feat: add /flowstate:compound command for knowledge capture"
```

---

## Task 14: Hooks Configuration

**Files:**
- Create: `hooks/hooks.json`

**Step 1: Write hooks configuration**

Minimal hooks for now — compaction survival (re-inject critical context after context compaction):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Flowstate plugin loaded. Available commands: /flowstate:brainstorm, /flowstate:plan, /flowstate:deepen-plan, /flowstate:work, /flowstate:review, /flowstate:deep-review, /flowstate:compound'",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Step 2: Verify JSON is valid**

```bash
python3 -c "import json; json.load(open('hooks/hooks.json')); print('Valid JSON')"
```

**Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: add session start hook for compaction survival"
```

---

## Task 15: Integration Verification

**Step 1: Verify complete file structure**

```bash
find . -name "*.md" -o -name "*.json" -o -name "*.yaml" | grep -v .git | sort
```

Expected output:
```
./.claude-plugin/marketplace.json
./.claude-plugin/plugin.json
./agents/research/best-practices-researcher.md
./agents/research/framework-docs-researcher.md
./agents/research/learnings-researcher.md
./agents/research/repo-research-analyst.md
./agents/research/spec-flow-analyzer.md
./agents/review/architecture-reviewer.md
./agents/review/pattern-reviewer.md
./agents/review/performance-reviewer.md
./agents/review/security-reviewer.md
./agents/review/simplicity-reviewer.md
./commands/brainstorm.md
./commands/compound.md
./commands/deepen-plan.md
./commands/deep-review.md
./commands/plan.md
./commands/review.md
./commands/work.md
./docs/plans/2026-02-27-flowstate-implementation-plan.md
./docs/plans/2026-02-27-flowstate-plugin-design.md
./hooks/hooks.json
./skills/brainstorming/SKILL.md
./skills/compound/assets/critical-pattern-template.md
./skills/compound/assets/resolution-template.md
./skills/compound/schema.yaml
./skills/compound/SKILL.md
./skills/tdd/SKILL.md
./skills/using-worktrees/SKILL.md
```

**Step 2: Verify all YAML frontmatter is valid**

```bash
for f in skills/*/SKILL.md agents/*/*.md commands/*.md; do
  echo "--- $f ---"
  head -1 "$f"
done
```

Expected: every file starts with `---`.

**Step 3: Verify cross-references**

Check that commands reference existing skills:
- `commands/brainstorm.md` → references `flowstate:brainstorming`
- `commands/compound.md` → references `flowstate:compound`
- `commands/work.md` → references `flowstate:tdd` and `flowstate:using-worktrees`

**Step 4: Count deliverables**

```bash
echo "Skills: $(ls skills/*/SKILL.md | wc -l)"
echo "Agents: $(ls agents/*/*.md | wc -l)"
echo "Commands: $(ls commands/*.md | wc -l)"
echo "Total files: $(find . -name '*.md' -o -name '*.json' -o -name '*.yaml' | grep -v .git | wc -l)"
```

Expected: 4 skills, 10 agents, 7 commands, ~28 total files.

**Step 5: Final commit**

```bash
git add -A
git status
# If any uncommitted files remain, commit them
```

---

## Summary

| Task | Files | Description |
|------|-------|-------------|
| 1 | 2 | Plugin scaffolding (manifests + directories) |
| 2 | 1 | Brainstorming skill (guided design) |
| 3 | 1 | TDD skill (test-first enforcement) |
| 4 | 1 | Using-worktrees skill (isolation) |
| 5 | 4 | Compound skill + schema + templates |
| 6 | 5 | Research agents (repo, learnings, best-practices, framework, spec-flow) |
| 7 | 5 | Review agents (security, performance, simplicity, architecture, patterns) |
| 8 | 1 | Brainstorm command |
| 9 | 1 | Plan command (most complex — orchestrates research + TDD tasks) |
| 10 | 1 | Deepen-plan command |
| 11 | 1 | Work command (TDD execution + subagent dispatch) |
| 12 | 2 | Review + deep-review commands |
| 13 | 1 | Compound command |
| 14 | 1 | Hooks configuration |
| 15 | 0 | Integration verification |
| **Total** | **~28** | |

**Recommended execution order:** Tasks 1-15 sequentially. Tasks 6-7 (agents) could run in parallel if using subagent-driven development.

**Estimated scope:** Each task is 5-15 minutes of prompt writing. The plan and work commands (Tasks 9, 11) are the most complex and may take 20-30 minutes each.
