---
name: skill:planning
description: >
  Transform brainstorm outputs, feature descriptions, or improvement ideas into
  well-structured implementation plans with TDD-structured tasks. Orchestrates
  parallel research (local + conditional external), spec-flow analysis, and plan
  writing. Triggers: "plan", "implement", "build this", or after a brainstorm
  session when ready to move to implementation.
---

<IMPORTANT>
This skill is the Flowstate planning workflow. It is NOT Claude Code's built-in plan mode.
Do NOT call EnterPlanMode or ExitPlanMode at any point during this workflow.
If you feel the urge to enter "plan mode", STOP — just follow the phases below instead.
</IMPORTANT>

# Planning: From Idea to Implementation Plan

Transform brainstorm outputs, feature descriptions, or improvement ideas into well-structured implementation plans with TDD-structured tasks. Every plan is grounded in codebase research, past learnings, and (when warranted) external best practices.

## Input

Requires a feature description, brainstorm reference, or improvement idea. If none is provided, ask the user: "What would you like to plan? Describe the feature, bug fix, or improvement -- or point me to a brainstorm document."

Do not proceed until you have a clear feature description from the user.

---

## Phase 0: Auto-Detect Brainstorm

Before asking questions, search for a recent brainstorm that matches this feature.

```bash
ls -la docs/brainstorms/*.md 2>/dev/null | head -20
```

**Relevance criteria -- a brainstorm is relevant if:**
- The topic (from filename or YAML frontmatter `topic:` field) semantically matches the feature description
- Created within the last 14 days
- If multiple candidates match, use the most recent one

**If a relevant brainstorm exists:**

1. Read the brainstorm document **thoroughly** -- every section matters
2. Announce: "Found brainstorm from [date]: [topic]. Using as foundation for planning."
3. Extract and carry forward **ALL** of the following into the plan:
   - Key decisions and their rationale
   - Chosen approach and why alternatives were rejected
   - Constraints and requirements discovered during brainstorming
   - Open questions (flag these for resolution during planning)
   - Success criteria and scope boundaries
   - Any specific technical choices or patterns discussed
4. **Skip idea refinement** -- the brainstorm already answered WHAT to build
5. Use brainstorm content as the **primary input** to research and planning phases
6. **The brainstorm is the origin document.** Throughout the plan, reference specific decisions with `(see brainstorm: docs/brainstorms/<filename>)` when carrying forward conclusions. Do not paraphrase decisions in a way that loses their original context -- link back to the source.
7. **Do not omit brainstorm content** -- if the brainstorm discussed it, the plan must address it (even if briefly). Scan each brainstorm section before finalizing the plan to verify nothing was dropped.

**If multiple brainstorms could match:**
Use **AskUserQuestion tool** to ask which brainstorm to use, or whether to proceed without one.

**If no brainstorm found (or not relevant), run idea refinement:**

Refine the idea through collaborative dialogue using the **AskUserQuestion tool**:
- Ask questions one at a time to understand the idea fully
- Prefer multiple choice questions when natural options exist
- Focus on understanding: purpose, constraints, success criteria
- Continue until the idea is clear OR user says "proceed"

**Gather signals for Phase 2 research decision.** During refinement, note:
- **User's familiarity**: Do they know the codebase patterns? Are they pointing to examples?
- **Topic risk**: Security, payments, external APIs warrant more caution
- **Uncertainty level**: Is the approach clear or open-ended?

---

## Phase 1: Parallel Local Research (Always Runs)

<thinking>
First, I need to understand the project's conventions, existing patterns, and any documented learnings. This is fast and local -- it informs whether external research is needed.
</thinking>

Run these agents **in parallel** to gather local context:

- Task learnings-researcher(feature_description)
- Task repo-research-analyst(feature_description)

**What to look for:**

| Agent | Focus |
|-------|-------|
| **learnings-researcher** (Haiku) | Search `docs/solutions/` for relevant past solutions. Grep-first filtering: extract keywords, parallel grep calls by title/tags/module. Always check `docs/solutions/patterns/critical-patterns.md`. Score relevance: strong/moderate/weak. Full read of strong/moderate matches only. Return: distilled summaries with file paths and key insights. |
| **repo-research-analyst** (Sonnet) | Find existing patterns, CLAUDE.md guidance, similar implementations, technology familiarity, pattern consistency. Return: relevant file paths with line numbers, conventions to follow. |

These findings inform the next phase.

---

## Phase 2: Conditional External Research

Based on signals from Phase 0 refinement and findings from Phase 1, decide on external research.

**Decision tree:**

| Signal | Action |
|--------|--------|
| **High-risk topics** (security, payments, external APIs, data privacy) | **ALWAYS research** -- the cost of missing something is too high |
| **Strong local context** (good patterns, CLAUDE.md has guidance, familiar tech, user knows what they want) | **Skip external research** -- local patterns suffice |
| **Uncertainty or unfamiliar territory** (user exploring, no codebase examples, new technology) | **Research** -- external perspective is valuable |

**Announce the decision and proceed.** Brief explanation, then continue. User can redirect if needed.

Examples:
- "Your codebase has solid patterns for this. Proceeding without external research."
- "This involves payment processing, so I'll research current best practices first."
- "This uses a framework we haven't seen in the codebase. Researching documentation."

**If research needed, spawn in parallel:**

- Task best-practices-researcher(feature_description)
  - Model: Sonnet
  - Current industry standards, real-world examples, community best practices
  - Uses WebSearch for current info

