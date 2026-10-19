# Technology Stack

**Analysis target**: Forever Guild Comms **0.4.3-beta**
**Supersedes**: the 0.4.1-beta pass of 2026-10-19T02:40:00Z

The runtime stack is unchanged: still plain Lua 5.1 against the Blizzard addon API, with no
runtime dependency added. 0.4.2 and 0.4.3 introduced no new tooling and consumed no new
Blizzard API surface. The only additions are source growth (one new data module), two more
offline harnesses, and one new standard-library usage.

**A note on `math.random`.** `A:ChooseMessageTemplate` is the first code in the project to
depend on randomness. It never calls `math.randomseed`, so the sequence depends on whatever
state the client's Lua provides. For message-wording variety this is immaterial — the
shuffle bag's exhaust-before-repeat property holds regardless of distribution quality — but
it is recorded here so a future reader does not assume seeding happens elsewhere.

## Programming Languages

| Language | Version | Usage |
| --- | --- | --- |
| Lua | 5.1 | The addon: 2,022 lines across 12 modules, up from 882 across 7 at 0.1.0. Plain Lua 5.1 as embedded by the WoW client; no transpiler, no build step, no external libraries. The eleven offline harnesses target the same version |
| XML | - | `Bindings.xml`, 12 lines. Blizzard's declarative key-binding format. The only non-Lua shipped code |
| PowerShell | 5.1+ | `install/Install-ForeverGuildComms.ps1`, 313 lines. Development and distribution only, never loaded by the client |
| Batch | - | `install/Install-ForeverGuildComms.cmd`, 31 lines. Double-click launcher for the installer |
| YAML | - | `.github/workflows/package.yml` and `.pkgmeta`. Release automation only |

Language features still deliberately avoided in the addon, because the client's 5.1
runtime lacks them: `goto`, integer division, the 5.3+ integer/float split, relocated
`table.unpack`, and all LuaJIT extensions (`ffi`, `bit`, `jit`, `table.new`).

### A note on text encoding

0.4.0 introduced non-ASCII source content for the first time: the translated templates in
`Languages.lua` and several accent phrases in `Accents.lua` contain accented Latin
characters. Two consequences the code handles explicitly:

- Source files must be UTF-8. `.gitattributes` pins LF endings, which keeps the byte
  content stable across platforms.
- `A:ChatLimit` replaced the previous raw `sub(1, 250)` so the 250-byte chat payload limit
  is applied without splitting a multibyte character. `tests/voice.lua` carries a
  dedicated regression assertion for this.

## Runtime Platform

