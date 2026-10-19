# Code Structure

**Analysis target**: Forever Guild Comms **0.4.1-beta**
**Supersedes**: the 0.2.0-beta pass of 2026-10-19T00:52:00Z

## Build System

- **Type**: still none for the addon itself. No transpiler, no bundler, no dependency
  manager. The `.lua` files and `Bindings.xml` are the shipped artifact and the client's
  embedded Lua 5.1 interpreter is the only runtime.
- **Added since 0.2.0**: a release pipeline that packages but does not compile.
  `.github/workflows/package.yml` (30 lines) invokes BigWigsMods/packager on a `v*` tag;
  `.pkgmeta` (13 lines) controls what the release archive contains.

```
## Interface: 16001
## Title: Forever Guild Comms
## Notes: Welcomes, guild greetings, translated and RP-accented messages, levels, crafting and LFG alerts, tabard reminders, and group requests.
## Author: Michael Reilly
## IconTexture: Interface\AddOns\ForeverGuildComms\Media\Icon
## Version: 0.4.1-beta
## SavedVariables: ForeverGuildCommsDB
## SavedVariablesPerCharacter: ForeverGuildCommsCharDB
## OptionalDeps: Titan
Core.lua
Languages.lua
Accents.lua
RaceProfiles.lua
Roster.lua
Alerts.lua
Tabard.lua
UI.lua
Options.lua
TitanMenu.lua
Broker.lua
```

Four TOC changes across this span: the version, a new `## IconTexture` line, an expanded
`## Notes`, and four added file entries.

**Load order is now load-order-critical in a second place.** The three voice modules sit
immediately after `Core.lua` and before `Roster.lua`. `Languages.lua` reads
`A.defaults.templates` at load time to populate its English entry, so it must follow
`Core.lua`; `RaceProfiles.lua` reads `A.accents` and `A.accentOrder`, so it must follow
`Accents.lua`; and `Roster.lua` calls `A:CommsText`, which needs `A:VoiceText` to exist by
the time a message is built. The current order satisfies all three.

- **Version coupling check**: all three locations agree at `0.4.1-beta` — TOC line 6,
  `Core.lua` line 9, `README.md` line 1. The three-place rule is upheld.
- **Interface number**: still `16001`.
- **Not in the TOC, by requirement**: `Bindings.xml`. The client auto-loads it from the
  addon root, and listing it would be wrong. Both distribution paths handle it explicitly:
  the installer appends it outside the TOC scan and fails if absent, and `.pkgmeta` does
  not exclude it.

## Module Hierarchy

```mermaid
flowchart TD
    TOC["ForeverGuildComms.toc"]
    Core["Core.lua"]
    Lang["Languages.lua<br/>data"]
    Acc["Accents.lua<br/>data"]
    RP["RaceProfiles.lua<br/>voice logic"]
    Roster["Roster.lua"]
    Alerts["Alerts.lua"]
    Tabard["Tabard.lua"]
    UI["UI.lua"]
    Options["Options.lua"]
    Titan["TitanMenu.lua"]
    Broker["Broker.lua"]
    Bind["Bindings.xml<br/>auto-loaded, not in TOC"]

    TOC --> Core
    Core --> Lang
    Lang --> Acc
    Acc --> RP
    RP --> Roster
    Roster --> Alerts
    Alerts --> Tabard
    Tabard --> UI
    UI --> Options
    Options --> Titan
    Titan --> Broker
    Bind -.->|"RunQuickAction"| Core
```

### Text Alternative

```
Load order (order matters):
   1. Core.lua           <- creates shared table A, must be first
   2. Languages.lua      <- reads A.defaults.templates at load
   3. Accents.lua        <- pure data
   4. RaceProfiles.lua   <- reads A.accents, provides VoiceText
   5. Roster.lua         <- calls A:CommsText
   6. Alerts.lua
   7. Tabard.lua
   8. UI.lua
   9. Options.lua
  10. TitanMenu.lua
  11. Broker.lua

Shipped but not listed:
      Bindings.xml       <- auto-loaded by the client from the addon root

Not shipped (nine offline harnesses):
      tests/syntax.lua smoke.lua verify.lua settings.lua timing.lua
      tests/titanmenu.lua voice.lua keybindings.lua icon.lua
```

## Existing Files Inventory

