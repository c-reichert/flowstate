# FlowState Plugin — Opus 4.6 Prompting Alignment Plan

**Created:** 2026-04-12
**Goal:** Update FlowState skills, agents, commands, and hooks to align with Anthropic's Opus 4.6 prompting best practices. Opus 4.6 is more responsive to system prompts and overtriggers on aggressive language — prompts that were needed for 4.5 now cause overcorrection.

**Scope:** Only changes where Opus 4.6 is the executing model (main session + Opus-designated agents). Haiku/Sonnet agents are excluded unless they receive instructions from the Opus session.

**Plugin location:** `~/.claude/plugins/cache/flowstate-marketplace/flowstate/0.5.1/`

---

## Guiding Principles

From Anthropic's official Claude 4.6 prompting guide:

1. **Dial back aggressive language** — "MUST"/"CRITICAL"/"NEVER" → softer conditional framing
2. **Add context and motivation ("the why")** — Anthropic: "Providing context or motivation behind your instructions helps Claude better understand your goals and deliver more targeted responses." Every rule should explain WHY it exists so Claude can generalize and judge edge cases.
3. **Remove over-prompting for thoroughness** — 4.6 is already more thorough; "if in doubt, use [tool]" causes overtriggering
4. **Replace blanket defaults** — "Default to using [tool]" → "Use [tool] when it would enhance your understanding"
5. **Use XML tags for prompt structure** — Anthropic officially recommends XML tags (`<instructions>`, `<examples>`, `<context>`) for unambiguous prompt parsing
6. **Adaptive thinking** — Extended thinking with `budget_tokens` is deprecated; use `effort` parameter
7. **Subagent restraint** — 4.6 has a strong predilection for spawning subagents; add guidance on when NOT to delegate
8. **Anti-overengineering** — 4.6 tends to create extra files and unnecessary abstractions

---

## Phase 1: Session-Start Hook (High Impact — Injected Every Session)

**File:** `hooks/session-start`

The core rules are injected into every session. This is the highest-leverage change.

- [ ] **1.1 Rewrite TDD Iron Law — soften + add why**
  Current: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST."
  Proposed: "Write a failing test before writing production code. Cycle: RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR. Watching the test fail first proves it actually tests the right thing — without that step, a passing test might be vacuous."

- [ ] **1.2 Rewrite Verification Before Completion — soften + add why**
  Current: "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE."
  Proposed: "Before claiming any status as complete, run the verification command fresh and read the complete output. Stale or remembered results drift from reality — only a fresh run reflects the current state of the code."

- [ ] **1.3 Rewrite Brainstorm Before Build — soften + add why**
  Current: "Do NOT implement, write code, scaffold, or create files until..."
  Proposed: "Explore the user's idea through brainstorming before implementing. Jumping to code before the design is understood leads to rework and misaligned solutions — even seemingly simple tasks benefit from a quick design pass."

- [ ] **1.4 Rewrite Subagent Distrust — soften + add why**
  Current: "Do not trust implementer reports. Read actual code. The implementer may have finished suspiciously quickly."
  Proposed: "Independently verify implementer work by reading actual code changes. Subagents lack full context and may produce code that passes superficially but misses spec requirements — the reviewer's job is to catch what the implementer missed."

- [ ] **1.5 Add Opus 4.6 behavioral guardrails**
  Add to hook output:
  - Subagent restraint: "Use subagents for parallel independent work. For simple tasks or single-file operations, work directly — subagent overhead isn't worth it for quick lookups or single edits."
  - Anti-overengineering: "Only make changes that are directly requested. Extra files, abstractions, or improvements beyond what was asked create maintenance burden and dilute the user's intent."

- [ ] **1.6 Wrap core rules in XML tags**
  Structure the hook output with XML tags per Anthropic's recommendation:
  ```
  <core_rules>
    <tdd_rule>...</tdd_rule>
    <verification_rule>...</verification_rule>
    <brainstorm_rule>...</brainstorm_rule>
    <subagent_distrust_rule>...</subagent_distrust_rule>
    <knowledge_compounding_rule>...</knowledge_compounding_rule>
  </core_rules>
  ```

---

## Phase 2: Core Skills (Opus-Executed)

### 2.1 TDD Skill
**File:** `skills/tdd/SKILL.md`

- [ ] **2.1a Replace ALL-CAPS rules with clear imperatives + why**
  "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" → "Write the failing test first. Watch it fail. Then write minimal code to pass. This cycle ensures every line of production code is covered by a test that actually validates behavior."

