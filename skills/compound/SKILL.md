---
name: compound
description: >
  Capture solved problems as categorized documentation with YAML frontmatter.
  Trigger words: "compound", "capture learning", "document solution", "that worked",
  "it's fixed", "working now", "problem solved", "that did it", "doc-fix"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
  - Glob
  - SubagentTool
  - AskUserQuestion
preconditions:
  - Problem has been solved (not in-progress)
  - Solution has been verified working
---

# Compound Knowledge Capture Skill

**Purpose:** Capture what you learned from the current work cycle as searchable,
reusable documentation. This is the step that makes every future cycle easier.

**Organization:** Single-file architecture -- each problem documented as one markdown
file in its category directory (e.g., `docs/solutions/performance-issues/n-plus-one-fix.md`).
Files use YAML frontmatter validated against `schema.yaml` for metadata and searchability.

---

## Phase 1: Parallel Capture

Spawn 5 subagents in parallel. ALL agents return **TEXT ONLY** -- no files written.

```
SubagentTool calls (parallel):

├── context-analyzer (model: Haiku)
│   Input: Full conversation context, problem description
│   Task: Extract problem type, component/module, observable symptoms
│   Return: YAML frontmatter skeleton with module, date, problem_type,
│           symptoms, severity, tags
│
├── solution-extractor (model: Opus)
│   Input: Full conversation context, investigation history
│   Task: Analyze investigation steps, what was tried, what worked,
│         what didn't work and why
│   Return: root_cause, resolution_type, solution description with
│           code examples (before/after), "What Didn't Work" section
│
├── related-docs-finder (model: Haiku)
│   Input: Problem keywords, module name, symptoms
│   Task: Search docs/solutions/ for related documentation using
│         grep-first filtering (keywords -> frontmatter -> full read)
│   Return: List of related solution file paths with brief descriptions
│
├── prevention-strategist (model: Opus)
│   Input: Root cause, solution details, problem context
│   Task: Develop prevention strategies and best practices
│   Return: Prevention guidance (coding practices, what to watch for,
│           how to catch early), "Why This Works" explanation
│
└── category-classifier (model: Haiku)
    Input: Problem description, symptoms, root cause
    Task: Determine optimal directory category from schema.yaml enum,
          generate kebab-case filename
    Validate: problem_type against schema.yaml values
    Return: category directory path, suggested filename
```

**Subagent prompt requirements:**
- Each subagent receives conversation context relevant to its task
- Each subagent returns structured text (not files, not tool calls)
- Orchestrator collects all 5 text results before proceeding to Phase 2

---

## Phase 2: Assemble and Write

The orchestrator collects all text results from Phase 1 and assembles the
resolution document.

### Step 2a: Validate YAML Frontmatter

Validate assembled frontmatter against `schema.yaml`:

- All required fields present (module, date, problem_type, symptoms, root_cause,
  resolution_type, severity, tags)
- `problem_type` matches schema enum exactly
- `resolution_type` matches schema enum exactly
- `severity` matches schema enum exactly
- `symptoms` is array with 1-5 items
- `tags` is array with 1-8 items (lowercase, hyphen-separated)
- `date` follows YYYY-MM-DD format

**If validation fails:** Fix values using context. If ambiguous, ask the user
via AskUserQuestion before proceeding.

### Step 2b: Determine Output Path

Use `category_mapping` from `schema.yaml` to map `problem_type` to directory:

```
problem_type         -> directory
build_error          -> docs/solutions/build-errors/
test_failure         -> docs/solutions/test-failures/
runtime_error        -> docs/solutions/runtime-errors/
performance_issue    -> docs/solutions/performance-issues/
database_issue       -> docs/solutions/database-issues/
security_issue       -> docs/solutions/security-issues/
ui_bug               -> docs/solutions/ui-bugs/
integration_issue    -> docs/solutions/integration-issues/
logic_error          -> docs/solutions/logic-errors/
developer_experience -> docs/solutions/developer-experience/
workflow_issue       -> docs/solutions/workflow-issues/
best_practice        -> docs/solutions/best-practices/
documentation_gap    -> docs/solutions/documentation-gaps/
```

### Step 2c: Write Resolution Document

1. Create directory: `mkdir -p docs/solutions/[category]/`
2. Populate `assets/resolution-template.md` with:
   - YAML frontmatter from context-analyzer (validated)
   - Problem/symptoms sections from context-analyzer
   - "What Didn't Work" and "Solution" from solution-extractor
   - "Why This Works" and "Prevention" from prevention-strategist
   - "Related Issues" from related-docs-finder
3. Write single file: `docs/solutions/[category]/[filename].md`

---

## Phase 3: Decision Menu

Present options via **AskUserQuestion** and WAIT for user response:

```
Solution documented.

File created:
  docs/solutions/[category]/[filename].md

What's next?
1. Continue workflow (recommended)
2. Add to Required Reading -- promote to critical-patterns.md
3. Link related documentation
4. View documentation
5. Other
```

### Smart Suggestion for Promotion