| Path | Purpose | Lines | Since 0.2.0 |
| --- | --- | --- | --- |
| `ForeverGuildComms.toc` | Manifest: interface, metadata, icon texture, SavedVariables, optional dep, 11-file load order | 15 | +0 lines, 4 edits |
| `Core.lua` | Namespace, defaults, migrations, identity helpers, `ChatLimit`, `CommsText`, send queue, approval backlog, `SetOption`/`SetVoiceOption`, `NormalizeTiming`, `RunQuickAction`, binding labels, slash commands, the single 14-event frame | 476 | **+170** |
| `Languages.lua` | 8 languages, `localeTemplates`, `localeRoleNames`, `localeActivityTypes`. Zero methods | 81 | **new** |
| `Accents.lua` | 29 curated styles via a local `register` helper, plus `accentOrder`. Zero methods | 51 | **new** |
| `RaceProfiles.lua` | `raceAccents`, `GetPlayerRace`, `GetAvailableAccents`, `ResolveAccent`, `VoiceText`, `LocalizeRoleText`, `LocalizeActivityType` | 102 | **new** |
| `Roster.lua` | Roster read, baseline, diff, guild-join parsing. Now emits through `CommsText` | 123 | +0 |
| `Alerts.lua` | Chat parsing, craft and group detection, recipe cache. `ScanRecipes` now returns a boolean | 99 | +1 |
| `Tabard.lua` | City detection, tabard check, two popups | 64 | +0 |
| `UI.lua` | Alerts inbox with review shortcut, review window, Ask-for-Help composer with localized labels | 286 | +1 |
| `Options.lua` | Settings canvas: toggles, mode radios, timing fields, template editors, languages and accents section, scroll anchors | 286 | **+103** |
| `TitanMenu.lua` | `PopulateTitanMenu`, `OpenTitanMenu` via Blizzard `MenuUtil` | 127 | **new** |
| `Broker.lua` | LibDataBroker object, counts, click routing | 38 | +0 |
| `Bindings.xml` | Three opt-in hotkeys dispatching to `RunQuickAction` | 12 | **new** |
| `tests/syntax.lua` | Compiles all shipped modules | 6 | +0 |
| `tests/smoke.lua` | Roster diff, guild-join, chat parsing, recipe cache | 75 | +3 |
| `tests/verify.lua` | Approval workflow, mode switching, guild-change safety | 69 | +3 |
| `tests/settings.lua` | SavedVariables migration, options widgets | 87 | +24 |
| `tests/timing.lua` | Queue delay arithmetic, login cooldown, zero cooldown | 55 | **new** |
| `tests/titanmenu.lua` | LDB object plus the whole nested menu tree | 168 | **new** |
| `tests/voice.lua` | Languages, accent filtering, custom-template precedence, UTF-8 | 46 | **new** |
| `tests/keybindings.lua` | Executes the real XML handlers; asserts opt-in and no-send | 62 | **new** |
| `tests/icon.lua` | Icon wiring across TOC, Broker, Options, installer, and the two textures | 21 | **new** |
| `README.md` | Install, keybindings, features, commands, modes, templates, limitations, test sequence | 158 | **+80** |
| `PACKAGING.md` | Release packaging process | 113 | **new** |
| `.pkgmeta` | Packager config and release exclusions | 13 | **new** |
| `.github/workflows/package.yml` | Tag-triggered release packaging | 30 | **new** |
| `install/Install-ForeverGuildComms.ps1` | TOC-driven Windows installer with backup | 313 | **new** |
| `install/Install-ForeverGuildComms.cmd` | Double-click launcher | 31 | **new** |
| `install/INSTALL-README.txt` | End-user install instructions | 66 | **new** |
| `.gitattributes` | LF line-ending policy | 21 | **new** |
| `.gitignore` | Packager build output, local ZIPs, editor temp files | 9 | rewritten |
| `LICENSE` | Licence text | 21 | +0 |
| `Media/Icon.tga` | In-game addon list icon | 64 KB | **new** |
| `Media/ProjectIcon.png` | Distribution listing icon | 481 KB | **new** |

**Shipped Lua**: 1,733 lines across 11 modules, up from 1,097 across 7 (+58%).
**Shipped non-Lua**: `Bindings.xml` 12 lines, two textures.
**Offline harnesses**: 589 lines across 9 files, up from 207 across 4 (+184%).
**Supporting scripts and docs**: 551 lines (installer 313, PACKAGING 113, README 158 are
partly overlapping categories; installer plus launcher plus install readme is 410).

