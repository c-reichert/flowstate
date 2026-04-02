<!-- retro:managed:start -->
## Retro-Discovered Patterns

- Atlassian Forge app development requires an adapted workflow — TDD does not work in the Forge stack. Christian confirmed: no automated test suite currently, no desire to change directory layout. Verification gate substitution: `yarn lint` + `tsc --noEmit`. A dedicated `flowstate:workflow:work-forge` command was built (added to re-compound-power plugin, version bumped and pushed to GitHub on 2026-03-18) to handle Forge-specific execution cycles without requiring a test suite.
- When looking up Jira tickets or Confluence pages, use the Atlassian MCP tools — do NOT open URLs in a web browser or use web-fetch tools. In session eaccfa29, Claude tried a browser/web approach for a Jira ticket URL and the user immediately interrupted: 'use atlassian mcp'.

**Why:** Atlassian MCP gives structured data directly; web navigation is slower and less reliable.
**How to apply:** For any resolution.atlassian.net URL the user shares, reach for `mcp__atlassian__getJiraIssue` or `mcp__atlassian__getConfluencePage` first.
- When configuring fritzinfluxdb (or any Fritz!Box TR-064 client) for Christian's home Fritz!Box, use username = 'cr' — NOT the MyFRITZ! account email 'cr@3bc.me'. The Fritz!Box uses its local username for TR-064 auth, not the MyFRITZ! identifier. Also use TLS (port 49443) rather than HTTP (49000) — with HTTP, fritzconnection library misidentifies SOAP-level auth failures as HTTP auth errors and throws FritzAuthorizationError, masking the real issue.

**Why:** cr@3bc.me is Christian's MyFRITZ! account email but TR-064 uses the local account username 'cr'. Discovered after lengthy debug session in 2026-03-08.

**How to apply:** Any future fritzinfluxdb, fritzconnection, or TR-064 automation for this Fritz!Box: user = 'cr', use TLS port.

<!-- retro:managed:end -->
