<!-- retro:managed:start -->
## Retro-Discovered Patterns

- Resolution AWS infrastructure changes must go through a formal Change Request in Jira before implementation. The process lives in Confluence. Claude should: (1) look up the Change Request template in Confluence, (2) create the Jira ticket, (3) wait for approval signal from Christian, (4) then implement. After implementation, update the ticket with a status comment.

**Why:** Resolution has a formal ITIL-style change management process. Skipping it would violate compliance requirements.

**How to apply:** Any time Christian asks to make AWS infrastructure changes (new buckets, IAM changes, SCP modifications, etc.), check if a change request exists before running any mutating commands.
- Resolution AWS DC Testing follows a seasonal enable/test/decommission cycle that repeats approximately annually:
1. Temporarily enable a region (e.g., us-west-2) in the Dev account via SCP
2. Grant the tester (e.g., Johannes) Admin rights in that account
3. Run DC tests
4. Decommission all resources in the region and re-restrict via SCP

Initially treated as a one-off workspace task; after first run Christian moved scripts to permanent script directories for annual reuse.

**How to apply:** For DC testing requests, look in permanent AWS scripts directories (not workspace/) for existing runbooks before starting fresh.

<!-- retro:managed:end -->