Test code is now **34% of shipped Lua** by line count, up from 19% at 0.2.0 and 8% at
0.1.0.

## Key Modules and Their Public Surface

**62 `function A:` definitions**, up from 45. By module: Core 26, UI 11, Roster 7,
RaceProfiles 6, Alerts 5, Broker 2, Tabard 2, TitanMenu 2, Options 1. `Languages.lua` and
`Accents.lua` define none — they are pure data.

**16 `local function` definitions**, up from 12: the four new ones are `register`
(`Accents.lua`) and `SecondsText`, `AddSetting`, `AddTiming` (`TitanMenu.lua`).

```mermaid
classDiagram
    class Core {
        +Print(s)
        +Key(name)
        +IsSelf(name, guid)
        +ChatLimit(text)
        +Format(template, vars)
        +CommsText(kind, vars)
        +CanUse()
        +Now()
        +IsDuplicate(key, cooldown)
        +SendGuild(message)
        +QueueGuild(message, key, cooldown)
        +DrainQueue()
        +StageApproval(entry)
        +ApproveMessage(index)
        +DismissMessage(index)
        +ClearApprovals()
        +RoleText(roles, noneText)
        +NormalizeTiming(key, value, fallback)
        +RefreshOptions()
        +SetOption(key, value)
        +VoiceOptionLabel(key, id)
        +SetVoiceOption(key, value)
        +VoiceChoices(key)
        +RunQuickAction(action)
        +OpenSettings(section)
        +Initialize()
    }
    class RaceProfiles {
        +GetPlayerRace()
        +GetAvailableAccents()
        +ResolveAccent()
        +VoiceText(kind, vars)
        +LocalizeRoleText(roles, fallback)
        +LocalizeActivityType(kind)
    }
    class UI {
        +BuildUI()
        +UpdateAlertsUI()
        +ShowAlerts()
        +BuildApprovalsUI()
        +UpdateApprovalsUI()
        +ShowApprovals()
        +BuildRequestUI()
        +RequestText()
        +UpdateRequestPreview()
        +ShowRequest()
        +SendHelpRequest()
    }
    class TitanMenu {
        +PopulateTitanMenu(root)
        +OpenTitanMenu(owner)
    }
    class Roster {
        +RequestRoster(force)
        +ReadRoster()
        +AcceptRoster(members, count, online, baseline)
        +CaptureBaseline()
        +OnRosterEvent(event)
        +OnSystemGuildJoin(message)
        +SetupRoster()
    }
    class Alerts {
        +AddAlert(kind, sender, text)
        +ScheduleRecipeScan()
        +ScanRecipes()
        +MatchCraft(lower)
        +OnGuildChat(message, sender)
    }

    Core <|-- RaceProfiles
    Core <|-- UI
    Core <|-- TitanMenu
    Core <|-- Roster
    Core <|-- Alerts
```

All modules attach to the same table `A`, so this is a composition view, not inheritance.

## State Declared on the Shared Table

New and changed entries marked.

