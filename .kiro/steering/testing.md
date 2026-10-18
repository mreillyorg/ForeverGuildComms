---
inclusion: auto
name: testing
description: How to run the offline Lua smoke tests and the in-game verification checklist for Forever Guild Comms. Use when running tests, adding tests, verifying addon behavior, or before releasing.
---

# Testing

There is no CI and no test framework. Verification is a two-layer process: an offline
Lua harness for logic, and a manual in-game pass for anything touching the client.

## Offline smoke tests

`tests/smoke.lua` stubs the WoW globals it needs (`UnitName`, `GetTime`, `IsInGuild`,
`C_Timer`, `CreateFrame`, `ERR_GUILD_JOIN_S`, `C_TradeSkillUI`, …), loads `Core.lua`,
`Roster.lua`, and `Alerts.lua` with `loadfile(...)("ForeverGuildComms", A)`, then asserts
on a fake table instead of sending chat. It prints `PASSED: ...` on success and dies on
the first failed `assert`.

Run it **from the addon root** (the path resolution in `smoke.lua` falls back to `./`):

```powershell
lua5.1.exe tests\smoke.lua
```

Use **Lua 5.1**, the version the WoW client embeds. LuaJIT 2.1 works too but is a
superset — it adds `ffi`, `bit`, `jit`, `table.new`, and `goto`, none of which exist in
game — so never let test code depend on those. Do not use Lua 5.4 (available as
`winget install DEVCOM.Lua`); its integer/float split and relocated `unpack` diverge from
the client.

Getting 5.1.5 on Windows: no package manager carries it, so take the
[LuaBinaries](https://luabinaries.sourceforge.net/) `lua-5.1.5_Win64_bin.zip` from the
SourceForge *Tools Executables* folder for 5.1.5 and unzip it somewhere on PATH. Keep
`lua5.1.dll` and the bundled `Microsoft.VC80.CRT\` folder next to `lua5.1.exe`; the
executable is a vc8 build and will not start without them. The binary is named
`lua5.1.exe`, not `lua.exe`.

If no interpreter is available, say so explicitly rather than reporting the suite as
passing.

What it currently locks down, and what must keep passing:

- the player's own level-up produces **no** message;
- another member's offline → online produces one login greeting;
- another member's level increase while online produces one congratulation;
- the localized guild-join line produces one welcome, and the player's own join does not;
- a craft request naming a cached recipe alerts, an LFG line alerts, and the player's own
  guild chat does not;
- only learned, non-disabled recipes enter the cache.

When changing roster diffing, chat parsing, templates, or the recipe scan, extend this
file in the same style: stub only what the new path touches, assert both the positive
case and the "must not fire" case, and keep the final `print` summary accurate.

Only `Core.lua`, `Roster.lua`, and `Alerts.lua` are loadable offline. `UI.lua`,
`Options.lua`, `Tabard.lua`, and `Broker.lua` depend on real frame, Settings, popup, and
LibStub APIs — test those in game.

## In-game verification

Enable Lua errors first: `/console scriptErrors 1` then `/reload`.

1. Turn the automatic chat options off while setting up, edit templates, then enable one
   feature at a time.
2. Another member logs in → exactly one greeting; your own login → none.
3. A member joins → exactly one welcome.
4. Another member levels while online → one congratulation. Level your own character →
   **nothing sent**.
5. Open each profession, check `/fgc recipes`, then have a guildmate request a known
   output by name.
6. Have a member post `LFG Deadmines` or `LF healer for quest` → private alert with a
   working Whisper button.
7. `/fgc request`, check the preview, then Send; confirm the 20-second rate limit.
8. Enter and leave a capital city with and without the tabard, with exit reminders both
   off and on.
9. With Titan Panel installed, verify left / shift-left / right click on the Guild Comms
   broker; then confirm the addon still loads with Titan disabled.
10. `/fgc status` and a `/reload` in a guild and while guildless, to confirm no messages
    leak from the baseline or a guild change.

Record anything unverified in the README limitations section. The README is part of the
deliverable, not an afterthought.
