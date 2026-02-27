---
module: System
date: 2026-02-27
problem_type: best_practice
symptoms:
  - "Sequential file creation taking too long for 28+ file projects"
  - "Rate limits hit when spawning too many Opus agents simultaneously"
root_cause: "Need to balance parallelism against API rate limits and model cost"
resolution_type: workflow_improvement
severity: medium
tags: [parallel-agents, subagent-dispatch, rate-limits, cost-optimization]
---

# Parallel Subagent Execution Patterns for Plugin Development

## Problem
Building the flowstate plugin required creating 28+ files (skills, agents, commands). Sequential creation would be slow, but unlimited parallelism hit rate limits and account spending caps.

## Symptoms
- 4 parallel Opus agents hit rate limits after ~20 minutes
- 3 of 4 agents failed with "API Error: Rate limit reached"
- Only 1 of 4 agents completed before the rate limit

## What Didn't Work
**Spawning 4 heavy Opus agents simultaneously on large file-creation tasks.**
- **Why it failed:** Each agent reads multiple reference files + writes large outputs. Combined token consumption exceeded account rate limits.

## Solution
**Batch by logical dependency, not by parallelism maximization.**

Effective pattern for this project:
1. **Batch 1:** Scaffolding (inline, no subagent needed)
2. **Batch 2:** All skills + all agents (4 subagents — logically independent, same batch)
3. **Batch 3:** All commands + hooks (1 subagent — depends on skills/agents existing)
4. **Batch 4:** Extraction/refactoring (3 subagents — each touches different files)

**Key insight:** Group by file independence, not by task count. If two agents might write to the same file, they MUST be sequential.

## Why This Works
- Agents working on independent files never conflict
- Rate limits are per-account, not per-agent — fewer heavy agents = less risk
- If one agent fails, others' work is already committed
- Commit between batches creates save points

## Prevention
- Always commit completed work before dispatching the next batch of agents
- Monitor account spend limits, not just rate limits
- For 20+ file projects, plan 3-4 batches rather than one massive parallel dispatch
- Use `bypassPermissions` mode for build agents to avoid permission prompts blocking progress

## Related Issues
- See also: [claude-code-plugin-architecture-20260227.md](../best-practices/claude-code-plugin-architecture-20260227.md)