| State | Initial value | Declared in | Meaning |
| --- | --- | --- | --- |
| `A.version` | `"0.4.1-beta"` | Core | **Changed** |
| `A.voiceDefaults` | `{language="en", accent="none", raceFilter=true, accentStrength="subtle"}` | Core | **New.** Per-character voice defaults |
| `A.timingLimits` | `{messageSpacing={3,120}, loginCooldown={0,3600}}` | Core | **New.** Clamp ranges |
| `A.defaults` | table | Core | 12 keys plus 4 templates |
| `A.languages` / `A.languageByID` | 8 entries | Languages | **New** |
| `A.localeTemplates` | 8 locales x 4 templates | Languages | **New** |
| `A.localeRoleNames` / `A.localeActivityTypes` | 8 locales | Languages | **New** |
| `A.accents` / `A.accentOrder` | 29 styles | Accents | **New** |
| `A.raceAccents` | 13 race keys | RaceProfiles | **New** |
| `A.char.voice` | backfilled in `Initialize` | Core | **New.** Per-character voice selections |
| `A.optionsPanel` | set in `BuildOptions` | Options | **New.** Lets `RefreshOptions` find the panel |
| `A.optionsScroll` | set in `BuildOptions` | Options | **New.** Deep-link scrolling |
| `A.messagesScrollY` / `A.languagesScrollY` | set in `BuildOptions` | Options | **New.** Section anchors |
| `A.pendingApprovals` | `{}` | Core | Approval backlog, capped at 30 |
| `A.pendingMessages` | `{}` | Core | Spacing queue, holds entry records |
| `A.eventsSeen` | `{}` | Core | Cooldown keys, still never pruned |
| `A.alerts` | `{}` | Core | Private alerts, newest first, capped at 30 |
| `A.classRoles` / `roleNames` / `roleOrder` | tables | Core | Role model |
| `A.onlineCount` / `guildCount` / `lastGuildSend` | `0` | Core | Counters |
| `A.db` / `A.char` | set in `Initialize` | Core | SavedVariables handles |
| `A.playerGuid` / `playerName` / `playerKey` / `selfKeys` / `playerClass` | set in `Initialize` | Core | Self-identity |
| `A.initialized` / `A.queueTimer` | booleans | Core | Gates and latches |
| `A.roster` / `rosterReady` / `rosterGuild` / `baselineTimer` / `lastRosterRequest` | - | Roster | Roster state |
| `A.recipeScanPending` | boolean | Alerts | Scan latch |
| `A.wasInCity` / `A.tabardCheckScheduled` | - | Tabard | Tabard state |
| `A.alertFrame` / `alertRows` / `alertPage` / `alertPageText` / `reviewShortcut` | set in `BuildUI` | UI | Alerts window |
| `A.approvalFrame` / `approvalRows` / `approvalPage` / `approvalPageText` / `approvalEmpty` | set in `BuildApprovalsUI` | UI | Review window |
| `A.requestFrame` / `activityEdit` / `roleChecks` / `needChecks` / `requestPreview` / `GetActivityType` | set in `BuildRequestUI` | UI | Composer |
| `A.lastManualRequest` | `nil` | UI | 20s manual send limit |
| `A.settingsCategory` | set in `BuildOptions` | Options | Category handle |
| `A.broker` | `nil` | Broker | LDB object |
| ~~`A.lastMessages`~~ | - | - | **Removed in 0.3.0.** Was dead state flagged in both prior passes |

### Global namespace

`_G.ForeverGuildComms`, `SLASH_FOREVERGUILDCOMMS1`, `SLASH_FOREVERGUILDCOMMS2`,
`SlashCmdList.FOREVERGUILDCOMMS`, four named frames
(`ForeverGuildCommsOptionsPanel`, `FGCAlertsFrame`, `FGCRequestFrame`,
`FGCApprovalsFrame`), two popup keys, and **four new `BINDING_*` globals**
(`BINDING_HEADER_FOREVERGUILDCOMMS` plus three `BINDING_NAME_*`). The binding globals are
required by the client's Key Bindings UI and have no alternative.

## Design Patterns

### Carried forward and intact
Shared-namespace modules; single event dispatcher; guarded cross-file dispatch; debounce
via timer plus boolean latch; queue with cooldown keys; defaults backfill; widget factory
closures; row pooling with paging; two-phase identity normalization; pattern escaping for
localized globals; late-bound delivery decision; identity-bound message records;
asymmetric mode transitions; fail-safe setting normalization.

### Single validating setter *(new in 0.3.0)*
- **Location**: `A:SetOption`, and `A:SetVoiceOption` for the per-character scope.
- **Purpose**: two independent configuration UIs cannot drift or bypass validation.
- **Implementation**: dispatch on the key's kind — enum keys check membership, timing keys
  pass through `NormalizeTiming`, boolean keys require a boolean, and anything else is
  refused. A `changed` flag avoids redundant refreshes, and the refresh fans out to
  `RefreshOptions` and `UpdateBroker`. `Options.lua` and `TitanMenu.lua` both write only
  here.

### Pure data modules *(new in 0.4.0)*
- **Location**: `Languages.lua`, `Accents.lua`.
- **Purpose**: separate curated content from the logic that selects it, so adding a
  language or style is a data edit with no code change.
- **Implementation**: both define zero methods. `Accents.lua` uses a file-local `register`
  helper to keep 29 entries declarative and uniform, with `accentOrder` giving stable
  presentation independent of table iteration order.

### Optional layer behind an indirection *(new in 0.4.0)*
- **Location**: `A:CommsText`.
- **Purpose**: make the whole voice feature removable without touching callers.
- **Implementation**: `if self.VoiceText then return self:VoiceText(...) end` then fall
  back to `Format(self.db.templates[kind], vars)`. The comment states the intent: existing
  tests and stripped-down installs still work. `tests/keybindings.lua` exercises exactly
  that path by loading only `Core.lua` and `Alerts.lua`.