- [ ] **2.1b Soften "Delete means DELETE" — one statement + why**
  Current: Repeated emphatic "Delete means DELETE" with moral framing
  Proposed: "If code was written before its test, delete it and start the cycle correctly. Code written without a failing test may accidentally pass for the wrong reasons — starting fresh ensures the test drives the implementation."

- [ ] **2.1c Replace moral framing with motivation**
  "Violating the letter of the rules is violating the spirit" → Replace with context about WHY the discipline matters: "TDD discipline compounds — each shortcut weakens the test suite's ability to catch regressions."

- [ ] **2.1d Soften absolutist "No exceptions" + explain when exceptions apply**
  Current: "No exceptions without your human partner's explicit permission."
  Proposed: "Exceptions require explicit user permission. Common exceptions: throwaway prototypes, generated code, config files — these don't benefit from test-first because they're either disposable or declarative."

### 2.2 Verification Before Completion Skill
**File:** `skills/verification-before-completion/SKILL.md`

- [ ] **2.2a Replace moral framing with motivation**
  "Claiming work is complete without verification is dishonesty" and "Skip any step = lying" → "Run verification commands fresh before reporting status. Context compaction and tool output can make earlier results stale — only a fresh run reflects current reality."

- [ ] **2.2b Replace "This is non-negotiable" with why**
  → "This step catches regressions that appear after changes accumulate. Skipping it risks reporting success on broken code."

### 2.3 Brainstorming Skill
**File:** `skills/brainstorming/SKILL.md`

- [ ] **2.3a Evaluate `<HARD-GATE>` wrapper**
  This is a custom enforcement mechanism. Test whether Opus 4.6 respects the brainstorm-before-build rule without the HARD-GATE wrapper. If so, replace with a clear instruction + XML-tagged section with motivation.

- [ ] **2.3b Soften "MUST present it and get approval" + add why**
  → "Present the design and get user approval before implementation begins. This alignment step prevents building the wrong thing — rework from misunderstood requirements is more expensive than a 5-minute design review."

- [ ] **2.3c Reframe "This applies to EVERY project" with motivation**
  → "Every project goes through brainstorming. Seemingly simple tasks often have hidden edge cases that surface during design but are expensive to discover during implementation."

### 2.4 Planning Skill
**File:** `skills/planning/SKILL.md`

