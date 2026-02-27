---
module: [Module or "System"]
date: [YYYY-MM-DD]
problem_type: [from schema enum]
symptoms:
  - [Observable symptom 1]
  - [Observable symptom 2]
root_cause: [Free text description]
resolution_type: [from schema enum]
severity: [critical|high|medium|low]
tags: [keyword1, keyword2, keyword3]
---

# [Clear Problem Title]

## Problem
[1-2 sentence clear description]

## Symptoms
- [Observable symptom 1]
- [Observable symptom 2]

## What Didn't Work
**Attempted Solution 1:** [Description]
- **Why it failed:** [Technical reason]

## Solution
[The actual fix that worked]

**Code changes:**
```[language]
# Before (broken):
[problematic code]

# After (fixed):
[corrected code]
```

## Why This Works
1. What was the ROOT CAUSE?
2. Why does the solution address this root cause?

## Prevention
- [Specific coding practice to avoid recurrence]
- [What to watch out for]
- [How to catch early]

## Related Issues
- See also: [related-issue.md](../category/related-issue.md)
