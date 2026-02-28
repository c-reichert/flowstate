---
name: skill:finishing-a-branch
description: Use when implementation is complete and all tests pass — guides branch completion by presenting structured options for merge, PR, or cleanup.
---

# Finishing a Branch

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

## Step 1: Verify All Tests Pass

**Invoke the flowstate:verification-before-completion skill.** Run the full test suite. Read output. Confirm zero failures.

**If tests fail:** Stop. Report failures. Do NOT proceed to Step 2.

## Step 2: Present Options

Use `AskUserQuestion` to present exactly these 4 options:

```
Implementation complete. All tests pass. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Determine `<base-branch>` first:
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

## Step 3: Execute Chosen Option

### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Verify tests on merged result
<test command>
# If tests pass
git branch -d <feature-branch>
```

### Option 2: Push and Create PR

See the **`requesting-code-review`** skill for what to include in the PR description.

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<what was built and why>

## Testing
<tests added, pass evidence, coverage summary>

## Post-Deploy Monitoring
<what to monitor, healthy signals, rollback triggers>
EOF
)"
```

Report the PR URL.

### Option 3: Keep As-Is

Report: "Keeping branch `<name>`. Worktree preserved at `<path>`."

Do NOT clean up worktree or branch.

### Option 4: Discard

**Require typed confirmation.** Show what will be deleted (branch, commits, worktree). Wait for exact "discard" confirmation, then:

```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Step 4: Clean Up Worktree (Options 1, 2, 4 only)

Option 3 preserves the worktree. For all others:

```bash
git worktree list  # check if in a worktree
git worktree remove <worktree-path>  # if applicable
```

## Step 5: Optionally Delete Feature Branch

For Option 2 (PR created), ask: "Delete local feature branch, or keep it?"

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | - | ask |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Red Flags

- Never proceed with failing tests or merge without verifying tests on the result
- Never delete work without typed confirmation or force-push without explicit request
- Always invoke verification-before-completion before offering options
- Always present exactly 4 options and get typed confirmation for Option 4
