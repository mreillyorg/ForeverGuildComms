# Component Inventory

**Analysis target**: Forever Guild Comms **0.2.0-beta**
**Supersedes**: the 0.1.0-beta pass of 2026-10-18

This project is a **single package**. It is not a multi-package workspace, so the
conventional package categories below are mapped onto the addon's seven source modules,
which are the real units of organization.

## Application Packages

| Component | Type | Purpose |
| --- | --- | --- |
| `ForeverGuildComms` | WoW addon (single package) | The entire deliverable. One TOC, seven Lua modules, flat layout, loaded in declared order by the client. |

### Modules within the package

| Module | Role | Purpose | 0.2.0 |
| --- | --- | --- | --- |
| `Core.lua` | Foundation | Shared namespace, defaults, SavedVariables init and migrations, identity and formatting helpers, the guild send queue, the approval backlog, slash commands, the single event dispatcher | **+79 lines** |
| `Roster.lua` | Feature | Roster read, baseline, and diff; login greetings, level-up congratulations, guild-join parsing; clears the approval backlog on a guild change | **+1 line** |
| `Alerts.lua` | Feature | Guild chat parsing, craft and group detection, recipe cache scan, private alert list | unchanged |
| `Tabard.lua` | Feature | Capital city detection, tabard slot check, two reminder popups | unchanged |
| `UI.lua` | Presentation | Alerts inbox, the new Verify Guild Messages review window, Ask-for-Help compose window, live preview, explicit sends | **+90 lines** |
| `Options.lua` | Presentation | Settings canvas panel, the Automatic/Verify radio pair, toggles, template editors with Use default buttons | **+41 lines** |
| `Broker.lua` | Optional integration | LibDataBroker data object reporting counts, pending reviews, and the current mode | **+4 lines** |

## Infrastructure Packages

None. There is no CDK, Terraform, CloudFormation, container, or deployment script in this
project. Deployment is a file copy into the client's `AddOns` directory.

## Shared Packages

None as separate packages. The shared-code role is played by `Core.lua`, which every
other module depends on through the single shared table `A`. No library is embedded, by
deliberate policy: the Titan/LibDataBroker integration uses Titan's own copy through
`LibStub("LibDataBroker-1.1", true)`.

## Test Packages

Four offline harnesses, up from one. All are deliberately excluded from the TOC and from
the shipped zip.

| Component | Type | Lines | Purpose |
| --- | --- | --- | --- |
| `tests/syntax.lua` | Compile check | 6 | **New.** `loadfile` every one of the seven shipped modules and assert it compiles, without executing any of it. The cheapest possible guard against a syntax error shipping. |
| `tests/smoke.lua` | Unit / logic | 72 | Roster diffing (self level-up excluded, login greeting, other member's level-up), guild-join parsing including the self case, craft and group chat detection including the self case, and learned-versus-unlearned recipe caching. |
| `tests/verify.lua` | Unit / logic | 66 | **New.** The approval workflow against the *real* `QueueGuild`, `DrainQueue`, `StageApproval`, `ApproveMessage`, `DismissMessage`, and `ClearApprovals`. Captures `C_Timer.After` callbacks in a list so the drain timer can be fired deliberately, and asserts `SendChatMessage` is only ever called with the `"GUILD"` channel. |
| `tests/settings.lua` | Unit / integration | 63 | **New.** SavedVariables migration and the Options panel. Uses a metatable-driven fake widget layer so `Options.lua` loads offline, then finds widgets by template name and label text and invokes their stored `OnClick` handlers. |

No performance, contract, or end-to-end test package exists. `Tabard.lua`, `Broker.lua`,
and `UI.lua` still have no automated coverage and are verified by the manual in-game
checklist.

## Supporting Files

| File | Purpose | 0.2.0 |
| --- | --- | --- |
| `ForeverGuildComms.toc` | The only manifest: interface version, metadata, SavedVariables declarations, optional dependency, load order | version bumped |
| `README.md` | Install steps, features, commands, the new Automatic-versus-Verify section, templates, limitations, a 10-step test sequence, debugging notes | **+11 lines** |
| `LICENSE` | License text | unchanged |
| `.gitignore` | Blocks compiled Lua, archives, object files, libraries, shared objects, and executables | unchanged |

## Development-Time Configuration

| Path | Purpose |
| --- | --- |
| `.kiro/steering/*.md` | Eight project steering documents encoding product non-goals, Lua style, guild chat safety invariants, Forever client API constraints, UI frame conventions, packaging rules, project structure, and the testing process. **`testing.md` is now out of date — see `code-quality-assessment.md`.** |
| `.kiro/aws-aidlc-rule-details/` | AI-DLC v1 workflow rule details, installed by the aidlc power |
| `aidlc-docs/` | AI-DLC artifacts, including this inventory |

These are excluded from the shipped zip.

## Total Count

- **Total Packages**: 1
- **Application**: 1 (seven modules within it)
- **Infrastructure**: 0
- **Shared**: 0 (the shared-code role is internal, in `Core.lua`)
- **Test**: 4 harness files, none packaged

### Shipped source

| Metric | 0.1.0 | 0.2.0 | Change |
| --- | --- | --- | --- |
| Lua modules | 7 | 7 | - |
| Lua lines | 882 | 1,097 | +215 |
| Public methods on `A` | 38 | 45 | +7 |
| File-local helpers | 12 | 12 | - |
| Event frames | 1 | 1 | - |
| Registered events | 14 | 14 | - |
| Named frame globals | 3 | 4 | +1 |
| Popup keys | 2 | 2 | - |
| Business transactions | 9 | 10 | +1 |
| SavedVariables tables | 2 | 2 | - |
| Settings keys (excluding templates) | 11 | 12 | +1 |
| Offline harnesses | 1 | 4 | +3 |
| Offline harness lines | 72 | 207 | +135 |
| Test lines as % of shipped source | 8% | 19% | +11pp |

### Detail

- **Public methods by module**: Core 17, UI 11, Roster 7, Alerts 5, Tabard 2, Broker 2,
  Options 1. The seven additions are `StageApproval`, `ApproveMessage`,
  `DismissMessage`, `ClearApprovals` in `Core.lua` and `BuildApprovalsUI`,
  `UpdateApprovalsUI`, `ShowApprovals` in `UI.lua`. Plus the `A.GetActivityType` closure
  assigned in `BuildRequestUI`.
- **File-local helpers** (12, unchanged): `fillDefaults`, `guildName`, `cleanChat`,
  `looksLikeCraftRequest`, `looksLikeGroupRequest`, `inMajorCity`,
  `guildTabardEquipped`, `Label`, `Button`, `Check`, `MakeLabel`, `MakeButton`.
- **Named frame globals** (4): `ForeverGuildCommsOptionsPanel`, `FGCAlertsFrame`,
  `FGCRequestFrame`, and the new `FGCApprovalsFrame`.
- **Popup keys** (2): `FGC_TABARD_CITY`, `FGC_TABARD_EXIT`.
- **Global namespace entries**: 1 (`_G.ForeverGuildComms`) plus the two `SLASH_*`
  variables and the `SlashCmdList` entry.
- **Business transactions**: 10, of which 4 can produce public chat (login greeting, new
  member welcome, level congratulation, manual help request), 1 resolves a staged
  message to public only on an explicit click, and 5 are entirely private.
- **Slash subcommands**: 8 behaviors across 11 accepted inputs, after `verify` and
  `review` were added.
