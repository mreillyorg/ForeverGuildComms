# Component Inventory

**Analysis target**: Forever Guild Comms **0.4.3-beta**
**Supersedes**: the 0.4.1-beta pass of 2026-10-19T02:40:00Z

Still a **single package**, now twelve source modules plus an auto-loaded `Bindings.xml`.

## Application Packages

| Component | Type | Purpose |
| --- | --- | --- |
| `ForeverGuildComms` | WoW addon (single package) | The entire deliverable. One TOC, twelve Lua modules plus an auto-loaded `Bindings.xml`, flat layout |

### Modules within the package

| Module | Role | Purpose | Since 0.4.1 |
| --- | --- | --- | --- |
| `Core.lua` | Foundation | Namespace, defaults, migrations, identity, UTF-8 clamping, the `CommsText` seam, send queue, approval backlog, validating setters, **bounded dedup-cache pruning**, quick-action dispatcher, binding labels, slash commands, the single event frame | **+29** |
| `Languages.lua` | Data | 8 languages, base translated templates, localized role and activity labels | +0 |
| `Accents.lua` | Data | 29 curated styles plus a stable order | +0 |
| `RaceProfiles.lua` | Feature | Race mapping, accent availability and resolution, `VoiceText`, localized labels | **+7** |
| `MessageVariants.lua` | Data + selection | **New.** 204 additional curated templates (68 locale, 136 accent) and the shuffle-bag selector | **new, 229** |
| `Roster.lua` | Feature | Roster read, baseline, diff, guild-join parsing | +0 |
| `Alerts.lua` | Feature | Chat parsing, craft and group detection, recipe cache | +0 |
| `Tabard.lua` | Feature | City detection, tabard check, two popups. **Login-check ordering fixed and per-stay prompt deduplication added** | **+6** |
| `UI.lua` | Presentation | Alerts inbox, review window, Ask-for-Help composer with **draft caching so the preview and sent text cannot diverge** | **+16** |
| `Options.lua` | Presentation | Settings canvas; adds the **Vary built-in message wording** toggle and a non-consuming preview | **+1** |
| `TitanMenu.lua` | Presentation | Nested right-click menu; adds the same wording toggle | **+1** |
| `Broker.lua` | Optional integration | LibDataBroker object, counts, click routing | +0 |

### Declarative input

| File | Role | Purpose |
| --- | --- | --- |
| `Bindings.xml` | Declarative input | Three opt-in hotkeys in the `ADDONS` category. Shipped, auto-loaded from the addon root, deliberately absent from the TOC |

## Infrastructure Packages

No cloud infrastructure. Two deployment mechanisms, unchanged in substance this span
(version strings only):

| Component | Type | Lines | Purpose |
| --- | --- | --- | --- |
| `install/Install-ForeverGuildComms.ps1` | Installer | 313 | Parses the TOC as its manifest, validates each entry, appends `Media/Icon.tga` and `Bindings.xml` explicitly, skips identical files, backs up overwrites to `Interface\AddOnBackups`, never touches SavedVariables |
| `install/Install-ForeverGuildComms.cmd` | Launcher | 31 | Double-click entry point |
| `install/INSTALL-README.txt` | Docs | 66 | End-user instructions |
| `.github/workflows/package.yml` | CI | 30 | On a `v*` tag, builds and publishes a ZIP through BigWigsMods/packager. **Runs no tests** |
| `.pkgmeta` | Packager config | 13 | `package-as: ForeverGuildComms`; excludes `install`, `tests`, `PACKAGING.md`, `.github`, `Media/ProjectIcon.png` |

## Shared Packages

None as separate packages. `Core.lua` plays the shared-code role for all eleven other
modules. `Languages.lua`, `Accents.lua`, and now `MessageVariants.lua` are shared *data*
consumed by `RaceProfiles.lua`.

No library is embedded.

## Test Packages

Eleven offline harnesses, up from nine. All excluded from the TOC and the release archive.

| Component | Lines | Loads | Purpose | Since 0.4.1 |
| --- | --- | --- | --- | --- |
| `tests/syntax.lua` | 6 | all 12 modules, runs none | Every file compiles. Updated to include `MessageVariants.lua` | +0 |
| `tests/smoke.lua` | 75 | Core, Roster, Alerts | Roster diffing, guild-join, chat parsing, recipe cache | +0 |
| `tests/verify.lua` | 69 | Core | Approval workflow, mode switching, guild-change safety | +0 |
| `tests/settings.lua` | 87 | Core, Options | SavedVariables migration and the options widgets | +0 |
| `tests/timing.lua` | 55 | Core + 3 voice modules | Exact queue delays, login cooldown, zero cooldown | +0 |
| `tests/titanmenu.lua` | 168 | Core, Options, TitanMenu, Broker | The LDB object and the whole nested menu tree | +0 |
| `tests/voice.lua` | 46 | Core + 3 voice modules | Languages, race filtering, custom-template precedence, UTF-8 | +0 |
| `tests/keybindings.lua` | 62 | Core, Alerts | The real `Bindings.xml` handlers; opt-in and no-send guarantees | +0 |
| `tests/icon.lua` | 21 | none; reads files | Icon wiring across four files plus texture sanity | +0 |
| `tests/tabard_dedup.lua` | 117 | **Core, Tabard** | **New.** Reproduces the login-check ordering race, per-stay prompt deduplication, city exit and re-entry, and the full dedup-cache pruning lifecycle including malformed and future timestamps and the idle ticker | **new** |
| `tests/variations.lua` | 93 | Core, Languages, Accents, RaceProfiles, MessageVariants, UI | **New.** Shuffle-bag behaviour across every language and every accent, variant completeness, custom-template override, non-consuming Settings preview, and preview/send stability | **new** |