- [ ] **2.4a Keep EnterPlanMode guard but soften**
  Current: "Do NOT call EnterPlanMode or ExitPlanMode at any point" + "If you feel the urge to enter 'plan mode', STOP"
  This is a legitimate footgun (GitHub issue #6109) — keep the guard but soften delivery: "This workflow replaces Claude Code's built-in plan mode. Do not call EnterPlanMode or ExitPlanMode during this workflow."

- [ ] **2.4b Soften "NEVER CODE"**
  → "This skill produces a plan document, not implementation code."

- [ ] **2.4c Review "ALWAYS research" for high-risk topics**
  → "Research externally for high-risk areas (security, payments, external APIs) where local context alone is insufficient."

### 2.5 Subagent-Driven Development Skill
**File:** `skills/subagent-driven-development/SKILL.md`

- [ ] **2.5a Soften "THE IRON LAW" repeated capitalization**
  Reference the TDD rule once, clearly: "Each task follows the TDD cycle: write failing test → verify it fails → implement → verify it passes."

- [ ] **2.5b Soften "CRITICAL INSTRUCTION: Do not trust the implementer's report"**
  → "Independently verify implementer work. Read the actual code changes, don't rely on the implementer's summary."

- [ ] **2.5c Add subagent spawning guidance for 4.6**
  Opus 4.6 may over-spawn subagents. Add: "Dispatch subagents for parallelizable tasks. For sequential tasks or tasks that share state, execute directly."

### 2.6 Compound Skill
**File:** `skills/compound/SKILL.md`

- [ ] **2.6a Soften "NEVER auto-promote"**
  → "Promotion to critical-patterns.md is advisory only. Present the suggestion and let the user decide."

- [ ] **2.6b Soften "MUST do" / "MUST NOT do" sections**
  → Convert to clear behavioral description: "Do:" and "Do not:" with imperative framing.

### 2.7 Systematic Debugging Skill
**File:** `skills/systematic-debugging/SKILL.md`

- [ ] **2.7a Review for over-prompting patterns**
  Check if the 3-strike escalation and 6-step cycle use aggressive language that 4.6 doesn't need.

### 2.8 Multi-Agent Review / Deep Code Review Skills
**Files:** `skills/multi-agent-review/SKILL.md`, `skills/deep-code-review/SKILL.md`

- [ ] **2.8a Keep "CRITICAL: Never flag docs/ for removal"**
  This is a protection rule, not aggressive prompting. Keep it but consider rephrasing: "Do not flag docs/plans/ or docs/solutions/ files for removal — these are knowledge artifacts, not dead code."

---

## Phase 3: Agent Definitions (Model-Specific)

### Opus-Model Agents (Direct Impact)

- [ ] **3.1 spec-flow-analyzer (Opus)**
  `agents/research/spec-flow-analyzer.md`
  Review for aggressive language. This agent maps user flows — check if it has unnecessary "MUST" patterns.

- [ ] **3.2 security-reviewer (Opus)**
  `agents/review/security-reviewer.md`
  Review for overtriggering patterns. Security review should be thorough but not over-flag.

### Sonnet/Haiku Agents (Indirect Impact)

These agents are NOT running on Opus 4.6, but they receive instructions from the Opus session:

- [ ] **3.3 Review agent dispatch prompts**
  When the main Opus session dispatches Sonnet/Haiku agents, the *dispatch prompt* is written by Opus. Check that the multi-agent-review and subagent-driven-development skills don't include language that causes Opus to write overly aggressive dispatch prompts.

---

## Phase 4: Command Files (Orchestration Layer)

- [ ] **4.1 remind.md**
  `commands/workflow/remind.md`
  This re-injects core rules. Apply same softening as Phase 1 (session-start hook).

- [ ] **4.2 work.md**
  `commands/workflow/work.md`
  Review for aggressive orchestration language. This is the main execution command.

- [ ] **4.3 Other commands (brainstorm, write-plan, review, etc.)**
  These are thin wrappers that invoke skills. Likely no changes needed, but verify they don't add their own aggressive framing on top of the skill instructions.

---

## Phase 5: Structural Improvements

- [ ] **5.1 Add XML tag structure to skill files**
  Per Anthropic's recommendation: "XML tags help Claude parse complex prompts unambiguously." Wrap key sections in skills with descriptive tags where they mix instructions, context, and examples:
  ```
  <workflow_rules>...</workflow_rules>
  <phase name="red">...</phase>
  <exceptions>...</exceptions>
  ```
  Use markdown headers within tagged sections for readability. XML defines boundaries; markdown provides internal structure.

- [ ] **5.2 Add effort guidance for dispatched agents**
  For Opus agents (spec-flow-analyzer, security-reviewer), consider adding effort hints: "This is a thorough analysis task — use high effort" vs. "This is a quick classification — keep it concise."

- [ ] **5.3 Add anti-overengineering to work command**
  Opus 4.6 tends to create extra files during implementation. Add to the work skill: "Clean up temporary files after task completion. Only create files that are part of the deliverable."

---

## Priority Order

1. **Phase 1 (session-start hook)** — Highest impact, injected every session
2. **Phase 2.1-2.5 (core skills)** — TDD, verification, brainstorming, planning, subagent dev
3. **Phase 4.1 (remind command)** — Mirrors session-start hook
4. **Phase 3 (agent definitions)** — Opus agents only
5. **Phase 2.6-2.8 (remaining skills)** — Lower priority
6. **Phase 5 (structural)** — Nice-to-have improvements

---

## Testing Strategy

After each change:
1. Start a fresh session to verify the hook injection looks correct
2. Run a simple `/workflow:brainstorm` to check the brainstorming gate still works
3. Run a `/workflow:work` on a trivial task to check TDD enforcement still holds
4. Verify that Opus 4.6 follows the rules without the aggressive language — if compliance drops, add back specific reinforcement (but targeted, not blanket)

---

## Notes

- **This is a plugin from the marketplace** — edits go to the cached copy at `~/.claude/plugins/cache/`. They survive until the plugin updates. Consider forking the plugin or submitting upstream PRs.
- **The goal is NOT to weaken the rules** — TDD, verification, brainstorm-before-build, and subagent distrust are all valuable. The goal is to express them in language that Opus 4.6 responds to optimally, without overcorrection or defensive behavior.
- **Some aggressive language may be intentional** — The plugin author may have calibrated for models that needed stronger prompting. Test before assuming softer is better.
