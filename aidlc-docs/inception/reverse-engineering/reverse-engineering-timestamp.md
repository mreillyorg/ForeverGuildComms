# Reverse Engineering Metadata

**Analysis Date**: 2026-10-19T00:52:00Z
**Analyzer**: AI-DLC (v1 workflow, aidlc-amit-verma power)
**Run type**: **Rerun**, explicitly requested by the user
**Previous run**: 2026-10-18T23:52:00Z against 0.1.0-beta
**Workspace**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\Addon-Manual\ForeverGuildComms-0.1.0-beta\ForeverGuildComms`
**Project**: Forever Guild Comms **0.2.0-beta**
**Project Type**: Brownfield, single-package WoW addon
**Total Files Analyzed**: 23

## Rerun Justification

Two independent grounds, either sufficient under `inception/workspace-detection.md`
Step 3:

1. **Explicit user request** — "re-run Reverse Engineering for new changes". This forces a
   rerun regardless of staleness.
2. **Artifacts were genuinely stale** — previous artifacts written 2026-10-19T00:37:25,
   sources modified 2026-10-19T00:40:41.

## Change Set Analyzed

Measured with `git diff HEAD`: **7 files modified, +257 / -31**, plus 3 new untracked
test files. The previous artifact set was committed in `a3d52a3`.

| File | Change | Nature |
| --- | --- | --- |
| `Core.lua` | +97 / -10 | New `outgoingMode` setting and `pendingApprovals` state; four new methods (`StageApproval`, `ApproveMessage`, `DismissMessage`, `ClearApprovals`); rewritten `QueueGuild` and `DrainQueue`; two new load-time migrations; `/fgc verify` and `/fgc review`; expanded `/fgc status`; new login banner |
| `UI.lua` | +95 / -8 | New `FGCApprovalsFrame` with `BuildApprovalsUI`, `UpdateApprovalsUI`, `ShowApprovals`; `Review (n)` shortcut on the alerts window; repositioned alerts controls |
| `Options.lua` | +50 / -7 | Automatic/Verify radio pair; per-template *Use default* button; default text shown beneath each editor; taller content frame; reworded guidance |
| `README.md` | +20 / -7 | New "Automatic versus Verify mode" section; new command; revised Titan description, limitations, and a 10-step test sequence |
| `Broker.lua` | +5 / -1 | Pending-review count and mode in the tooltip; left-click prioritizes review; `| Review n` in the label |
| `Roster.lua` | +1 / -0 | Guild change now also calls `ClearApprovals` |
| `ForeverGuildComms.toc` | +1 / -1 | Version bump only |
| `tests/verify.lua` | new, 66 lines | Approval workflow against the real queue and backlog |
| `tests/settings.lua` | new, 63 lines | SavedVariables migration and Options widgets via a fake widget layer |
| `tests/syntax.lua` | new, 6 lines | Compiles all seven shipped modules |

Unchanged: `Alerts.lua`, `Tabard.lua`, `tests/smoke.lua`, `LICENSE`, `.gitignore`.
Their file timestamps moved but their content did not.

## Metric Deltas

| Metric | 0.1.0 | 0.2.0 |
| --- | --- | --- |
| Shipped Lua lines | 882 | 1,097 |
| Public methods on `A` | 38 | 45 |
| File-local helpers | 12 | 12 |
| Registered events / event frames | 14 / 1 | 14 / 1 |
| Named frame globals | 3 | 4 |
| Business transactions | 9 | 10 |
| Settings keys excluding templates | 11 | 12 |
| Offline harnesses / lines | 1 / 72 | 4 / 207 |
| Test lines as % of shipped source | 8% | 19% |

## Artifacts Generated

All nine regenerated against 0.2.0.

- [x] business-overview.md — new BT-10, mode-aware BT-1/2/3, new dictionary terms
- [x] architecture.md — the three routes to guild chat, new sequence diagrams, mode-switch flow
- [x] code-structure.md — new counts, new state, new patterns, four-harness inventory
- [x] api-documentation.md — seven new methods, changed `QueueGuild`/`DrainQueue` contracts, new entry record
- [x] component-inventory.md — delta table against 0.1.0
- [x] technology-stack.md — targeted update; stack itself unchanged
- [x] dependencies.md — new internal edges, revised offline-testability finding
- [x] code-quality-assessment.md — status of all 15 prior findings plus 7 new ones
- [x] reverse-engineering-timestamp.md — this file

## Files Analyzed

### Shipped source (7 files, 1,097 lines)
`Core.lua` (306), `UI.lua` (285), `Options.lua` (183), `Roster.lua` (123),
`Alerts.lua` (98), `Tabard.lua` (64), `Broker.lua` (38)

### Manifest and docs (4 files)
`ForeverGuildComms.toc` (15), `README.md` (78), `LICENSE` (21), `.gitignore` (41)

### Test harnesses (4 files, 207 lines)
`tests/smoke.lua` (72), `tests/verify.lua` (66), `tests/settings.lua` (63),
`tests/syntax.lua` (6)

### Project steering, treated as authoritative design intent (8 files)
`product.md`, `structure.md`, `lua-style.md`, `guild-chat-safety.md`,
`forever-client-api.md`, `ui-frames.md`, `release-packaging.md`, `testing.md`

`ui-frames.md` was again listed but not read; its conventions were inferred from the
source. `testing.md` was read and found to be out of date against the current test suite.

## Verification Performed

- Full `git diff HEAD` read for all seven modified files; all three new test files read in
  full.
- File and line counts measured directly, not estimated.
- Method count (45 `function A:`) and file-local helper count (12 `local function`)
  measured by pattern search.
- Event registrations (14) and event-frame count (1) re-measured to confirm the new
  feature added neither.
- Version strings checked in all three required locations and confirmed to agree at
  `0.2.0-beta`: TOC line 5, `Core.lua` line 4, `README.md` line 1.
- Interface number confirmed still `16001`.
- Prior findings re-tested by pattern search: `A.lastMessages` still has exactly one
  reference (its declaration); `messageSpacing` and `loginCooldown` still have two each
  (default plus consumer, no UI control); `Options.lua` still builds exactly 9 toggles.
- `Options.lua`'s `OnDefault` read directly to confirm it still performs a one-level copy
  and now also resets `outgoingMode`.
- Git state read: three commits on `main`; the 0.2.0 work is uncommitted.

## Explicitly Not Verified

- **No code was executed.** No Lua interpreter is on PATH on this machine — `lua5.1`,
  `lua`, `luajit`, `lua5.4`, and `lua54` were all checked and none resolved — so none of
  the four harnesses was run. Every statement about what the tests cover comes from
  reading them, not from observing them pass. Per the project's own testing rule, this is
  stated rather than glossed.
- **No in-game behavior was observed.** Runtime event ordering, timer resolution, frame
  template availability (including the new `UIRadioButtonTemplate`), and actual Blizzard
  API responses are all inferred from source and the project's API notes.
- **The tabard ordering issue remains an inference**, unchanged from the previous pass and
  still requiring in-game confirmation before being treated as a defect.
- **The row-index-binding concern is a fragility assessment, not an observed bug.** The
  current code is safe because every mutation path refreshes the UI; the finding is about
  how easily that could be broken, not about present behavior.

## Scope Note

The user scoped the original run to "up to and including Reverse Engineering" and this
rerun to the same stage. Requirements Analysis has still not been started, no extension
opt-in questions have been presented, no extension rule files have been loaded, and no
extension configuration is recorded in `aidlc-state.md`.
