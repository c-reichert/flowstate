---
name: warn-push-version-check
enabled: true
event: bash
pattern: git\s+push
action: warn
---

**Version check before push.**

This project requires a version bump in `package.json` on every `feat:` or `fix:` commit. Before pushing, verify:

1. Check the most recent commit message — is it a `feat:` or `fix:` commit?
2. If yes, does the commit (or a subsequent `chore: bump version` commit) include an updated `version` field in `package.json`?
3. If the version wasn't bumped, do it now before pushing.

This check exists because the version bump has been forgotten in multiple past sessions, requiring the user to catch it manually each time.
