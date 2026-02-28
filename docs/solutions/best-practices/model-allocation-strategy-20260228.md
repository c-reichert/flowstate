---
module: flowstate-plugin
date: 2026-02-28
problem_type: best_practice
symptoms:
  - Excessive API costs from over-allocating expensive models to all agents
  - No framework for deciding which model tier to assign to which agent
  - Assumption that more expensive model always produces better results
root_cause: Task-type dependent quality gaps between model tiers make blanket allocation wasteful — structured checklist review doesn't benefit from Opus, while architectural reasoning does
resolution_type: workflow_improvement
severity: medium
tags: [model-allocation, multi-agent, claude-haiku, claude-sonnet, claude-opus, cost-optimization, qodo-benchmark]
---

# Model Allocation Strategy for Multi-Agent Plugins

## Problem
A multi-agent plugin with 22 agents initially assigned most agents to Opus, assuming more expensive = better. This led to unnecessary API costs with no quality improvement for many task types.

## Symptoms
- All review agents running on Opus despite doing structured checklist work
- Implementer on Opus despite Sonnet being within 1.2 points on SWE-bench
- No data-driven rationale for model assignments
- 3-5x cost overhead for tasks that don't benefit from Opus reasoning

## What Didn't Work
**Attempted Solution 1:** All agents on Opus
- **Why it failed:** Overkill for structured, checklist-driven tasks. Qodo's benchmark on 400 real PRs showed Haiku 4.5 actually scored higher than Sonnet 4.5 (7.29 vs 6.60) on standard code review tasks.

**Attempted Solution 2:** Uniform Sonnet allocation
- **Why it failed:** Under-allocates for high-consequence reasoning tasks like security review where a missed vulnerability is costly.

## Solution
Task-type matching: assign model tier based on what the agent actually does, not how important it sounds.

**Decision framework:**

```yaml
# Opus (5 agents) — High-consequence reasoning where mistakes are costly
- security-reviewer        # Missing a vulnerability = production incident
- spec-flow-analyzer       # Missing an edge case = broken feature
- code-quality-reviewer    # Deep structural assessment
- solution-extractor       # Nuanced root cause analysis
- prevention-strategist    # Cross-cutting prevention guidance

# Sonnet (8 agents) — Structured analysis + code generation
- implementer              # SWE-bench gap only 1.2 points vs Opus
- architecture-reviewer    # Multi-file reasoning where Sonnet advantage is real
- performance-reviewer     # Some systems-level inference needed
- best-practices-researcher # Source authority evaluation matters
- plan-deepening agents    # Synthesis of external sources

# Haiku (9 agents) — Checklist-driven review + grep/classify
- simplicity-reviewer      # Named code smell taxonomy, rigid output
- pattern-reviewer         # Anti-pattern detection with fixed checklist
- repo-research-analyst    # Grep → read → report (same as learnings-researcher)
- learnings-researcher     # Grep + classify
- framework-docs-researcher # Lookup + summarize
- brainstorm-research      # Search + classify
- compound-research        # Search + classify
- session-start            # Context injection
- spec-research            # Grep + classify
```

**Key benchmarks driving this:**

| Model | SWE-bench | Code Review (Qodo) | Price (in/out per 1M) |
|-------|-----------|--------------------|-----------------------|
| Haiku 4.5 | 73.3% | 7.29 (wins 58%) | $1/$5 |
| Sonnet 4.5 | 77.2% | 6.60 | $3/$15 |
| Opus 4.1 | 80.9% | — | $5/$25 |

## Why This Works
1. **The gap is task-type dependent, not uniform.** Structured checklist review with named taxonomies: Haiku wins or ties. Multi-file architectural reasoning: Sonnet advantage real. Grep-and-classify: no meaningful gap.
2. **Qodo's 400-PR benchmark** is the most directly applicable data point — a production engineering team concluded Haiku 4.5 outperforms Sonnet 4.5 on day-to-day review tasks.
3. **The TDD review loop compensates** for the implementer's 10% coding gap — failed implementations get caught by spec review.

## Prevention
- When adding new agents, match model to task type before defaulting to the most expensive option
- Checklist-driven tasks with named taxonomies → Haiku
- Code generation and multi-file reasoning → Sonnet
- High-consequence judgment where false negatives are costly → Opus
- Re-evaluate allocations when new model benchmarks are published

## Related Issues
- See also: [claude-code-plugin-architecture-20260227.md](../best-practices/claude-code-plugin-architecture-20260227.md)
