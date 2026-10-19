# Reverse Engineering Metadata

**Analysis Date**: 2026-10-19T03:20:00Z
**Analyzer**: AI-DLC (v1 workflow, aidlc-amit-verma power)
**Run type**: **Third rerun**, explicitly requested by the user
**Previous runs**: 0.1.0-beta (2026-10-18T23:52Z), 0.2.0-beta (2026-10-19T00:52Z), 0.4.1-beta (2026-10-19T02:40Z)
**Workspace**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\Addon-Manual\ForeverGuildComms-0.1.0-beta\ForeverGuildComms`
**Project**: Forever Guild Comms **0.4.3-beta**
**Project Type**: Brownfield, single-package WoW addon
**Total Files Analyzed**: 40

## Rerun Justification

Explicit user request, and verified as warranted before regenerating anything: the working
tree carries a new 229-line module, two new harnesses, and edits to eight other files, with
shipped Lua up 289 lines since the last pass.

## Releases Covered

| Release | Theme | Headline change |
| --- | --- | --- |
| 0.4.2-beta | Message variety | `MessageVariants.lua`: curated alternative phrasings for all four built-in templates across 8 languages and all 29 accents, selected by a non-repeating shuffle bag. New `randomizeMessages` setting, on by default. Draft caching in the help composer so the preview and the sent text cannot diverge |
| 0.4.3-beta | Maintenance | Two long-standing findings fixed: the tabard login-check ordering race, and the unbounded `A.eventsSeen` cache. Both landed with a dedicated regression harness |

## Findings Closed by This Change Set

Both had been reported in **all three** previous passes.

| Finding | First reported | Resolution |
| --- | --- | --- |
| Tabard initial-check ordering | 0.1.0 pass | `A:CheckTabard` restructured: it now always records `wasInCity`, uses a `tabardInitialCheckDone` latch so the 3-second login check can still prompt after the 1.2-second transition check has run, and a `tabardCityPrompted` flag to allow at most one city prompt per uninterrupted stay. `tests/tabard_dedup.lua` reproduces the original race explicitly |
| `A.eventsSeen` never pruned | 0.1.0 pass | New `A:PruneEventsSeen`, driven both by an activity-triggered sweep throttled to 60 seconds inside `IsDuplicate` and by a 300-second idle ticker registered in `Initialize`. Retention is `timingLimits.loginCooldown.max` (3600s), deliberately the longest supported cooldown so that raising `loginCooldown` later cannot re-admit a suppressed event. Malformed and future-dated timestamps are also discarded |

## Metric Deltas

| Metric | 0.1.0 | 0.2.0 | 0.4.1 | 0.4.3 |
| --- | --- | --- | --- | --- |
| Shipped Lua modules | 7 | 7 | 11 | 12 |
| Shipped Lua lines | 882 | 1,097 | 1,733 | 2,022 |
| Public methods on `A` | 38 | 45 | 62 | 64 |
| File-local helpers | 12 | 12 | 16 | 16 |
| Registered events / event frames | 14 / 1 | 14 / 1 | 14 / 1 | 14 / 1 |
| Business transactions | 9 | 10 | 13 | 14 |
| Account settings keys (excl. templates) | 11 | 12 | 12 | 13 |
| Languages / accent styles | 0 / 0 | 0 / 0 | 8 / 29 | 8 / 29 |
| Curated template variants | 0 | 0 | 0 | 204 |
| Offline harnesses / lines | 1 / 72 | 4 / 207 | 9 / 589 | 11 / 799 |
| Test lines as % of shipped Lua | 8% | 19% | 34% | 40% |

Registered events have now held at 14 on a single dispatcher across all six releases.

## Artifacts Generated

All nine regenerated against 0.4.3.

- [x] business-overview.md — BT-14, variant business rules, `MessageVariants.lua` description
- [x] architecture.md — the variant selection stage in the message pipeline, draft caching, pruning
- [x] code-structure.md — 12-module load order, new counts, shuffle-bag and draft-fingerprint patterns
- [x] api-documentation.md — `PruneEventsSeen`, `ChooseMessageTemplate`, the `preview` parameter, `randomizeMessages`
- [x] component-inventory.md — four-pass delta table
- [x] technology-stack.md — targeted update; stack unchanged
- [x] dependencies.md — `MessageVariants.lua` edges, still no new external dependency
- [x] code-quality-assessment.md — two findings closed, status of all prior items, new findings
- [x] reverse-engineering-timestamp.md — this file

## Files Analyzed

### Shipped source (12 Lua modules, 2,022 lines)
`Core.lua` (505), `UI.lua` (302), `Options.lua` (287), `MessageVariants.lua` (229),
`TitanMenu.lua` (128), `Roster.lua` (123), `RaceProfiles.lua` (109), `Alerts.lua` (99),
`Languages.lua` (81), `Tabard.lua` (70), `Accents.lua` (51), `Broker.lua` (38)

### Shipped non-Lua
`Bindings.xml` (12), `Media/Icon.tga` (64 KB), `Media/ProjectIcon.png` (481 KB)

### Manifest and docs
`ForeverGuildComms.toc` (16), `README.md` (169), `PACKAGING.md` (113), `LICENSE` (21),
`.gitattributes` (21), `.gitignore` (9), `.pkgmeta` (13)

### Test harnesses (11 files, 799 lines)
`titanmenu.lua` (168), `tabard_dedup.lua` (117), `variations.lua` (93), `settings.lua` (87),
`smoke.lua` (75), `verify.lua` (69), `keybindings.lua` (62), `timing.lua` (55),
`voice.lua` (46), `icon.lua` (21), `syntax.lua` (6)

### Installer and CI
`install/Install-ForeverGuildComms.ps1` (313), `install/INSTALL-README.txt` (66),
`install/Install-ForeverGuildComms.cmd` (31), `.github/workflows/package.yml` (30)

### Project steering (8 files)
`product.md`, `structure.md`, `lua-style.md`, `guild-chat-safety.md`,
`forever-client-api.md`, `ui-frames.md`, `release-packaging.md`, `testing.md`

`testing.md` was rewritten immediately after the previous pass and is now accurate, though
it predates the two new harnesses and does not yet list them. `ui-frames.md` was again not
read; its conventions were inferred from the source.

## Verification Performed

- Read `MessageVariants.lua`, `tests/tabard_dedup.lua`, and `tests/variations.lua` in full.
- Read the complete working-tree diff for `Core.lua`, `Tabard.lua`, `RaceProfiles.lua`,
  `UI.lua`, `Options.lua`, `TitanMenu.lua`, `tests/syntax.lua`, the TOC, and `README.md`.
- File and line counts measured directly, not estimated, and compared against the figures
  recorded by the previous pass.
- Method count (64 `function A:`), file-local helpers (16), event registrations (14), and
  event frames (1) all re-measured by pattern search.
- Version strings confirmed in sync at `0.4.3-beta` across the TOC (line 6), `Core.lua`
  (line 9), and `README.md` (line 1).
- `MessageVariants.lua` confirmed added to both the TOC load order and `tests/syntax.lua`.
- Variant inventory counted from the source by pattern match, not estimated: **68** locale
  variants across 8 languages and **136** accent variants across 29 accents, **204** in
  total. Every one of the 29 accents and all 8 languages carry entries for all four kinds.
- Confirmed the accent-flair application moved *after* variant selection in
  `A:VoiceText`, so flair prefixes whichever wording was chosen.
- Confirmed `tests/variations.lua` asserts variant completeness for every accent in
  `accentOrder` across all four kinds, which makes a missing entry a test failure rather
  than a silent fallback.

## Explicitly Not Verified

- **No code was executed.** No Lua interpreter is on PATH on this machine, so none of the
  eleven harnesses was run. All statements about coverage come from reading them. The
  project's own testing rule requires saying this rather than glossing it.
- **No in-game behaviour was observed.** In particular the tabard fix addresses an event
  ordering race that was itself inferred from source across three passes; the new harness
  simulates the ordering it believes occurs, but the real `PLAYER_LOGIN` versus
  `PLAYER_ENTERING_WORLD` sequence in the live Forever client remains unconfirmed. The fix
  is sound against the simulated ordering and is defensive enough to be correct either
  way, but "verified in game" it is not.
- **Shuffle-bag distribution was not statistically analysed.** The harness asserts
  no-repeat-within-bag and no-adjacent-repeat; this pass did not examine the uniformity of
  `math.random` sequences, nor whether the seed is initialised.
- **Translation quality of the 204 new variants was not assessed**, only their structural
  integrity: every accent and kind has at least one entry, and placeholders survive
  interpolation.

## Scope Note

The user has scoped all four runs to Reverse Engineering. Requirements Analysis has still
not been started, no extension opt-in questions have been presented, and no extension
configuration is recorded in `aidlc-state.md`.