**Coverage by module**: every module now has at least one harness that loads it.
`Tabard.lua` was the last gap and is now covered by `tabard_dedup.lua`. `UI.lua` is loaded
by both `titanmenu.lua` and `variations.lua`, and the latter now drives real logic through
it (`RequestText`, `UpdateRequestPreview`, `ShowRequest`, `SendHelpRequest`) rather than
only stubbing it — though the alerts and review window rendering remains undriven.

## Supporting Files

| File | Purpose | Lines | Since 0.4.1 |
| --- | --- | --- | --- |
| `ForeverGuildComms.toc` | Manifest; now 12 files | 16 | +1 |
| `README.md` | Install, keybindings, features, modes, limitations, in-game checklist, plus a 0.4.3 maintenance-fix section | 169 | **+11** |
| `PACKAGING.md` | Release packaging process | 113 | version refs |
| `LICENSE` | Licence text | 21 | +0 |
| `.gitattributes` | LF line-ending policy | 21 | +0 |
| `.gitignore` | Packager output, local ZIPs, editor temp files | 9 | +0 |
| `Media/Icon.tga` | In-game addon list icon | 64 KB | +0 |
| `Media/ProjectIcon.png` | Distribution listing icon | 481 KB | +0 |

## Development-Time Configuration

| Path | Purpose |
| --- | --- |
| `.kiro/steering/*.md` | Eight project rules. `testing.md` was corrected after the previous pass and is now accurate, but predates the two new harnesses and does not list them |
| `.kiro/aws-aidlc-rule-details/` | AI-DLC v1 rule set |
| `aidlc-docs/` | AI-DLC artifacts, including this inventory |

## Total Count

- **Total Packages**: 1
- **Application**: 1 (twelve modules plus one XML input file)
- **Infrastructure**: 0 cloud; 1 installer and 1 CI workflow
- **Shared**: 0 as packages; 3 shared data modules internally
- **Test**: 11 harness files, none packaged

### Shipped source

| Metric | 0.1.0 | 0.2.0 | 0.4.1 | 0.4.3 | Change |
| --- | --- | --- | --- | --- | --- |
| Lua modules | 7 | 7 | 11 | 12 | +1 |
| Lua lines | 882 | 1,097 | 1,733 | 2,022 | +289 |
| Public methods on `A` | 38 | 45 | 62 | 64 | +2 |
| File-local helpers | 12 | 12 | 16 | 16 | - |
| Event frames | 1 | 1 | 1 | 1 | - |
| Registered events | 14 | 14 | 14 | 14 | - |
| Named frame globals | 3 | 4 | 4 | 4 | - |
| Other globals | 4 | 4 | 8 | 8 | - |
| Popup keys | 2 | 2 | 2 | 2 | - |
| Business transactions | 9 | 10 | 13 | 14 | +1 |
| SavedVariables tables | 2 | 2 | 2 | 2 | - |
| Account settings keys (excl. templates) | 11 | 12 | 12 | 13 | +1 |
| Per-character setting groups | 3 | 3 | 4 | 4 | - |
| Languages / accent styles | 0/0 | 0/0 | 8/29 | 8/29 | - |
| Curated template variants | 0 | 0 | 0 | 204 | +204 |
| Offline harnesses / lines | 1/72 | 4/207 | 9/589 | 11/799 | +2 / +210 |
| Test lines as % of shipped Lua | 8% | 19% | 34% | 40% | +6pp |
| Modules with no harness | 6 | 3 | 1 | **0** | -1 |
| CI pipelines | 0 | 0 | 1 | 1 | - |

### Detail

- **Public methods by module**: Core 27, UI 11, Roster 7, RaceProfiles 6, Alerts 5,
  Broker 2, Tabard 2, TitanMenu 2, Options 1, MessageVariants 1; `Languages.lua` and
  `Accents.lua` define none. Plus the `A.GetActivityType` closure.
- **The two new methods**: `A:PruneEventsSeen` in `Core.lua` and
  `A:ChooseMessageTemplate` in `MessageVariants.lua`.
- **Changed signatures**: `A:CommsText(kind, vars, preview)` and
  `A:VoiceText(kind, vars, preview)` both gained a third parameter.
- **New state**: `A.lastEventPrune`, `A.eventRetentionSeconds`,
  `A.eventPruneIntervalSeconds`, `A.messageVariantBags`, `A.requestDraft`,
  `A.tabardInitialCheckDone`, `A.tabardCityPrompted`.
- **New setting**: `randomizeMessages`, default `true`, exposed in both Settings and the
  Titan menu.
- **Curated variants**: 204 total — 68 across 8 languages, 136 across 29 accents. Every
  language and accent carries entries for all four template kinds, a property
  `tests/variations.lua` asserts rather than assumes.
- **Business transactions**: 14. Four can produce public chat, one resolves a staged
  message to public only on an explicit click, and nine are entirely private.
- **Input surfaces**: four — slash commands, the Settings panel, the Titan nested menu, and
  three opt-in key bindings.
