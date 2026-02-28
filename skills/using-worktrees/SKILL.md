---
name: using-worktrees
description: Create and manage git worktrees for isolated feature development — used at start of work phase after plan approval
---

# Using Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository. Each worktree gets its own working directory and branch while sharing the object store. This prevents half-finished work from polluting the main branch and enables parallel development.

**Golden rule:** One branch per worktree. Never checkout a branch that is already checked out in another worktree.

**Announce at start:** "Setting up an isolated worktree for this feature."

## When to Create

- At the **start of the work phase**, after plan approval
- Before executing any implementation tasks
- When you need isolation from the current workspace

Do NOT create worktrees during brainstorming or planning. Those phases operate on the main branch.

## Creation Flow

### Step 1: Create Worktree Directory

```bash
# Check if .worktrees/ already exists
ls -d .worktrees 2>/dev/null

# If not, create it
mkdir -p .worktrees
```

### Step 2: Verify .gitignore

The worktree directory MUST be gitignored. Check and fix immediately if not.

```bash
# Check if .worktrees is ignored
git check-ignore -q .worktrees 2>/dev/null
echo $?  # 0 = ignored (good), 1 = NOT ignored (fix it)
```

If NOT ignored:

```bash
echo ".worktrees/" >> .gitignore
git add .gitignore
git commit -m "chore: add .worktrees to gitignore"
```

Do not proceed until the directory is ignored. Committing worktree contents to the repository is a serious mistake.

### Step 3: Create the Worktree

```bash
# Derive feature name from plan
git worktree add .worktrees/<feature-name> -b feature/<feature-name>
cd .worktrees/<feature-name>
```

Branch naming: use `feature/<name>`, `fix/<name>`, or `refactor/<name>` matching the plan type.

### Step 4: Auto-Detect Project Setup

Run dependency installation based on project files found in the worktree:

```bash
# Node.js
[ -f package-lock.json ] && npm install
[ -f yarn.lock ] && yarn install
[ -f pnpm-lock.yaml ] && pnpm install
[ -f bun.lockb ] && bun install

# Python
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && [ -d .venv ] && uv sync || pip install -e .
[ -f Pipfile ] && pipenv install
[ -f poetry.lock ] && poetry install

# Ruby
[ -f Gemfile.lock ] && bundle install

# Rust
[ -f Cargo.toml ] && cargo build

# Go
[ -f go.mod ] && go mod download

# Elixir
[ -f mix.lock ] && mix deps.get

# PHP
[ -f composer.lock ] && composer install
```

If no recognizable project files exist, skip this step.

### Step 5: Run Tests for Clean Baseline

Run the project's test suite to confirm a clean starting state:

```bash
# Use whatever test command the project uses
npm test          # Node.js
pytest            # Python
bundle exec rspec # Ruby
cargo test        # Rust
go test ./...     # Go
mix test          # Elixir
```

**If tests pass:** Report the count and confirm the worktree is ready.

**If tests fail:** Report failures to the user. Ask whether to proceed or investigate. Do NOT silently continue with a broken baseline — you will not be able to distinguish new bugs from pre-existing ones.

### Step 6: Report

```
Worktree ready at .worktrees/<feature-name>
Branch: feature/<feature-name>
Dependencies installed: [yes/no/skipped]
Tests: [N passing, 0 failures]
Ready to implement.
```

## Cleanup Flow

Run cleanup after work is complete and merged (or abandoned).

### Step 1: Verify Tests Pass

```bash
cd .worktrees/<feature-name>
# Run full test suite
# All tests must pass before cleanup
```

### Step 2: Return to Main Worktree

```bash
cd /path/to/main/repo
```

### Step 3: Remove the Worktree

```bash
git worktree remove .worktrees/<feature-name>
```

### Step 4: Optionally Delete the Branch

If the branch has been merged:

```bash
git branch -d feature/<feature-name>
```

If the branch was abandoned (unmerged), confirm with user before:

```bash
git branch -D feature/<feature-name>
```

## Common Gotchas

### Use `git worktree remove`, not `rm -rf`

Deleting a worktree directory with `rm -rf` leaves stale entries in `.git/worktrees/`. Git will refuse to create a new worktree with the same branch name. Always use `git worktree remove` for clean removal.

If you already used `rm -rf`:

```bash
git worktree prune
```

### Dependencies Must Be Re-Installed

Each worktree has its own working directory. `node_modules/`, `.venv/`, `vendor/` do not carry over from the main checkout. Always run dependency installation in the new worktree.

### Submodules Need Initialization

If the project uses git submodules, initialize them in the new worktree:

```bash
cd .worktrees/<feature-name>
git submodule update --init --recursive
```

### Disk Space

Each worktree duplicates the working tree (not the object store). For large repos with heavy build artifacts, worktrees can consume significant disk space. Clean up promptly after merging.

### One Branch Per Worktree

Git enforces this: you cannot check out a branch that is already checked out in another worktree. If you need the same branch, use the existing worktree.

To see all active worktrees:

```bash
git worktree list
```

### Stale Worktrees

If a worktree directory was moved or deleted outside of git:

```bash
git worktree prune   # Cleans up stale entries
git worktree list    # Verify clean state
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify gitignored) |
| `.worktrees/` missing | Create it, add to .gitignore |
| Not in .gitignore | Add immediately, commit |
| Tests fail at baseline | Report to user, ask before proceeding |
| No project files found | Skip dependency install |
| Cleanup after merge | `git worktree remove` then `git branch -d` |
| Cleanup after abandon | `git worktree remove` then confirm `git branch -D` |
| Stale worktree entry | `git worktree prune` |

## Integration

**Called by:**
- `/workflow:work` (Phase 1: Setup) — creates worktree before task execution begins

**Pairs with:**
- `tdd` skill — TDD enforcement runs inside the worktree
- Plan documents — branch name derived from plan title/type
