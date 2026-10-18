# Technology Stack

**Analysis target**: Forever Guild Comms **0.2.0-beta**
**Supersedes**: the 0.1.0-beta pass of 2026-10-18

The stack itself did not change in 0.2.0. No dependency was added, removed, or upgraded,
and no tooling was introduced. The changes below are the growth in source size, one new
Blizzard frame template, and three additional offline harnesses.

## Programming Languages

| Language | Version | Usage |
| --- | --- | --- |
| Lua | 5.1 | The entire addon, 1,097 lines across seven modules (up from 882 in 0.1.0). Plain Lua 5.1 as embedded by the WoW client: no transpiler, no build step, no external libraries. The four offline harnesses target the same version. |

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
| Blizzard UI frame templates | client-provided | `BasicFrameTemplateWithInset` for all three windows, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`, `UIPanelScrollFrameTemplate`, and **`UIRadioButtonTemplate`** (new in 0.2.0, for the outgoing-mode selector). No custom XML and no reskinning of Blizzard's own frames. |
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
| `ForeverGuildCommsDB` | Account-wide SavedVariables | All settings including the new `outgoingMode`, plus the four message templates (`A.db`) |
| `ForeverGuildCommsCharDB` | Per-character SavedVariables | `recipes`, `myRoles`, `needRoles` (`A.char`) |

Both are written by the client on logout or reload. The addon never serializes anything
itself; it relies on `fillDefaults` to backfill new keys on load so existing users keep
their choices, which is how `outgoingMode` reached existing profiles in 0.2.0.

Deliberately **not** persisted: `A.pendingApprovals`. Staged messages do not survive a
reload, which is the right default for time-sensitive social greetings — a welcome
approved three days late would be worse than one never sent.

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
| Standalone Lua interpreter | 5.1.5 recommended | Runs the four harnesses. Each must be invoked from the addon root, for example `lua5.1.exe tests\verify.lua`, because every harness resolves its base path with a fallback to `./`. |
| `assert` from the Lua standard library | 5.1 | The entire assertion mechanism. There is no test framework, no runner, no fixtures, and no reporter: each harness dies on the first failed assert and prints a `PASSED` summary otherwise. |
| Hand-rolled stub layers | - | Each harness stubs only the client globals its own code path touches. `tests/settings.lua` goes furthest, with a metatable-based fake widget layer that makes `Options.lua` loadable offline, and a `CreateFrame` that records every widget so the test can locate them afterwards by template name or label text. |
| Captured timer queue | - | `tests/verify.lua` replaces `C_Timer.After` with a function that appends the callback to a list instead of running it, so the drain timer can be fired deliberately at the point the test chooses. This is what lets it assert the mid-flight mode-change behavior. |
| Manual in-game checklist | - | A ten-step sequence, revised in 0.2.0 to lead with Verify mode. Still the only verification path for `UI.lua`, `Tabard.lua`, and `Broker.lua`. |

### Offline harnesses

| Harness | Loads | Covers |
| --- | --- | --- |
| `tests/syntax.lua` | all 7 modules, runs none | Every shipped file compiles |
| `tests/smoke.lua` | Core, Roster, Alerts | Roster diffing, guild-join parsing, chat parsing, recipe cache |
| `tests/verify.lua` | Core | The approval workflow, dedup, mode switching, guild-change safety, and that automatic sending still works |
| `tests/settings.lua` | Core, Options | SavedVariables migration, default template refill, the radio pair, the Use default buttons |

Interpreter notes recorded by the project: LuaJIT 2.1 works but is a superset, so test
code must not depend on its extensions. Lua 5.4 (the version `winget` offers) is
explicitly unsuitable. On Windows no package manager carries 5.1.5, so the LuaBinaries
`lua-5.1.5_Win64_bin.zip` build is used, keeping `lua5.1.dll` and the bundled
`Microsoft.VC80.CRT\` folder beside the executable.

## CI/CD

| Stage | Tooling |
| --- | --- |
| None | No CI, no pipeline, no automated release. Verification is the four offline harnesses plus the manual in-game pass, all run by hand. With four harnesses now instead of one, the case for a single runner script is stronger than it was in 0.1.0. |

## Version Control

| Tool | State |
| --- | --- |
| Git | Repository on `main`, tracking `origin/main`, with three commits: `49e6f25` "Initial commit", `e081ff2` "Version 0.1.0", and `a3d52a3` "added Kiro steering & AIDLC + Generated Docs for 0.1.0", which committed `.kiro/` and the previous `aidlc-docs/` artifacts. The 0.2.0 work is **uncommitted**: seven modified files (`Core.lua`, `Roster.lua`, `UI.lua`, `Options.lua`, `Broker.lua`, `ForeverGuildComms.toc`, `README.md`) and three untracked files (`tests/verify.lua`, `tests/settings.lua`, `tests/syntax.lua`). Git reports LF-to-CRLF normalization warnings on the modified files; no `.gitattributes` is present to pin line endings. |

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
