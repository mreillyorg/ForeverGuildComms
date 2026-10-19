# Reverse Engineering Metadata

**Analysis Date**: 2026-10-19T02:40:00Z
**Analyzer**: AI-DLC (v1 workflow, aidlc-amit-verma power)
**Run type**: **Second rerun**, explicitly requested by the user
**Previous runs**: 2026-10-18T23:52:00Z against 0.1.0-beta; 2026-10-19T00:52:00Z against 0.2.0-beta
**Workspace**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\Addon-Manual\ForeverGuildComms-0.1.0-beta\ForeverGuildComms`
**Project**: Forever Guild Comms **0.4.1-beta**
**Project Type**: Brownfield, single-package WoW addon
**Total Files Analyzed**: 37

## Rerun Justification

Two independent grounds, either sufficient under `inception/workspace-detection.md`
Step 3:

1. **Explicit user request** — "using aidlc, please run another reverse-engineering pass to
   resync them".
2. **Artifacts were three releases stale** — they described 0.2.0-beta while the code had
   reached 0.4.1-beta.

## Releases Covered

| Release | Theme | Headline change |
| --- | --- | --- |
| 0.3.0-beta | Control | Titan nested menu via Blizzard `MenuUtil`; `messageSpacing` and `loginCooldown` made reachable and clamped; `A:SetOption` as the single validating writer; dead `A.lastMessages` removed |
| 0.4.0-beta | Voice | Three new modules: 8 curated languages, 29 regional and WoW-race RP styles, per-character storage, race filtering, accent strength; `A:CommsText` indirection; UTF-8-safe `A:ChatLimit` |
| 0.4.1-beta | Access | `Bindings.xml` with three opt-in hotkeys; `A:RunQuickAction` as a shared dispatcher; `ScanRecipes` returns a boolean for honest feedback |

Also landed alongside these, in separate commits: the integrated Windows installer and
`PACKAGING.md`; the addon icon, `.pkgmeta`, and the GitHub Actions release workflow.

## Metric Deltas

| Metric | 0.1.0 | 0.2.0 | 0.4.1 |
| --- | --- | --- | --- |
| Shipped Lua modules | 7 | 7 | 11 |
| Shipped Lua lines | 882 | 1,097 | 1,733 |
| Public methods on `A` | 38 | 45 | 62 |
| File-local helpers | 12 | 12 | 16 |
| Registered events / event frames | 14 / 1 | 14 / 1 | 14 / 1 |
| Named frame globals | 3 | 4 | 4 |
| Other globals | 4 | 4 | 8 |
| Business transactions | 9 | 10 | 13 |
| Per-character setting groups | 3 | 3 | 4 |
| Languages / accent styles | 0 / 0 | 0 / 0 | 8 / 29 |
| Offline harnesses / lines | 1 / 72 | 4 / 207 | 9 / 589 |
| Test lines as % of shipped Lua | 8% | 19% | 34% |
| CI pipelines | 0 | 0 | 1 |

## Artifacts Generated

All nine regenerated against 0.4.1.

- [x] business-overview.md — 13 transactions, BT-11/12/13, voice business rules
- [x] architecture.md — four routes to guild chat, the validating-setter hub, the optional voice layer, four new sequence diagrams
- [x] code-structure.md — 11-module load order with three ordering constraints, 8 new patterns, full file inventory
- [x] api-documentation.md — 17 new methods, the key-binding API, voice data models, accent strength semantics
- [x] component-inventory.md — three-release delta table
- [x] technology-stack.md — new Blizzard surfaces, encoding note, packaging and CI, 9-harness table
- [x] dependencies.md — load-order-critical edges, the removable voice layer, release-time supply chain
- [x] code-quality-assessment.md — status of all 17 prior recommendations plus 7 new findings
- [x] reverse-engineering-timestamp.md — this file

## Files Analyzed

### Shipped source (11 Lua modules, 1,733 lines)
`Core.lua` (476), `UI.lua` (286), `Options.lua` (286), `TitanMenu.lua` (127),
`Roster.lua` (123), `RaceProfiles.lua` (102), `Alerts.lua` (99), `Languages.lua` (81),
`Tabard.lua` (64), `Accents.lua` (51), `Broker.lua` (38)

### Shipped non-Lua
`Bindings.xml` (12), `Media/Icon.tga` (64 KB), `Media/ProjectIcon.png` (481 KB)

### Manifest and docs
`ForeverGuildComms.toc` (15), `README.md` (158), `PACKAGING.md` (113), `LICENSE` (21),
`.gitattributes` (21), `.gitignore` (9), `.pkgmeta` (13)

### Test harnesses (9 files, 589 lines)
`titanmenu.lua` (168), `settings.lua` (87), `smoke.lua` (75), `verify.lua` (69),
`keybindings.lua` (62), `timing.lua` (55), `voice.lua` (46), `icon.lua` (21),
`syntax.lua` (6)

### Installer and CI
`install/Install-ForeverGuildComms.ps1` (313), `install/INSTALL-README.txt` (66),
`install/Install-ForeverGuildComms.cmd` (31), `.github/workflows/package.yml` (30)

### Project steering, treated as authoritative design intent (8 files)
`product.md`, `structure.md`, `lua-style.md`, `guild-chat-safety.md`,
`forever-client-api.md`, `ui-frames.md`, `release-packaging.md`, `testing.md`

`ui-frames.md` was again listed but not read; its conventions were inferred from the
source. `testing.md` was read and found materially out of date — see the assessment.

## Verification Performed

- Read in full: `Core.lua`, `Languages.lua`, `Accents.lua`, `RaceProfiles.lua`,
  `TitanMenu.lua`, `Bindings.xml`, and the `voice`, `timing`, `icon`, and `keybindings`
  harnesses. Read in part: `Options.lua`, `UI.lua`, `titanmenu.lua`.
- Read the complete `git diff` for the 0.3.0, 0.4.0, 0.4.1, installer, and icon commits.
- File and line counts measured directly, not estimated.
- Method count (62 `function A:`), file-local helper count (16 `local function`), event
  registrations (14), and event frames (1) all measured by pattern search, per module and
  in total.
- Traced every `CommsText`, `VoiceText`, `LocalizeRoleText`, `LocalizeActivityType`,
  `RunQuickAction`, and `ChatLimit` call site to confirm the integration points.
- Version strings checked in all three required locations and confirmed to agree at
  `0.4.1-beta`: TOC line 6, `Core.lua` line 9, `README.md` line 1.
- Interface number confirmed still `16001`.
- Accent inventory counted from `accentOrder` and cross-checked against the `register`
  calls: 29 styles, 21 English, 8 across five other languages.
- Prior findings re-tested by pattern search: `A.lastMessages` now has **zero** references
  (resolved); `eventsSeen` has 3 (still unpruned); the `GetActivityType` closure persists;
  the `"Current Profession"` fallback persists; `entryIndex` still has 4 positional
  references; no `.luacheckrc` exists.
- `Options.lua`'s `OnDefault` read directly: confirmed still a one-level copy, confirmed it
  now also resets `A.char.voice`, and confirmed the duplicated `UpdateRequestPreview` line.
- `.kiro/steering/testing.md` read and diffed against reality: documents 1 of 9 harnesses
  and still asserts that `Options.lua`, `Tabard.lua`, and `Broker.lua` cannot be tested
  offline.

## Explicitly Not Verified

- **No code was executed.** No Lua interpreter is on PATH on this machine — `lua5.1`,
  `lua`, and `luajit` were all checked and none resolved — so none of the nine harnesses
  was run. Every statement about what the tests cover comes from reading them. Per the
  project's own testing rule, this is stated rather than glossed.
- **No in-game behaviour was observed.** Runtime event ordering, timer resolution,
  `MenuUtil` availability, `UIRadioButtonTemplate` availability, the Key Bindings panel
  registration, and what `UnitRace` actually returns for Skyborne on the live Forever
  client are all inferred from source and the project's API notes.
- **The tabard ordering issue remains an inference**, unchanged across all three passes,
  and still requires in-game confirmation before being treated as a defect.
- **The positional row-binding concern is a fragility assessment, not an observed bug.**
- **Translation quality was not assessed.** The eight locales are taken as given; this pass
  verified their structural integrity (all four templates present per locale, placeholders
  intact) but makes no claim about linguistic accuracy.

## Scope Note

The user has scoped all three runs to Reverse Engineering. Requirements Analysis has still
not been started, no extension opt-in questions have been presented, no extension rule
files have been loaded, and no extension configuration is recorded in `aidlc-state.md`.
