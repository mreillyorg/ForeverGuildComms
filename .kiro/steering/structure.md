# Project structure and module pattern

Flat addon folder, no subdirectories for source. The folder name must stay
`ForeverGuildComms` with `ForeverGuildComms.toc` inside it, matching the TOC filename.

## Load order (as listed in the TOC — order matters)

| File | Responsibility |
| --- | --- |
| `Core.lua` | Shared table, defaults, helpers (`Print`/`Key`/`IsSelf`/`Format`/`CanUse`/`Now`/`IsDuplicate`), guild send queue, SavedVariables init, slash commands, the single event frame |
| `Roster.lua` | Guild roster read/baseline/diff, login + level-up messages, guild-join system message parsing |
| `Alerts.lua` | Guild chat parsing, craft/group detection, recipe cache scan, private alert list |
| `Tabard.lua` | City detection, tabard checks, `StaticPopupDialogs` |
| `UI.lua` | Alerts window, Ask-for-Help window, preview and send |
| `Options.lua` | Settings canvas panel registration |
| `Broker.lua` | Optional LibDataBroker data object |

`tests/smoke.lua` is an offline harness and is **not** listed in the TOC.

## Module pattern

Every file starts by capturing the addon vararg into the shared table:

```lua
local _, A = ...          -- Core.lua uses: local ADDON, A = ...
```

- `A` is the one shared namespace. `Core.lua` publishes it as `_G.ForeverGuildComms`;
  no other global is created except the `SLASH_*` / `SlashCmdList` entries and named
  frames (`ForeverGuildCommsOptionsPanel`, `FGCAlertsFrame`, `FGCRequestFrame`).
- Public behavior goes on `A` as methods: `function A:Thing() ... end`, called as
  `self:Thing()` or `A:Thing()`.
- File-local helpers stay `local function` and are not exposed (e.g. `cleanChat`,
  `inMajorCity`, `fillDefaults`, `MakeLabel`).
- State lives on `A` and is declared up front with a safe initial value
  (`A.roster = {}`, `A.rosterReady = false`, …), so later files never index nil.

## Cross-file calls must be guarded

Later modules are optional from `Core.lua`'s point of view. Call across files with an
existence check, as `A:Initialize` and the event handler do:

```lua
if self.BuildUI then self:BuildUI() end
if A.OnGuildChat then A:OnGuildChat(...) end
```

## Events

There is exactly **one** `CreateFrame("Frame")` event dispatcher, at the bottom of
`Core.lua`. New events get registered there and routed to a guarded module method.
Do not create additional event frames in feature files; the handler also enforces the
`if not A.initialized then return end` gate.

## New feature checklist

1. Add the file to the TOC in the correct position (after `Core.lua`).
2. Start it with `local _, A = ...` and declare its state on `A`.
3. Add any default settings to `A.defaults` in `Core.lua` (`fillDefaults` migrates
   existing SavedVariables automatically).
4. Register new events in the `Core.lua` frame and dispatch with a guard.
5. Expose the feature through `Options.lua` toggles and, if relevant, a `/fgc` subcommand.
6. Update `README.md` (features, commands, limitations).
