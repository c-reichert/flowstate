---
name: skill:plan-deepening
description: >
  Enhance an existing plan with parallel research agents per section. Adds best
  practices, edge cases, code examples, and learnings references. Does not
  rewrite -- only enriches. Triggers: "deepen", "enhance plan", "add research
  to plan", or after initial planning when more depth is needed.
---

# Plan Deepening: Enrich Plans with Research

Enhance an existing plan by running parallel research agents per section. This adds depth -- best practices, performance considerations, edge cases, concrete code examples, and references to past learnings. The original plan structure is preserved; content is only added, never removed.

## Input

Requires a path to an existing plan file in `docs/plans/`.

**If the plan path is not provided:**
1. Check `docs/plans/` for the most recently modified plan:
   ```bash
   ls -lt docs/plans/*.md 2>/dev/null | head -5
   ```
2. If found, ask: "Found plan at `[path]`. Should I deepen this one?"
3. If not found, ask: "Which plan should I deepen? Provide the path to the plan file."

Do not proceed until you have a valid plan file.

---

## Phase 1: Parse Plan Structure

Read the plan file completely. Extract a **section manifest**:

- Overview / problem statement
- Research context (if already present)
- Technical approach / architecture sections
- Implementation tasks (list each task)
- Technologies and frameworks mentioned
- Libraries and dependencies referenced
- Acceptance criteria
- Edge cases (if already present)

Create a structured list of sections to enhance. Each section gets its own research focus.

---

## Phase 2: Per-Section Parallel Research

For each section in the manifest, spawn a research agent (Sonnet) in parallel:

```
For each section:
  Task section-researcher(section_content, technologies_mentioned)
    Model: Sonnet
    Focus areas:
    - Industry standards and conventions for this area
    - Performance considerations specific to this section
    - Common pitfalls and how to avoid them
    - Concrete code examples from real-world usage
    - Security implications (if applicable)
```

**Also query in parallel:**

- **Context7 MCP** for framework documentation:
  - For each technology/framework mentioned in the plan
  - Resolve library ID first, then query for relevant patterns
  - Focus on the specific use cases in the plan, not general overviews

- **WebSearch** for current best practices:
  - Target queries at specific technical decisions in the plan
  - Look for recent articles, blog posts, and documentation updates
  - Prioritize official documentation and reputable engineering blogs

---

## Phase 3: Learnings Discovery

Search `docs/solutions/` for relevant documented learnings that apply to this plan:

```
Task learnings-discovery(plan_summary, technologies, components)
  Model: Haiku

  Strategy (grep-first filtering):
  1. Extract keywords from plan: technology names, component names, error types, patterns
  2. Run parallel grep calls on docs/solutions/:
     - grep by title/filename
     - grep by tags in YAML frontmatter
     - grep by module/component name
     - grep by symptoms
  3. Always check docs/solutions/patterns/critical-patterns.md
  4. Read frontmatter of matched files
  5. Score relevance: strong / moderate / weak
  6. Full read of strong and moderate matches only
  7. Return: file path, relevance score, key insight, applicable section
```

For each relevant learning found, note which plan section it should enhance.

---

## Phase 4: Enhance Plan Sections

For each section, integrate research findings. Add a **Research Insights** subsection:

```markdown
#### Research Insights

**Best Practices:**
- [Concrete recommendation with source]
- [Convention to follow]

**Performance Considerations:**
- [Optimization opportunity with expected impact]
- [Benchmark or measurement guidance]

**Edge Cases:**
- [Edge case scenario] -- [handling strategy]
- [Boundary condition] -- [validation approach]

**Code Examples:**
```[language]
// Example from [source/pattern]
[concrete code example relevant to this section]
```

**Learnings from Past Work:**
- [Learning title] (docs/solutions/[path]) -- [how it applies here]

**References:**
- [Documentation URL] -- [what it covers]
- [Blog post / article URL] -- [key takeaway]
```

**Rules for enhancement:**
- Do NOT remove or rewrite existing content -- only add
- Do NOT replace the original implementation plan -- augment it
- Place Research Insights as a subsection under each enhanced section
- If a section already has research context, merge new findings (no duplicates)
- Keep enhancements concise -- each insight should earn its place
- Code examples should be directly applicable, not generic

---

## Phase 5: Add Enhancement Summary

At the **top of the plan** (after YAML frontmatter, before the first section), add:

```markdown
## Enhancement Summary

**Deepened on:** YYYY-MM-DD
**Sections enhanced:** [count] of [total]
**Research sources:** [count] external, [count] learnings, [count] framework docs

**Key Improvements:**
1. [Most impactful improvement -- e.g., "Added retry strategy for API calls based on past outage resolution"]
2. [Second improvement -- e.g., "Identified race condition edge case in concurrent user scenario"]
3. [Third improvement -- e.g., "Added performance benchmarks from framework documentation"]

**Learnings Applied:**
- [docs/solutions/path/file.md] -- [one-line insight]
- [docs/solutions/path/file.md] -- [one-line insight]
```

---

## Phase 6: Review the Enhanced Plan

Before saving, invoke the **flowstate:skill:document-review** skill to verify the enhanced plan remains coherent. Confirm that new research insights do not contradict existing content, that no sections were accidentally removed, and that the enhancements add genuine value.

Address any critical or important issues found by the review before proceeding.

---

## Phase 7: Update Plan File

Write the enhanced plan back to the **same file path** -- preserve the original filename.

```bash
# Verify the file was updated
wc -l docs/plans/[filename]
```

Then commit:

```bash
git add docs/plans/[filename]
git commit -m "docs: deepen plan for [brief description]"
```

Confirm: "Plan deepened and updated at `docs/plans/[filename]`"

---

## What This Does NOT Do

- **Does NOT run review agents** -- save that for `/workflow:review`
- **Does NOT rewrite the plan** -- only adds research context and insights
- **Does NOT replace existing content** -- only enhances with new subsections
- **Does NOT change the plan structure** -- sections stay where they are
- **Does NOT re-run the original planning agents** -- uses new research-focused agents

---

## Post-Deepening Options

Use the **AskUserQuestion tool** to present:

**Question:** "Plan deepened with [X] sections enhanced and [Y] learnings applied. What next?"

**Options:**
1. **Start `/workflow:work`** -- Begin TDD implementation of this plan
2. **Generate parallel session prompt** -- Produce a deep handoff prompt for implementing this plan in a separate Claude Code session or agent. Follow the "Parallel Session Prompt Generation" instructions in the `planning` skill.
3. **Review the enhanced plan** -- Read through and discuss improvements
4. **Deepen further** -- Run another round focusing on specific sections
5. **Done for now** -- Return later when ready

---

## Reminders

- This skill is about **depth, not breadth** -- make each section richer, not longer
- Prioritize **actionable insights** over general knowledge
- **Learnings references** are the most valuable additions -- they represent hard-won knowledge
- If Context7 MCP is not available, fall back to WebSearch for framework documentation
- **Pipeline mode:** If invoked from an automated workflow, skip AskUserQuestion calls and proceed automatically