Before presenting the menu, evaluate whether to suggest promotion:

**Suggest "This might be worth adding to Required Reading (Option 2)" when:**
- Severity is `critical`
- Problem affects multiple modules (cross-cutting concern)
- Solution is non-obvious (multiple failed attempts before resolution)

**NEVER auto-promote.** The suggestion is advisory only. The user always decides.

### Handle Responses

**Option 1: Continue workflow**
- Return to calling workflow
- Documentation is complete

**Option 2: Add to Required Reading**
- Proceed to Phase 4 (Critical Pattern Promotion)

**Option 3: Link related documentation**
- Ask: "Which doc to link? (provide filename or describe)"
- Search docs/solutions/ for the target document
- Add cross-reference to both documents (bidirectional linking)
- Confirm: "Cross-reference added."
- Present decision menu again

**Option 4: View documentation**
- Display the created documentation file
- Present decision menu again

**Option 5: Other**
- Ask what the user would like to do
- Execute requested action
- Present decision menu again if appropriate

---

## Phase 4: Critical Pattern Promotion

Runs only when user selects Option 2 from the decision menu.

### Step 4a: Extract Pattern

From the resolution document, extract:
- The wrong approach (code that caused the problem)
- The correct approach (code that fixed it)
- Technical explanation of why
- When/where this pattern applies

### Step 4b: Format as WRONG vs CORRECT

Use `assets/critical-pattern-template.md` to structure the entry:

```markdown
## N. [Pattern Name]

### WRONG ([Will cause X error])
```[language]
[code showing wrong approach]
```

### CORRECT
```[language]
[code showing correct approach]
```

**Why:** [Technical explanation]
**Placement/Context:** [When this applies]
**Documented in:** `docs/solutions/[category]/[filename].md`
```

### Step 4c: Append to Critical Patterns

1. Read `docs/solutions/patterns/critical-patterns.md`
   - If file does not exist, create it with a header:
     ```markdown
     # Critical Patterns -- Required Reading

     These patterns MUST be followed. All subagents check this file before
     code generation. Violations of these patterns cause real bugs.

     ---
     ```
2. Determine next pattern number (N) from existing entries
3. Append the formatted pattern entry
4. Add cross-reference back to the resolution document

### Step 4d: Confirm

```
Added to Required Reading as pattern #N.
All subagents will see this pattern before code generation.
```

Return to decision menu or continue workflow as appropriate.

---

## Schema Reference

YAML frontmatter is validated against: `skills/compound/schema.yaml`

See `schema.yaml` for:
- All field definitions and types
- Enum values for problem_type, resolution_type, severity
- Category mapping (problem_type -> directory path)

## Template References

- Resolution document template: `skills/compound/assets/resolution-template.md`
- Critical pattern template: `skills/compound/assets/critical-pattern-template.md`

---

## Error Handling

**Missing context from conversation:**
- Ask user for missing details via AskUserQuestion
- Do NOT proceed until critical information is provided (module, symptoms, solution)

**YAML validation failure:**
- Show specific validation errors
- Attempt auto-correction from context
- If ambiguous, ask user via AskUserQuestion
- BLOCK file creation until frontmatter is valid

**No related docs found:**
- Proceed normally -- "Related Issues" section gets "None identified"

**Category ambiguity:**
- If category-classifier returns low confidence, present top 2 options
  to user via AskUserQuestion

**critical-patterns.md does not exist:**
- Create it with header before appending (see Phase 4, Step 4c)

---

## Quality Guidelines

**Good documentation has:**
- Exact error messages (copy-paste from output)
- Specific file:line references where applicable
- Observable symptoms (what you saw, not interpretations)
- Failed attempts documented (helps avoid wrong paths)
- Technical explanation (not just "what" but "why")
- Code examples (before/after)
- Prevention guidance (how to catch early)
- Cross-references to related issues

**Avoid:**
- Vague descriptions ("something was wrong")
- Missing technical details ("fixed the code")
- No context (which file? which module?)
- Code dumps without explanation
- No prevention guidance

---

## Execution Guidelines

**MUST do:**
- Run all 5 subagents in parallel (Phase 1)
- Validate YAML frontmatter against schema.yaml before writing
- Create directories with `mkdir -p` before writing files
- Present decision menu via AskUserQuestion and WAIT
- Suggest promotion for critical/cross-cutting/non-obvious patterns
- Use resolution-template.md structure for all documents

**MUST NOT do:**
- Write files from subagents (text only, orchestrator writes)
- Skip YAML validation
- Auto-promote patterns to critical-patterns.md
- Skip the decision menu
- Use vague, unsearchable descriptions
- Omit code examples from solution section

---

## Success Criteria

Documentation is successful when ALL of the following are true:

- YAML frontmatter validated against schema.yaml (all required fields, correct enums)
- File created in docs/solutions/[category]/[filename].md
- Resolution template fully populated with all sections
- Code examples included in solution section
- Cross-references added if related issues found
- User presented with decision menu and response handled
- If promoted: pattern appended to critical-patterns.md in WRONG/CORRECT format