### Customized content wins *(new in 0.4.0)*
- **Location**: `A:VoiceText`, mirrored by the `custom` flag in `A:RequestText`.
- **Purpose**: never rewrite text a human authored.
- **Implementation**: compare the stored template against `A.defaults.templates[kind]`; if
  they differ, format verbatim and return. This is why an item link or colour code in a
  custom template survives untouched, and `tests/voice.lua` asserts it with a real
  hyperlink.

### Encoding-aware truncation *(new in 0.4.0)*
- **Location**: `A:ChatLimit`, used by `Format`, `SendGuild`, and the `QueueGuild` entry
  builder.
- **Purpose**: translations introduced multibyte characters that a naive `sub(1, 250)`
  would split, producing mojibake at the limit.
- **Implementation**: walk backwards from byte 251 while the byte is a UTF-8 continuation
  byte (`>= 128 and < 192`), then cut. Asserted by a dedicated regression test.

### Self-healing dependent selections *(new in 0.4.0)*
- **Location**: `A:SetVoiceOption`, and the voice block of `A:Initialize`.
- **Purpose**: a stored accent can become invalid when the language or race filter changes.
- **Implementation**: after a `language` or `raceFilter` write, re-list the available
  accents and revert to `auto` if the current choice is absent. The comment is explicit
  that reverting beats using an incompatible style invisibly.

### Declarative input with a single dispatcher *(new in 0.4.1)*
- **Location**: `Bindings.xml` plus `A:RunQuickAction`.
- **Purpose**: add an input surface without duplicating action logic.
- **Implementation**: each XML body is a one-line guarded call into the dispatcher, which
  gates on `A.initialized` and handles three named actions. `TitanMenu.lua` was refactored
  onto the same dispatcher in the same change, removing the inline duplicate it had.

### Deep-linking into a deferred panel *(new in 0.3.0, extended in 0.4.0)*
- **Location**: `A:OpenSettings(section)`.
- **Purpose**: let a menu shortcut land on the right part of a long scrolling panel.
- **Implementation**: open the category, then `C_Timer.After(0, ...)` to defer the scroll
  until the scroll child exists, using anchors published by `Options.lua`. The comment
  notes the asynchronous display is the reason for the deferral.

### Harness with a synthetic widget layer *(extended)*
- **Location**: `tests/settings.lua` and `tests/titanmenu.lua`.
- **Purpose**: load frame-dependent modules offline.
- **Implementation**: a metatable whose `__index` returns real implementations for the few
  methods under test and a no-op otherwise, with `CreateFrame` recording every widget.
  `tests/titanmenu.lua` extends the idea to the menu API itself, building a fake node type
  with `CreateTitle`, `CreateButton`, `CreateCheckbox`, `CreateRadio`, and `CreateDivider`
  that records children, so the menu tree can be walked and its callbacks invoked.

## Critical Dependencies

### WoW Forever client API (1.60.1, Interface 16001)
- **Usage**: every external call, written against the modern namespaced surface.
- **New call sites in this span**: `MenuUtil.CreateContextMenu` (feature-detected, with a
  Settings fallback), `UnitRace`, `UIRadioButtonTemplate`, and the `BINDING_*` /
  `Bindings.xml` key-binding mechanism.
- **Purpose**: the entire runtime. Every call remains feature-detected because the client
  is in beta.

### LibDataBroker-1.1 via LibStub
- **Usage**: `Broker.lua` only, `LibStub("LibDataBroker-1.1", true)`.
- Still optional, still runtime-detected, still not embedded, still no version assertion.
- **Worth noting**: `TitanMenu.lua` did **not** add a Titan dependency. It uses Blizzard's
  `MenuUtil`, so no Titan menu library is bundled and the no-hard-dependency policy holds.

### BigWigsMods/packager *(new, release-time only)*
- **Version**: `@v2` action pin.
- **Usage**: `.github/workflows/package.yml`, on a `v*` tag.
- **Purpose**: build and attach the release ZIP. Not a runtime dependency.

### Standalone Lua 5.1 interpreter (development only)
- **Usage**: running the nine harnesses from the addon root.
- **Purpose**: offline verification. LuaJIT 2.1 works but is a superset; Lua 5.4 is
  unsuitable.
