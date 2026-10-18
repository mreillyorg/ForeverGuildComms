# Technology Stack

## Programming Languages

| Language | Version | Usage |
| --- | --- | --- |
| Lua | 5.1 | The entire addon, 882 lines across seven modules. Plain Lua 5.1 as embedded by the WoW client: no transpiler, no build step, no external libraries. The offline harness targets the same version. |

Language features deliberately avoided, because the client's 5.1 runtime does not have
them: the `goto` statement, integer division, the 5.3+ integer/float distinction, and the
relocated `table.unpack`. LuaJIT extensions (`ffi`, `bit`, `jit`, `table.new`) are also
off-limits even though LuaJIT can run the test harness.

## Runtime Platform

| Component | Version | Notes |
| --- | --- | --- |
| World of Warcraft: Forever | 1.60.1 | Target client. Beta opened 2026-09-17. |
| TOC interface number | `16001` | Declared in `ForeverGuildComms.toc`. Must not be changed to a Classic Era or retail value. |
| Client install path (this machine) | `World of Warcraft\_classic_beta_\Interface\AddOns\` | The beta AddOns directory. |
| Embedded Lua interpreter | 5.1 | Provided by the client; the only production runtime. |

### The decisive platform fact

Forever is **not** the Classic Era client. It runs on the modern (Mainline) UI
architecture and exposes the large majority of the 12.1.5-era API, while the *content*
(items, zones, professions, nine classes) is Vanilla 1-60. Two consequences visible
throughout the code:

1. The addon is written against **modern namespaced APIs** — `C_Timer`, `C_GuildInfo`,
   `C_TradeSkillUI`, `C_Map`, `Settings` — rather than Vanilla-era equivalents like a
   global `GuildRoster()`, `SetMapToCurrentZone`, or XML-driven
   `InterfaceOptions_AddCategory`.
2. Vanilla content assumptions are correct and intentional: Guild Tabard item `5976`, the
   eight capital cities, and the nine-class `A.classRoles` table.

The Midnight addon disarmament rules, including secret values, are active in Forever.
APIs exposing combat-relevant state can return values addon code cannot inspect, and
arithmetic or comparison against a secret errors. The product avoids this class of
problem entirely by treating combat, DPS, threat, and encounter features as non-goals;
the only numeric data it compares is roster level, and that is explicitly type-checked
before every comparison.

## Frameworks

| Framework | Version | Purpose |
| --- | --- | --- |
| Blizzard WoW AddOn API | 1.60.1 / Interface 16001 | The only framework. Events, frames, timers, chat, settings, and persistence all come from the client. |
| Blizzard UI frame templates | client-provided | `BasicFrameTemplateWithInset` for both windows, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`, `UIPanelScrollFrameTemplate`. No custom XML and no reskinning of Blizzard's own frames. |
| Modern Settings API | client-provided | `Settings.RegisterCanvasLayoutCategory` plus `RegisterAddOnCategory` for the options panel, with a printed fallback if absent. |

No application framework, no UI library, no state-management library, no serialization
library.

## Libraries

| Library | Version | Dependency type | Purpose |
| --- | --- | --- | --- |
| LibDataBroker-1.1 | unpinned, supplied by Titan Panel | **Optional**, runtime-detected | The status indicator in `Broker.lua`. Looked up with `LibStub("LibDataBroker-1.1", true)`; the silent-failure flag plus an explicit nil guard means the addon runs fully without it. Declared `## OptionalDeps: Titan`, never `RequiredDeps`. |

Nothing is embedded or vendored. "No hard library dependencies" is a stated product
constraint, not an accident.

## Infrastructure

| Service | Purpose |
| --- | --- |
| None | There is no cloud footprint, no server, no container, no network call. The addon runs in-process in the game client. |

### Persistence

| Store | Scope | Contents |
| --- | --- | --- |
| `ForeverGuildCommsDB` | Account-wide SavedVariables | All settings and the four message templates (`A.db`) |
| `ForeverGuildCommsCharDB` | Per-character SavedVariables | `recipes`, `myRoles`, `needRoles` (`A.char`) |

Both are written by the client on logout or reload. The addon never serializes anything
itself; it relies on `fillDefaults` to backfill new keys on load so existing users keep
their choices.

## Build Tools

| Tool | Version | Purpose |
| --- | --- | --- |
| None | - | No build system, no package manager, no bundler, no minifier, no code generator. The `.lua` files are the shipped artifact. |

### Packaging

Manual. A zip whose contents extract to `AddOns\ForeverGuildComms\`, containing the seven
`.lua` sources, the `.toc`, `README.md`, and `LICENSE`. `.git`, `.kiro`, and `tests` are
excluded. The inner folder must be named exactly `ForeverGuildComms` or the client will
not find the TOC.

Version strings are coupled across three files and must be bumped together: the TOC
`## Version`, `A.version` in `Core.lua`, and the `README.md` title line.

## Testing Tools

| Tool | Version | Purpose |
| --- | --- | --- |
| Standalone Lua interpreter | 5.1.5 recommended | Runs `tests/smoke.lua`. Invoked from the addon root as `lua5.1.exe tests\smoke.lua`, because the harness's path resolution falls back to `./`. |
| `assert` from the Lua standard library | 5.1 | The entire assertion mechanism. There is no test framework, no runner, no fixtures, and no reporter: the harness dies on the first failed assert and prints a `PASSED` summary otherwise. |
| Manual in-game checklist | - | A ten-step sequence covering greetings, joins, level-ups, the recipe cache, alerts, the rate-limited manual send, tabard transitions, Titan integration, and guild-change behavior. This is the only verification path for `UI.lua`, `Options.lua`, `Tabard.lua`, and `Broker.lua`. |

Interpreter notes recorded by the project: LuaJIT 2.1 works but is a superset, so test
code must not depend on its extensions. Lua 5.4 (the version `winget` offers) is
explicitly unsuitable. On Windows no package manager carries 5.1.5, so the LuaBinaries
`lua-5.1.5_Win64_bin.zip` build is used, keeping `lua5.1.dll` and the bundled
`Microsoft.VC80.CRT\` folder beside the executable.

## CI/CD

| Stage | Tooling |
| --- | --- |
| None | No CI, no pipeline, no automated release. Verification is the offline harness plus the manual in-game pass, both run by hand. |

## Version Control

| Tool | State |
| --- | --- |
| Git | Repository present with two commits on `main`, tracking `origin/main`: `49e6f25` "Initial commit" and `e081ff2` "Version 0.1.0". `.kiro/` and `aidlc-docs/` are currently untracked. |

## Development Environment

| Tool | Purpose |
| --- | --- |
| Kiro IDE | Agentic development environment. Eight project steering files encode the product's non-goals, Lua style, safety invariants, client constraints, UI conventions, packaging rules, structure, and testing process. |
| AI-DLC v1 (aidlc-amit-verma power) | Workflow rules installed at `.kiro/steering/core-workflow.md` with details under `.kiro/aws-aidlc-rule-details/`. Artifacts in `aidlc-docs/`. |

## Attribution

Client and API facts in this document derive from the project's own
`.kiro/steering/forever-client-api.md`, which cites the
[Patch 1.60.1 API changes notes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes),
[Blizzard's announcement on Midnight addon changes](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons),
and the [Forever addon overview](https://teamoverpowered.com/forever/guides/addons/).
Content was rephrased for compliance with licensing restrictions.
