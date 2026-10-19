# AI-DLC State Tracking

## Project Information
- **Project Name**: ForeverGuildComms (Forever Guild Comms **0.4.3-beta**)
- **Project Type**: Brownfield
- **Start Date**: 2026-10-18T23:45:00Z
- **Current Stage**: INCEPTION - Reverse Engineering (third rerun complete, awaiting user approval)

## Workspace State
- **Existing Code**: Yes
- **Programming Languages**: Lua 5.1 (addon), XML (key bindings), PowerShell and YAML (tooling)
- **Build System**: None for compilation; GitHub Actions packaging on a `v*` tag
- **Project Structure**: Single-package flat World of Warcraft addon, 12 modules
- **Reverse Engineering Needed**: Completed four times; artifacts current as of 2026-10-19T03:20:00Z
- **Workspace Root**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\Addon-Manual\ForeverGuildComms-0.1.0-beta\ForeverGuildComms`

## Code Location Rules
- **Application Code**: Workspace root (NEVER in aidlc-docs/)
- **Documentation**: aidlc-docs/ only
- **Project-specific constraints**: the addon folder must stay named exactly
  `ForeverGuildComms` with `ForeverGuildComms.toc` inside it, and source files stay flat.
  `Bindings.xml` is shipped from the addon root and must **not** be listed in the TOC.

## Extension Configuration
Not yet determined. Extension opt-in questions are presented during Requirements
Analysis, which has not run. Only the three `*.opt-in.md` files were loaded at workflow
start; no full extension rule files have been loaded.

| Extension | Enabled | Decided At |
| --- | --- | --- |
| security/baseline | Undecided | - |
| resiliency/baseline | Undecided | - |
| testing/property-based | Undecided | - |

## Stage Progress

### INCEPTION
- [x] Workspace Detection - Completed 2026-10-18T23:45:00Z - Brownfield
- [x] Reverse Engineering - Completed 2026-10-18T23:52:00Z against 0.1.0-beta
- [x] Reverse Engineering - Rerun completed 2026-10-19T00:52:00Z against 0.2.0-beta
- [x] Reverse Engineering - Second rerun completed 2026-10-19T02:40:00Z against 0.4.1-beta
- [x] Reverse Engineering - **Third rerun** completed 2026-10-19T03:20:00Z against 0.4.3-beta - awaiting approval
- [ ] Requirements Analysis - Not started (user has scoped all four runs to end after Reverse Engineering)
- [ ] User Stories - Not assessed
- [ ] Workflow Planning - Not started
- [ ] Application Design - Not assessed
- [ ] Units Generation - Not assessed

### CONSTRUCTION
- [ ] Not started

### OPERATIONS
- [ ] Placeholder stage

## Reverse Engineering Status
- [x] Reverse Engineering - Third rerun completed on 2026-10-19T03:20:00Z
- **Artifacts Location**: `aidlc-docs/inception/reverse-engineering/`
- **Artifacts target**: 0.4.3-beta. All nine regenerated.
- **Change span covered**: 0.4.2 (varied message wording, 204 curated variants, shuffle-bag
  selection, fingerprinted draft caching) and 0.4.3 (tabard login-ordering fix, bounded
  dedup cache), plus two new regression harnesses.

## Reverse Engineering History

| Run | Date | Target | Trigger | Outcome |
| --- | --- | --- | --- | --- |
| 1 | 2026-10-18T23:52Z | 0.1.0-beta | First brownfield pass | 9 artifacts; gate never answered |
| 2 | 2026-10-19T00:52Z | 0.2.0-beta | Explicit rerun; artifacts stale | 3 of 15 findings resolved |
| 3 | 2026-10-19T02:40Z | 0.4.1-beta | Explicit rerun; three releases stale | 6 of 17 resolved, 1 half |
| 4 | 2026-10-19T03:20Z | 0.4.3-beta | Explicit rerun; verified real change first | 3 of 19 resolved, incl. both findings first raised against 0.1.0 |

## Project Growth Across Passes

| Metric | 0.1.0 | 0.2.0 | 0.4.1 | 0.4.3 |
| --- | --- | --- | --- | --- |
| Shipped Lua modules | 7 | 7 | 11 | 12 |
| Shipped Lua lines | 882 | 1,097 | 1,733 | 2,022 |
| Public methods | 38 | 45 | 62 | 64 |
| Business transactions | 9 | 10 | 13 | 14 |
| Offline harnesses | 1 | 4 | 9 | 11 |
| Test % of shipped Lua | 8% | 19% | 34% | 40% |
| Modules with no harness | 6 | 3 | 1 | **0** |

## Notes
- The user has scoped every run to end after Reverse Engineering, so the workflow stops at
  the approval gate rather than auto-advancing to Requirements Analysis.
- **Closed this run**: the two oldest findings in the project, both first reported against
  0.1.0 — the tabard login-check ordering race and the unbounded `A.eventsSeen` cache.
  Both fixes shipped with `tests/tabard_dedup.lua`, which reproduces the original race
  explicitly rather than only testing the corrected behaviour.
- **Also closed**: `Tabard.lua` was the last module with no harness. Every module is now
  loaded by at least one test.
- **Top open action item, unchanged for three passes**: packaging is automated on a `v*`
  tag but nothing in CI runs the eleven harnesses or checks the three version strings. It
  is also the cheapest item on the list — the suite is pure Lua with no dependencies and
  its run commands are already documented in `.kiro/steering/testing.md`.
- **New this run**: `randomizeMessages` defaults to `true`, making it the first setting in
  the project's history whose default changes existing output on upgrade. The README
  documents the default but not the departure from convention.
- `.kiro/steering/testing.md` was corrected after run 3 and is accurate, but predates the
  two harnesses added in 0.4.3 and does not list them.
- No code was executed in any of the four runs; no Lua interpreter is installed on this
  machine.
