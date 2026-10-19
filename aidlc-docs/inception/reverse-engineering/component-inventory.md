# Component Inventory

**Analysis target**: Forever Guild Comms **0.4.1-beta**
**Supersedes**: the 0.2.0-beta pass of 2026-10-19T00:52:00Z

Still a **single package**. The conventional package categories are mapped onto the
addon's eleven source modules, which are the real units of organization.

## Application Packages

| Component | Type | Purpose |
| --- | --- | --- |
| `ForeverGuildComms` | WoW addon (single package) | The entire deliverable. One TOC, eleven Lua modules plus an auto-loaded `Bindings.xml`, flat layout. |

### Modules within the package

| Module | Role | Purpose | Since 0.2.0 |
| --- | --- | --- | --- |
| `Core.lua` | Foundation | Namespace, defaults, migrations, identity, UTF-8 clamping, the `CommsText` seam, send queue, approval backlog, validating setters, quick-action dispatcher, binding labels, slash commands, the single event frame | **+170** |
| `Languages.lua` | Data | 8 languages, translated templates, localized role and activity labels. Zero methods | **new** |
| `Accents.lua` | Data | 29 curated styles plus a stable order. Zero methods | **new** |
| `RaceProfiles.lua` | Feature | Race mapping, accent availability and resolution, `VoiceText`, localized labels | **new** |
| `Roster.lua` | Feature | Roster read, baseline, diff, guild-join parsing. Now emits via `CommsText` | +0 |
| `Alerts.lua` | Feature | Chat parsing, craft and group detection, recipe cache. `ScanRecipes` returns a boolean | +1 |
| `Tabard.lua` | Feature | City detection, tabard check, two popups | +0 |
| `UI.lua` | Presentation | Alerts inbox, review window, Ask-for-Help composer with localized labels | +1 |
| `Options.lua` | Presentation | Settings canvas: toggles, mode, timing fields, template editors, languages and accents, scroll anchors | **+103** |
| `TitanMenu.lua` | Presentation | Nested right-click menu via Blizzard `MenuUtil`, with a Settings fallback | **new** |
| `Broker.lua` | Optional integration | LibDataBroker object, counts, click routing | +0 |

### Declarative input

| File | Role | Purpose |
| --- | --- | --- |
| `Bindings.xml` | Declarative input | **New.** Three opt-in hotkeys in the `ADDONS` category. Shipped, auto-loaded from the addon root, and deliberately **absent from the TOC** |

## Infrastructure Packages

Still no CDK, Terraform, CloudFormation, or container. Two deployment mechanisms now
exist, neither of which is cloud infrastructure:

| Component | Type | Lines | Purpose |
| --- | --- | --- | --- |
| `install/Install-ForeverGuildComms.ps1` | Installer | 313 | **New.** Parses the TOC, validates each entry against `^[A-Za-z0-9_-]+\.(lua\|xml)$`, appends `Media/Icon.tga` and `Bindings.xml` explicitly, skips byte-identical files, backs up overwritten files to `Interface\AddOnBackups`, never touches SavedVariables |
| `install/Install-ForeverGuildComms.cmd` | Launcher | 31 | **New.** Double-click entry point |
| `install/INSTALL-README.txt` | Docs | 66 | **New.** End-user instructions |
| `.github/workflows/package.yml` | CI | 30 | **New.** On a `v*` tag, builds and publishes a ZIP through BigWigsMods/packager using the built-in `GITHUB_TOKEN`; CurseForge, WoWInterface, and Wago tokens are optional secrets |
| `.pkgmeta` | Packager config | 13 | **New.** `package-as: ForeverGuildComms`; excludes `install`, `tests`, `PACKAGING.md`, `.github`, `Media/ProjectIcon.png` |

## Shared Packages

None as separate packages. `Core.lua` plays the shared-code role for all ten other
modules. `Languages.lua` and `Accents.lua` are shared *data* consumed only by
`RaceProfiles.lua`.

No library is embedded. Notably `TitanMenu.lua` added a nested menu **without** adding a
Titan or menu-library dependency, by using Blizzard's own `MenuUtil` behind a feature
check.

## Test Packages

Nine offline harnesses, up from four. All excluded from the TOC and from the release
archive.

| Component | Lines | Loads | Purpose | Since 0.2.0 |
| --- | --- | --- | --- | --- |
| `tests/syntax.lua` | 6 | all shipped modules, runs none | Every file compiles | +0 |
| `tests/smoke.lua` | 75 | Core, Roster, Alerts | Roster diffing (self level-up excluded), guild-join including the self case, craft and group detection including the self case, learned-vs-unlearned caching | +3 |
| `tests/verify.lua` | 69 | Core | The approval workflow against the real queue and backlog, including the mode-switch and guild-change invariants | +3 |
| `tests/settings.lua` | 87 | Core, Options | SavedVariables migration, default template refill, radio modes, Use default buttons, via a synthetic widget layer | +24 |
| `tests/timing.lua` | 55 | Core, Languages, Accents, RaceProfiles | **New.** Asserts the *exact* computed queue delay for successive sends, per-member login cooldown, and `loginCooldown = 0` | **new** |
| `tests/titanmenu.lua` | 168 | Core, Options, TitanMenu, Broker | **New.** Fakes both the frame API and the menu node API, then walks the generated menu tree and invokes its callbacks. The largest harness | **new** |
| `tests/voice.lua` | 46 | Core, Languages, Accents, RaceProfiles | **New.** Languages, race filtering, custom-template precedence with a real item link, UTF-8 truncation, invalid-value rejection, unknown-race fallback | **new** |
| `tests/keybindings.lua` | 62 | Core, Alerts | **New.** Reads `Bindings.xml`, `load()`s each embedded handler, asserts opt-in and uniqueness, drives all three actions, and requires zero sends | **new** |
| `tests/icon.lua` | 21 | nothing; reads files as text | **New.** Icon wiring across the TOC, `Broker.lua`, `Options.lua`, and the installer, plus a size sanity check on both textures | **new** |

