# Lua style for this addon

Match the existing files. The code is plain Lua 5.1 (the WoW runtime) with no build step,
no transpiler, and no external libraries.

## Formatting

- 4 spaces, no tabs. No trailing whitespace. Keep lines under ~100 characters.
- No blank line between short related functions; the existing files pack
  `function A:Foo() ... end` definitions back to back.
- Single-statement bodies may stay on one line when it reads cleanly:
  `if not name then return false end`.
- Table constructors use `{key=value, other=value}` (no spaces around `=`) for compact
  data, and one entry per line for `A.defaults`-style config.
- Use `..` with surrounding spaces for concatenation.

## Naming

- `A` for the addon namespace, methods `PascalCase` (`A:QueueGuild`), state and locals
  `camelCase` (`self.rosterReady`, `local newMember`).
- SavedVariables: `ForeverGuildCommsDB` (account) and `ForeverGuildCommsCharDB`
  (per character, accessed as `A.db` and `A.char`).
- Frame globals and popup keys use the `FGC_` / `FGC` prefix.
- Table keys for names always go through `A:Key(name)` (lowercased, trimmed, whitespace
  collapsed) so lookups are consistent.

## Required idioms

- **Everything lives behind `A:CanUse()`** for guild-facing behavior: it checks the
  enabled flag and `IsInGuild()`.
- **Type-check external data.** Roster levels, chat messages, and Blizzard globals are
  validated before use (`type(message) ~= "string"`, `type(previous.level) == "number"`).
- **Feature-detect every API** before calling it, because this is a beta client:
  ```lua
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
  ```
- **Wrap protected calls that can error** — `SendChatMessage` goes through `pcall` and
  reports failure via `A:Print`.
- **Debounce/schedule with `C_Timer.After` plus a boolean latch**, the
  `ScheduleRecipeScan` / `ScheduleTabardCheck` / `baselineTimer` pattern, so repeated
  events collapse into one run.
- **Clamp user text**: templates cap at 250 characters in `A:Format` and again in
  `A:SendGuild`; edit boxes use `SetMaxLetters`.
- Escape Lua pattern characters when building patterns from Blizzard localized globals
  (see the `ERR_GUILD_JOIN_S` handling in `Roster.lua`). Prefer
  `string.find(haystack, needle, 1, true)` for plain substring tests.
- Use `wipe(t)` for clearing tables, `table.insert`/`table.remove` for list edits.

## Comments

Sparse and explanatory — comment *why* a guard exists, not what a line does. Existing
examples: the realm-suffix note in `A:IsSelf`, the incomplete-roster guard in
`OnRosterEvent`, the item-5976 note in `Tabard.lua`. Keep that density.

## Avoid

- New globals, `getglobal`, string keys built by concatenating unnormalized names.
- `OnUpdate` scripts for periodic work; use `C_Timer.After` / `C_Timer.NewTicker`.
- `/run`-style string loading, `loadstring`, or anything that would taint protected code.
- Deep nesting; prefer early `return` guards, as the existing handlers do.