| Component | Version | Notes |
| --- | --- | --- |
| World of Warcraft: Forever | 1.60.1 | Target client. Beta opened 2026-09-17 |
| TOC interface number | `16001` | Unchanged across all four releases |
| Client install path (this machine) | `World of Warcraft\_classic_beta_\Interface\AddOns\` | Beta AddOns directory |
| Embedded Lua interpreter | 5.1 | The only production runtime |

### The decisive platform fact

Forever is **not** the Classic Era client. It runs on the modern (Mainline) UI
architecture and exposes most of the 12.1.5-era API, while the *content* is Vanilla 1-60.
The codebase continues to honour this correctly, and this span added three more examples:

- `MenuUtil.CreateContextMenu` for the nested menu — a modern API, feature-detected with a
  Settings-page fallback, and notably *not* Titan's own menu library.
- `UIRadioButtonTemplate` for the mode and voice selectors.
- `UnitRace` for accent filtering, with a defensive probe for Forever's **Skyborne** race
  whose locale-independent token the client may not publish. The code checks both the
  token and the localized name for a `skyborne` substring. `A.raceAccents` also maps both
  `Scourge` and `Undead` to the Forsaken style, hedging on which token the client returns.

Vanilla content assumptions remain correct and intentional: Guild Tabard item `5976`, the
eight capital cities, the nine-class `A.classRoles` table. The thirteen WoW-race accent
styles include races beyond the Vanilla playable set (Blood Elf, Draenei, Goblin,
Skyborne), which is forward-looking rather than inconsistent — they are simply
unreachable through the race filter on a character whose race the client does not report.

The Midnight addon disarmament rules including secret values are active in Forever. The
product avoids the problem entirely by treating combat data as a non-goal; the only
numeric comparison is roster level, still type-checked before use.

## Frameworks

| Framework | Version | Purpose |
| --- | --- | --- |
| Blizzard WoW AddOn API | 1.60.1 / Interface 16001 | The only framework. Events, frames, timers, chat, settings, menus, key bindings, persistence |
| Blizzard UI frame templates | client-provided | `BasicFrameTemplateWithInset` for all three windows, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `UIRadioButtonTemplate`, `InputBoxTemplate`, `UIPanelScrollFrameTemplate`. No custom XML frames and no reskinning of Blizzard's own frames |
| Blizzard `MenuUtil` | client-provided | **New.** Nested context menu, feature-detected |
| Blizzard key-binding system | client-provided | **New.** `Bindings.xml` plus `BINDING_HEADER_*` / `BINDING_NAME_*` globals |
| Modern Settings API | client-provided | `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory`, with a printed fallback if absent |

No application framework, no UI library, no state-management library, no i18n library —
the translation layer is hand-curated data tables.

## Libraries

| Library | Version | Dependency type | Purpose |
| --- | --- | --- | --- |
| LibDataBroker-1.1 | unpinned, supplied by Titan Panel | **Optional**, runtime-detected | The status indicator in `Broker.lua`, via `LibStub("LibDataBroker-1.1", true)`. Still a soft dependency; the addon runs fully without it |

Nothing embedded or vendored. "No hard library dependencies" remains intact and was
actively upheld this span: the nested menu could have pulled in Titan's menu library and
instead uses Blizzard's `MenuUtil`.

## Infrastructure

| Service | Purpose |
| --- | --- |
| None at runtime | No cloud footprint, no server, no container, no network call from the addon |
| GitHub Actions | **New.** Release packaging only, triggered by a `v*` tag |

### Persistence

| Store | Scope | Contents |
| --- | --- | --- |
| `ForeverGuildCommsDB` | Account-wide SavedVariables | 12 settings and 4 templates (`A.db`) |
| `ForeverGuildCommsCharDB` | Per-character SavedVariables | `voice` **(new)**, `recipes`, `myRoles`, `needRoles` (`A.char`) |

Written by the client on logout or reload. The addon never serializes anything itself.
`fillDefaults` backfills new keys, which is how both `outgoingMode` (0.2.0) and the
`voice` table (0.4.0) reached existing profiles without disturbing prior choices.

Beyond backfill, `A:Initialize` now performs four validation passes on load: mode
coercion, blank-template refill, **timing clamping through `NormalizeTiming`**, and
**voice validation** (unknown language to `en`, unknown strength to `subtle`, non-boolean
race filter to `true`, unavailable accent to `auto`). A hand-edited or corrupted saved
file is therefore corrected rather than trusted.

Deliberately **not** persisted: `A.pendingApprovals`. Staged messages do not survive a
reload, which is correct for time-sensitive social greetings.

## Build Tools

| Tool | Version | Purpose |
| --- | --- | --- |
| None for compilation | - | No build system, bundler, minifier, or code generator. The `.lua` files and `Bindings.xml` are the shipped artifact |
| BigWigsMods/packager | `@v2` | **New.** Builds and publishes the release ZIP from a tag |

### Packaging

Two distribution paths now exist.

**Automated (addon managers).** `.github/workflows/package.yml` runs on a `v*` tag with
`contents: write`, checks out full history for the changelog, and invokes
BigWigsMods/packager. Publishing to GitHub Releases needs no repository secrets — it uses
the built-in `GITHUB_TOKEN`. CurseForge, WoWInterface, and Wago tokens are read from
optional secrets and are inert if unset. `.pkgmeta` sets `package-as: ForeverGuildComms`
and excludes `install`, `tests`, `PACKAGING.md`, `.github`, and `Media/ProjectIcon.png`,
while retaining `Media/Icon.tga` and `Bindings.xml`.

**Manual (integrated Windows installer).** `install/Install-ForeverGuildComms.ps1` reads
the TOC as its manifest, validates every entry against
`^[A-Za-z0-9_-]+\.(lua|xml)$` and throws on anything with a path, traversal, or an
unexpected extension. It then appends two files the TOC cannot list: `Media/Icon.tga` and
`Bindings.xml`, failing if either is missing. It skips byte-identical files, backs up
files it is about to overwrite into `Interface\AddOnBackups`, never replaces the whole
addon directory, and never touches SavedVariables.

The inner folder must remain exactly `ForeverGuildComms`. Version strings are coupled
across three files — TOC `## Version`, `A.version`, and the `README.md` title — and all
three currently read `0.4.1-beta`.

## Testing Tools