**Coverage by module**: `Core.lua`, `Roster.lua`, `Alerts.lua`, `Options.lua`,
`TitanMenu.lua`, `Broker.lua`, `Languages.lua`, `Accents.lua`, `RaceProfiles.lua`, and
`Bindings.xml` all have at least one harness exercising them. **`Tabard.lua` and `UI.lua`
remain the only modules with no automated coverage**, and `Tabard.lua` is the only one with
none at all (`UI.lua`'s `ShowAlerts`/`ShowRequest` are stubbed in `keybindings.lua` rather
than exercised).

## Supporting Files

| File | Purpose | Lines | Since 0.2.0 |
| --- | --- | --- | --- |
| `ForeverGuildComms.toc` | Manifest; now 11 files, with `## IconTexture` | 15 | 4 edits |
| `README.md` | Install, keybindings, features, commands, modes, templates, limitations, 10-step test sequence | 158 | **+80** |
| `PACKAGING.md` | Release packaging process | 113 | **new** |
| `LICENSE` | Licence text | 21 | +0 |
| `.gitattributes` | LF line-ending policy | 21 | **new** |
| `.gitignore` | Packager output, local ZIPs, editor temp files | 9 | rewritten |
| `Media/Icon.tga` | In-game addon list icon | 64 KB | **new** |
| `Media/ProjectIcon.png` | Distribution listing icon | 481 KB | **new** |

## Development-Time Configuration

| Path | Purpose |
| --- | --- |
| `.kiro/steering/*.md` | Eight project rules. **`testing.md` is now badly out of date** — see `code-quality-assessment.md` |
| `.kiro/aws-aidlc-rule-details/` | AI-DLC v1 rule set |
| `aidlc-docs/` | AI-DLC artifacts, including this inventory |

## Total Count

- **Total Packages**: 1
- **Application**: 1 (eleven modules plus one XML input file)
- **Infrastructure**: 0 cloud; 1 installer and 1 CI workflow
- **Shared**: 0 as packages; 2 shared data modules internally
- **Test**: 9 harness files, none packaged

### Shipped source

| Metric | 0.1.0 | 0.2.0 | 0.4.1 | Change since 0.2.0 |
| --- | --- | --- | --- | --- |
| Lua modules | 7 | 7 | 11 | +4 |
| Lua lines | 882 | 1,097 | 1,733 | +636 |
| Public methods on `A` | 38 | 45 | 62 | +17 |
| File-local helpers | 12 | 12 | 16 | +4 |
| Event frames | 1 | 1 | 1 | - |
| Registered events | 14 | 14 | 14 | - |
| Named frame globals | 3 | 4 | 4 | - |
| Other globals | 4 | 4 | 8 | +4 (`BINDING_*`) |
| Popup keys | 2 | 2 | 2 | - |
| Business transactions | 9 | 10 | 13 | +3 |
| SavedVariables tables | 2 | 2 | 2 | - |
| Account settings keys (excl. templates) | 11 | 12 | 12 | - |
| Per-character setting groups | 3 | 3 | 4 | +1 (`voice`) |
| Languages | 0 | 0 | 8 | +8 |
| Accent styles | 0 | 0 | 29 | +29 |
| Offline harnesses / lines | 1 / 72 | 4 / 207 | 9 / 589 | +5 / +382 |
| Test lines as % of shipped Lua | 8% | 19% | 34% | +15pp |
| CI pipelines | 0 | 0 | 1 | +1 |

### Detail

- **Public methods by module**: Core 26, UI 11, Roster 7, RaceProfiles 6, Alerts 5,
  Broker 2, Tabard 2, TitanMenu 2, Options 1, Languages 0, Accents 0. Plus the
  `A.GetActivityType` closure assigned in `BuildRequestUI`.
- **The 17 new methods**: `ChatLimit`, `CommsText`, `NormalizeTiming`, `RefreshOptions`,
  `SetOption`, `VoiceOptionLabel`, `SetVoiceOption`, `VoiceChoices`, `RunQuickAction` in
  `Core.lua`; `GetPlayerRace`, `GetAvailableAccents`, `ResolveAccent`, `VoiceText`,
  `LocalizeRoleText`, `LocalizeActivityType` in `RaceProfiles.lua`;
  `PopulateTitanMenu`, `OpenTitanMenu` in `TitanMenu.lua`. One method was removed in
  effect: the dead `A.lastMessages` table went away in 0.3.0.
- **File-local helpers** (16): `fillDefaults`, `guildName`, `cleanChat`,
  `looksLikeCraftRequest`, `looksLikeGroupRequest`, `inMajorCity`,
  `guildTabardEquipped`, `Label`, `Button`, `Check`, `MakeLabel`, `MakeButton`, plus the
  four new ones: `register` (Accents), `SecondsText`, `AddSetting`, `AddTiming`
  (TitanMenu).
- **Named frame globals** (4): `ForeverGuildCommsOptionsPanel`, `FGCAlertsFrame`,
  `FGCRequestFrame`, `FGCApprovalsFrame`.
- **Other globals** (8): `_G.ForeverGuildComms`, two `SLASH_*`, the `SlashCmdList` entry,
  and four `BINDING_*` labels required by the client's Key Bindings UI.
- **Business transactions**: 13. Four can produce public chat, one resolves a staged
  message to public only on an explicit click, and eight are entirely private.
- **Input surfaces**: four — slash commands (8 behaviours across 11 inputs), the Settings
  panel, the Titan nested menu, and three opt-in key bindings.
