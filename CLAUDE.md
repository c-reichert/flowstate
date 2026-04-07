<!-- retro:managed:start -->
## Retro-Discovered Patterns

- AWS SSO login workflow: Claude runs the SSO login script (stored in aws/discovery workspace), then Christian approves the browser popup. Always run SSO login as the first step before any AWS CLI commands, especially after sessions expire. Christian reminded in session 68f7c469: 'there was also a SSO login script cause all sessions are currently expired. execute it before anything else, i'll approve in the browser.'
- Christian's GTD weekly review workflow (observed session 5999dc7f): uses voice mode while driving + Todoist MCP. Pattern:
1. Pull all Todoist projects + tasks
2. Give high-level spoken summary
3. Process inbox 2-3 items at a time, waiting for his verbal OK/close/move decisions
4. Review stale tasks (10+ months old) same way
5. Clean up empty project folders after closures
6. Braindump new tasks at end of session

Simple reminders go into a dedicated 'Simple Reminders' Todoist project. After review, cross-reference with LifeOS Obsidian vault for anything that should go on a someday/maybe list.

<!-- retro:managed:end -->
