<!-- retro:managed:start -->
## Retro-Discovered Patterns

- Christian follows a Change Request workflow for significant AWS infrastructure changes: (1) look up the change process in Confluence, (2) create a Jira Change Request ticket via Atlassian MCP, (3) get approval, (4) implement, (5) update the ticket with a status comment. This was observed for the Glacier→S3 migration and is driven by a formal change management process documented in Confluence.
- The PAI security-validator.ts hook enforces uv over python3 (blocks python3 calls with 'uvEnforcement: BLOCKED') and blocks curl network requests. When triggered, it closes the stream causing 'Stream closed' errors on Bash, Write, and MCP tools. If many tools fail with Stream closed in sequence, suspect the security validator hook — check $PAI_DIR/hooks/security-validator.ts allow list. Workaround: use uv run python instead of python3, avoid direct curl calls.

<!-- retro:managed:end -->
