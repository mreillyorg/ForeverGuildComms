# AI-DLC State Tracking

## Project Information
- **Project Name**: ForeverGuildComms (Forever Guild Comms **0.4.1-beta**)
- **Project Type**: Brownfield
- **Start Date**: 2026-10-18T23:45:00Z
- **Current Stage**: INCEPTION - Reverse Engineering (second rerun complete, awaiting user approval)

## Workspace State
- **Existing Code**: Yes
- **Programming Languages**: Lua 5.1 (addon), XML (key bindings), PowerShell and YAML (tooling)
- **Build System**: None for compilation; GitHub Actions packaging on a `v*` tag
- **Project Structure**: Single-package flat World of Warcraft addon, 11 modules
- **Reverse Engineering Needed**: Completed three times; artifacts current as of 2026-10-19T02:40:00Z
- **Workspace Root**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\Addon-Manual\ForeverGuildComms-0.1.0-beta\ForeverGuildComms`

## Code Location Rules
- **Application Code**: Workspace root (NEVER in aidlc-docs/)
- **Documentation**: aidlc-docs/ only
- **Structure patterns**: See code-generation.md Critical Rules
- **Project-specific constraints**: the addon folder must stay named exactly
  `ForeverGuildComms` with `ForeverGuildComms.toc` inside it, and source files stay flat.
  `Bindings.xml` is shipped from the addon root and must **not** be listed in the TOC.
  See `.kiro/steering/structure.md`.

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
- [x] Reverse Engineering - **Second rerun** completed 2026-10-19T02:40:00Z against 0.4.1-beta - awaiting approval
- [ ] Requirements Analysis - Not started (user has scoped all three runs to end after Reverse Engineering)
- [ ] User Stories - Not assessed
- [ ] Workflow Planning - Not started
- [ ] Application Design - Not assessed
- [ ] Units Generation - Not assessed

### CONSTRUCTION
- [ ] Not started

### OPERATIONS
- [ ] Placeholder stage

## Reverse Engineering Status
- [x] Reverse Engineering - Second rerun completed on 2026-10-19T02:40:00Z
- **Artifacts Location**: `aidlc-docs/inception/reverse-engineering/`
- **Artifacts target**: 0.4.1-beta. All nine regenerated.
- **Change span covered**: three releases — 0.3.0 (Titan nested menu, timing controls),
  0.4.0 (languages and accents), 0.4.1 (opt-in key bindings) — plus the installer,
  packaging, icon, and CI work committed alongside them.

## Reverse Engineering History

| Run | Date | Target | Trigger | Outcome |
| --- | --- | --- | --- | --- |
| 1 | 2026-10-18T23:52:00Z | 0.1.0-beta | First brownfield pass | 9 artifacts; gate never answered |
| 2 | 2026-10-19T00:52:00Z | 0.2.0-beta | Explicit rerun; artifacts stale | 9 artifacts regenerated; 3 of 15 findings resolved |
| 3 | 2026-10-19T02:40:00Z | 0.4.1-beta | Explicit rerun; artifacts three releases stale | 9 artifacts regenerated; 6 of 17 recommendations resolved, 1 half |

## Project Growth Across Passes

| Metric | 0.1.0 | 0.2.0 | 0.4.1 |
| --- | --- | --- | --- |
| Shipped Lua modules | 7 | 7 | 11 |
| Shipped Lua lines | 882 | 1,097 | 1,733 |
| Public methods | 38 | 45 | 62 |
| Business transactions | 9 | 10 | 13 |
| Offline harnesses | 1 | 4 | 9 |
| Test % of shipped Lua | 8% | 19% | 34% |

## Notes
- The user has scoped every run so far to end after Reverse Engineering, so the workflow
  stops at the approval gate rather than auto-advancing to Requirements Analysis.
- Eight pre-existing Kiro steering files encode product non-goals, Lua style, guild chat
  safety invariants, client API constraints, UI frame conventions, packaging, structure,
  and testing. They are treated as authoritative design intent.
- **Closed during run 3**: `.kiro/steering/testing.md` had been the number-one
  recommendation of run 2 and was still describing one of nine harnesses while claiming
  three modules could not be tested offline. It was rewritten during this run to document
  every harness and its coverage, to record that CI packages but does not test, and to
  identify `Tabard.lua` as the only module no harness loads.
- **Top open action item**: packaging is automated via GitHub Actions on a `v*` tag, but
  nothing in CI runs the nine harnesses or checks the three version strings. A tag can
  publish a release with no automated verification.
- No code was executed in any of the three runs; no Lua interpreter is installed on this
  machine.
