---
name: review
description: "Run 5 core review agents in parallel plus learnings researcher to catch issues before merge. Produces prioritized findings (P1/P2/P3) with todo files for tracking."
disable-model-invocation: true
argument-hint: "[optional: PR number, branch name, or file paths to review]"
---

Invoke the flowstate:multi-agent-review skill for: $ARGUMENTS
