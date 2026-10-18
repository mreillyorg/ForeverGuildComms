# Component Inventory

This project is a **single package**. It is not a multi-package workspace, so the
conventional package categories below are mapped onto the addon's seven source modules,
which are the real units of organization.

## Application Packages

| Component | Type | Purpose |
| --- | --- | --- |
| `ForeverGuildComms` | WoW addon (single package) | The entire deliverable. One TOC, seven Lua modules, flat layout, loaded in declared order by the client. |

### Modules within the package

| Module | Role | Purpose |
| --- | --- | --- |
| `Core.lua` | Foundation | Shared namespace, defaults, SavedVariables init, identity and formatting helpers, the guild send queue, slash commands, the single event dispatcher |
| `Roster.lua` | Feature | Roster read, baseline, and diff; login greetings, level-up congratulations, guild-join parsing |
| `Alerts.lua` | Feature | Guild chat parsing, craft and group detection, recipe cache scan, private alert list |
| `Tabard.lua` | Feature | Capital city detection, tabard slot check, two reminder popups |
| `UI.lua` | Presentation | Alerts inbox window, Ask-for-Help compose window, live preview, explicit send |
| `Options.lua` | Presentation | Settings canvas panel registration, toggles, template editors |
| `Broker.lua` | Optional integration | LibDataBroker data object when a broker library is present |

## Infrastructure Packages

None. There is no CDK, Terraform, CloudFormation, container, or deployment script in this
project. Deployment is a file copy into the client's `AddOns` directory.

## Shared Packages

None as separate packages. The shared-code role is played by `Core.lua`, which every
other module depends on through the single shared table `A`. No library is embedded, by
deliberate policy: the Titan/LibDataBroker integration uses Titan's own copy through
`LibStub("LibDataBroker-1.1", true)`.

## Test Packages

| Component | Type | Purpose |
| --- | --- | --- |
| `tests/smoke.lua` | Unit / logic harness | Offline Lua 5.1 harness. Stubs the client globals it needs, loads `Core.lua`, `Roster.lua`, and `Alerts.lua` via `loadfile`, and asserts the guild-chat safety invariants against a fake queue. Deliberately excluded from the TOC and from the shipped zip. |

No integration, load, contract, or end-to-end test package exists. Anything touching
frames, the Settings API, popups, or LibStub is verified by a manual in-game checklist
rather than automated tests.

## Supporting Files

| File | Purpose |
| --- | --- |
| `ForeverGuildComms.toc` | The only manifest: interface version, metadata, SavedVariables declarations, optional dependency, load order |
| `README.md` | Install steps, features, commands, templates, limitations, suggested test sequence, debugging notes. Treated as part of the deliverable, not an afterthought |
| `LICENSE` | License text |
| `.gitignore` | Blocks compiled Lua, archives, object files, libraries, shared objects, and executables |

## Development-Time Configuration

| Path | Purpose |
| --- | --- |
| `.kiro/steering/*.md` | Eight project steering documents encoding product non-goals, Lua style, guild chat safety invariants, Forever client API constraints, UI frame conventions, packaging rules, project structure, and the testing process |
| `.kiro/aws-aidlc-rule-details/` | AI-DLC v1 workflow rule details, installed by the aidlc power |
| `aidlc-docs/` | AI-DLC artifacts, including this inventory |

These are excluded from the shipped zip.

## Total Count

- **Total Packages**: 1
- **Application**: 1 (seven modules within it)
- **Infrastructure**: 0
- **Shared**: 0 (the shared-code role is internal, in `Core.lua`)
- **Test**: 1 harness file, not packaged

### Shipped source

- **Lua modules**: 7
- **Lua lines**: 882
- **Public methods on `A`**: 38 (`function A:` definitions; Core 13, Roster 7, Alerts 5,
  UI 8, Tabard 2, Broker 2, Options 1), plus the `A.GetActivityType` closure assigned in
  `BuildRequestUI`
- **File-local helpers**: 12 (`fillDefaults`, `guildName`, `cleanChat`,
  `looksLikeCraftRequest`, `looksLikeGroupRequest`, `inMajorCity`,
  `guildTabardEquipped`, the widget factories `Label`/`Button`/`Check` in `UI.lua`, and
  `MakeLabel`/`MakeButton` in `Options.lua`)
- **Event frames**: 1
- **Registered events**: 14
- **Named frame globals**: 3 (`ForeverGuildCommsOptionsPanel`, `FGCAlertsFrame`,
  `FGCRequestFrame`)
- **Popup keys**: 2 (`FGC_TABARD_CITY`, `FGC_TABARD_EXIT`)
- **Global namespace entries**: 1 (`_G.ForeverGuildComms`) plus the two `SLASH_*`
  variables and the `SlashCmdList` entry
- **Business transactions implemented**: 9 (4 produce public chat, 5 are private)
- **SavedVariables tables**: 2 (`ForeverGuildCommsDB` account-wide,
  `ForeverGuildCommsCharDB` per character)