| Tool | Version | Purpose |
| --- | --- | --- |
| Standalone Lua interpreter | 5.1.5 recommended | Runs the nine harnesses. Each must be invoked from the addon root, e.g. `lua5.1.exe tests\voice.lua`, because every harness resolves its base path with a `./` fallback |
| `assert` from the standard library | 5.1 | The entire assertion mechanism. No framework, runner, fixtures, or reporter; each harness dies on the first failure and prints a `PASSED` summary |
| Hand-rolled stub layers | - | Each harness stubs only the globals its own path touches |
| Synthetic widget layer | - | `tests/settings.lua` and `tests/titanmenu.lua` use a metatable whose `__index` returns real implementations for the methods under test and a no-op otherwise, with `CreateFrame` recording every widget for later lookup by template or label |
| Synthetic menu-node layer | - | **New.** `tests/titanmenu.lua` additionally fakes the `MenuUtil` node API (`CreateTitle`, `CreateButton`, `CreateCheckbox`, `CreateRadio`, `CreateDivider`), recording children so the generated tree can be walked and its callbacks invoked |
| Captured timer queue | - | `tests/verify.lua` and `tests/timing.lua` replace `C_Timer.After` with a recorder. `timing.lua` keeps the `delay` argument and asserts its exact value, which is how the spacing arithmetic is verified |
| Text-level file assertions | - | **New.** `tests/icon.lua` and `tests/keybindings.lua` read project files as text. `keybindings.lua` goes further and `load()`s the Lua embedded in `Bindings.xml`, so the real binding handlers execute |
| Manual in-game checklist | - | Ten steps in `README.md`. Still the only verification path for `Tabard.lua` |

### Offline harnesses

| Harness | Loads | Covers |
| --- | --- | --- |
| `tests/syntax.lua` | all modules, runs none | Every shipped file compiles |
| `tests/smoke.lua` | Core, Roster, Alerts | Roster diffing, guild-join parsing, chat parsing, recipe cache |
| `tests/verify.lua` | Core | Approval workflow, dedup, mode switching, guild-change safety |
| `tests/settings.lua` | Core, Options | SavedVariables migration, template refill, radio modes, Use default buttons |
| `tests/timing.lua` | Core + 3 voice modules | Exact queue delays, per-member login cooldown, zero cooldown |
| `tests/titanmenu.lua` | Core, Options, TitanMenu, Broker | LDB object and the whole nested menu tree |
| `tests/voice.lua` | Core + 3 voice modules | Languages, race filtering, custom-template precedence, UTF-8 truncation, invalid-value rejection |
| `tests/keybindings.lua` | Core, Alerts | The real `Bindings.xml` handlers, opt-in guarantee, no-send guarantee |
| `tests/icon.lua` | none; reads files | Icon wiring across four files plus texture size sanity |
| `tests/tabard_dedup.lua` | Core, Tabard | **New.** The login-check ordering race, per-stay prompt dedup, city exit and re-entry, and the dedup-cache lifecycle including malformed and future timestamps and the idle ticker |
| `tests/variations.lua` | Core + 4 data/voice modules + UI | **New.** Shuffle bags across all 8 languages and all 29 accents, variant completeness, custom-template override, non-consuming preview, preview/send stability |

Interpreter notes recorded by the project: LuaJIT 2.1 works but is a superset, so test
code must not depend on its extensions. Lua 5.4 is explicitly unsuitable. On Windows no
package manager carries 5.1.5, so the LuaBinaries `lua-5.1.5_Win64_bin.zip` build is
used, keeping `lua5.1.dll` and the bundled `Microsoft.VC80.CRT\` folder beside the
executable.

## CI/CD

| Stage | Tooling |
| --- | --- |
| Build | N/A — nothing to compile |
| Test | **None in CI.** The nine harnesses are run by hand |
| Package | GitHub Actions on a `v*` tag, via BigWigsMods/packager |
| Publish | GitHub Releases with the built-in token; CurseForge, WoWInterface, and Wago optional |

The gap worth naming: packaging is automated but **testing is not**. A tag can cut a
release without any harness having been run. Adding a test job to the same workflow, or a
single local runner script, is the obvious next step.

## Version Control

| Tool | State |
| --- | --- |
| Git | `main` tracking `origin/main` at `git@github.com:mreillyorg/ForeverGuildComms.git`. Nine commits. The eight published commit messages were rewritten and force-pushed on 2026-10-19 for descriptiveness; `.gitattributes` pins LF to stop the CRLF churn git had been warning about. No tags yet, so the `v*` packaging workflow has never fired |

## Development Environment

| Tool | Purpose |
| --- | --- |
| Kiro IDE | Agentic development environment. Eight project steering files encode non-goals, Lua style, safety invariants, client constraints, UI conventions, packaging, structure, and testing |
| AI-DLC v1 (aidlc-amit-verma power) | Workflow rules at `.kiro/steering/core-workflow.md` with details under `.kiro/aws-aidlc-rule-details/`. Artifacts in `aidlc-docs/` |

## Attribution

Client and API facts derive from the project's own
`.kiro/steering/forever-client-api.md`, which cites the
[Patch 1.60.1 API changes notes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes),
[Blizzard's announcement on Midnight addon changes](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons),
and the [Forever addon overview](https://teamoverpowered.com/forever/guides/addons/).
Content was rephrased for compliance with licensing restrictions.