- Task framework-docs-researcher(feature_description)
  - Model: Haiku
  - Framework/library documentation via Context7 MCP
  - Resolve library ID, query docs, return relevant snippets

---

## Phase 3: Spec-Flow Analysis

After research completes, spawn the spec-flow analyzer to validate and refine the feature specification:

- Task spec-flow-analyzer(feature_description, research_findings)
  - Model: Opus
  - Map all user flows and permutations
  - Identify missing error handling
  - Find edge cases and ambiguities
  - Validate acceptance criteria completeness
  - Return: flow map, edge cases, missing handling, questions for clarification

**Review spec-flow analysis results:**
- Incorporate identified gaps or edge cases into the plan
- Update acceptance criteria based on findings
- Flag any unresolvable ambiguities for the user

---

## Phase 4: Consolidate Research

After all research phases complete, merge findings into a unified context:

- **Relevant file paths** from repo research (e.g., `app/services/example_service.py:42`)
- **Institutional learnings** from `docs/solutions/` with key insights and gotchas to avoid
- **External documentation URLs** and best practices (if external research was done)
- **Edge cases** discovered by spec-flow-analyzer
- **CLAUDE.md conventions** that apply to this work
- **Related issues or PRs** discovered

**Optional validation:** Briefly summarize consolidated findings and ask the user if anything looks off or missing before proceeding to plan writing.

---

## Phase 5: Write the Plan

Use the **flowstate:skill:writing-plans** skill to structure the plan document.

Feed it the consolidated research from Phase 4 (learnings, patterns, best practices, edge cases)
and the feature description from Phase 0. The skill defines the document format, detail levels,
TDD task structure, learnings integration, and output template.

---

## Phase 6: Review the Plan

Before saving, invoke the **flowstate:skill:document-review** skill for a structured self-review of the plan document. This catches completeness gaps, vague language, missing file paths, and YAGNI violations before the plan is committed.

Address any critical or important issues found by the review before proceeding.

---

## Phase 7: Save Plan

```bash
mkdir -p docs/plans/
```

Use the Write tool to save the complete plan to `docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`.

Confirm: "Plan written to `docs/plans/[filename]`"

Then commit:

```bash
git add docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md
git commit -m "docs: add plan for [brief description]"
```

---

## Phase 8: Offer Options

Use the **AskUserQuestion tool** to present these options:

**Question:** "Plan ready at `docs/plans/[filename]`. What would you like to do next?"

**Options:**
1. **Run `/workflow:deepen-plan`** -- Enhance each section with parallel research agents (best practices, edge cases, code examples)
2. **Start `/workflow:work`** -- Begin TDD implementation of this plan
3. **Generate parallel session prompt** -- Produce a deep handoff prompt for implementing this plan in a separate Claude Code session or agent
4. **Review and refine** -- Improve the plan through structured discussion
5. **Done for now** -- Return later when ready

Based on selection:
- **`/workflow:deepen-plan`** -- Invoke the deepen-plan command with the plan file path
- **`/workflow:work`** -- Invoke the work command with the plan file path
- **Generate parallel session prompt** -- See "Parallel Session Prompt Generation" below
- **Review and refine** -- Discuss improvements, update the plan, re-present options
- **Done for now** -- Acknowledge and remind the user of the plan file path

Loop back to options after refinement until user selects a workflow command or chooses done.

---

## Parallel Session Prompt Generation

When the user selects "Generate parallel session prompt", produce a comprehensive handoff prompt they can paste into a new Claude Code session (or use to spawn a parallel agent). The prompt must be **self-contained** — the new session has zero context from this one.

**Include in the prompt:**

1. **Project context** — repo path, tech stack, key architecture decisions
2. **Full plan reference** — the exact path to the plan file (`docs/plans/...`)
3. **Brainstorm reference** — path to the brainstorm doc if one exists
4. **Key decisions made** — summarize all decisions from brainstorming/planning so the new session doesn't re-ask
5. **Learnings to check** — mention `docs/solutions/` and `critical-patterns.md` if they exist
6. **Explicit instructions** — tell the new session to:
   - Read the plan file completely before starting
   - Run `/workflow:work <plan-path>` to execute
   - Follow TDD discipline (the session-start hook will reinforce this)
   - Commit incrementally
   - Run `/workflow:review` after completion
   - Run `/workflow:compound` to capture learnings
7. **Constraints and scope** — anything the user said about what to prioritize, skip, or be careful about

**Format the prompt as a single copyable code block** so the user can paste it directly.

**Example structure:**
```
You are implementing a feature in [repo]. The design and plan are complete.

## Context
- Repo: [path]
- Tech stack: [stack]
- Key decisions: [list]

## Instructions
1. Read the plan: [path]
2. Read the brainstorm for context: [path]
3. Check docs/solutions/ for relevant past learnings
4. Run `/workflow:work [plan-path]` to execute the plan with TDD
5. After completion, run `/workflow:review` then `/workflow:compound`

## Important
- [Any constraints, priorities, or warnings]
```

---

## Reminders

- **NEVER CODE.** This skill produces a plan, not implementation.
- **The brainstorm is the origin document** -- if one exists, the plan must honor all decisions made there.
- **Pipeline mode:** If invoked from an automated workflow (LFG or similar), skip all AskUserQuestion calls. Make decisions automatically and proceed to writing the plan without interactive prompts.
- **Plan structure details** are in the `flowstate:skill:writing-plans` skill -- do not duplicate them here.
