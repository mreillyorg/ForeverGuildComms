---
inclusion: auto
name: testing
description: How to run the nine offline Lua harnesses and the in-game verification checklist for Forever Guild Comms. Use when running tests, adding tests, verifying addon behavior, or before releasing.
---

# Testing

Verification is a two-layer process: nine offline Lua harnesses for logic, and a manual
in-game pass for anything that needs a real client.

**There is no test framework and no test automation in CI.** `assert` from the standard
library is the entire mechanism: each harness dies on the first failure and prints a
`PASSED: ...` summary otherwise. `.github/workflows/package.yml` exists but only
*packages* a release on a `v*` tag — it does not run any of these. Running them is
currently a manual step, so run them before tagging.

## Offline harnesses

Nine files in `tests/`, none listed in the TOC and none shipped. Run each **from the addon
root**; every harness resolves its base path with a `./` fallback.

```powershell
lua5.1.exe tests\syntax.lua
lua5.1.exe tests\smoke.lua
lua5.1.exe tests\verify.lua
lua5.1.exe tests\settings.lua
lua5.1.exe tests\timing.lua
lua5.1.exe tests\titanmenu.lua
lua5.1.exe tests\voice.lua
lua5.1.exe tests\keybindings.lua
lua5.1.exe tests\icon.lua
```

| Harness | Loads | What it locks down |
| --- | --- | --- |
| `syntax.lua` | all 11 modules, runs none | Every shipped file compiles. Cheapest possible guard against shipping a parse error |
| `smoke.lua` | Core, Roster, Alerts | The player's own level-up produces **no** message; another member's offline → online produces one greeting; another member's level increase while online produces one congratulation; the localized guild-join line produces one welcome and the player's own join does not; a craft request naming a cached recipe alerts, an LFG line alerts, and the player's own guild chat does not; only learned, non-disabled recipes enter the cache |
| `verify.lua` | Core | The whole approval workflow against the **real** queue and backlog: Verify mode never auto-sends; dedup applies in Verify mode too; Send posts exactly one message; Dismiss never sends; **switching back to Automatic does not release staged messages**; **switching to Verify during the spacing delay captures an in-flight message**; a message cannot cross a guild boundary; `ClearApprovals` empties the backlog; Automatic still sends without a click; `SendChatMessage` is only ever called with `"GUILD"` |
| `settings.lua` | Core, Options | SavedVariables migration: a custom template survives, blank and whitespace-only templates are refilled from defaults, a missing template is filled, `outgoingMode` defaults to `automatic`. Plus the options widgets: two radios with Automatic preselected, four Use default buttons, and both radios switching the mode |
| `timing.lua` | Core + the three voice modules | The **exact** computed queue delay for successive sends, the per-member login cooldown in both directions, and `loginCooldown = 0` allowing repeat greetings |
| `titanmenu.lua` | Core, Options, TitanMenu, Broker | The LibDataBroker data object and the entire nested menu tree, by faking both the frame API and the `MenuUtil` node API, then walking the generated tree and invoking its callbacks |
| `voice.lua` | Core + the three voice modules | Language selection and translation; race filtering (a filtered-out accent cannot be set); an incompatible accent resets to `auto` when the language changes; **a customized template overrides translation and preserves item links**; localized role and activity labels; unknown races fall back to `auto`/`none` only; invalid values are rejected; and UTF-8 truncation never splits a multibyte character |
| `keybindings.lua` | Core, Alerts | Reads `Bindings.xml`, `load()`s each embedded handler, and executes the real binding code. Asserts the bindings are opt-in (**no `default=` attribute**), unique, and correctly categorised; that the actions open the intended windows; that the recipe rescan reports both outcomes; and that **no path sends a guild message**. Also covers the disabled-addon and pre-initialisation cases |
| `icon.lua` | nothing; reads files as text | The icon path stays consistent across the TOC `## IconTexture`, `Broker.lua`, `Options.lua`, and the installer, and both textures exist at a plausible size |

### Which modules are loadable offline

All of them except `Tabard.lua`. The frame-dependent modules are reachable by supplying a
**synthetic widget layer**: a metatable whose `__index` returns a real implementation for
the handful of methods the test cares about (`SetText`, `GetText`, `SetChecked`,
`GetChecked`, `SetScript`, `HasFocus`, `CreateFontString`) and a no-op for everything
else, with `CreateFrame` recording each widget so the test can find it afterwards by
template name or label text. `settings.lua` established the pattern and `titanmenu.lua`
extends it to the menu node API.

- **Covered**: `Core.lua`, `Roster.lua`, `Alerts.lua`, `Options.lua`, `TitanMenu.lua`,
  `Broker.lua`, `Languages.lua`, `Accents.lua`, `RaceProfiles.lua`, and `Bindings.xml`.
- **Loaded but not driven**: `UI.lua`. `titanmenu.lua` loads it, but the window logic —
  notably `UpdateApprovalsUI`'s paging and row binding — is not exercised. The widget
  layer above is the way in if you add coverage.
- **No harness loads it**: `Tabard.lua`. It is the obvious next target: `inMajorCity` and
  `guildTabardEquipped` need only `C_Map`, `GetRealZoneText`, and `GetInventoryItemID`
  stubs, and `CheckTabard`'s transition logic is a pure state machine.

## Interpreter

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

If no interpreter is available, **say so explicitly rather than reporting the suite as
passing.** Reading a harness is not running it.

## Adding tests

When changing roster diffing, chat parsing, the send queue, the approval backlog, the
voice layer, templates, settings validation, or the recipe scan, extend the matching
harness in the same style:

- Stub only what the new path touches.
- Assert both the positive case **and** the "must not fire" case. Every existing harness
  does this, and for a guild-chat addon the negative assertion is the valuable one.
- Where a timer is involved, capture the `C_Timer.After` callback into a list instead of
  running it, so the test fires it deliberately. Keep the `delay` argument if the timing
  itself matters — that is how `timing.lua` verifies the spacing arithmetic.
- Prefer testing the real artifact over a reimplementation. `keybindings.lua` loads and
  executes the actual `Bindings.xml`; `icon.lua` reads the actual TOC and installer.
- Keep the final `print` summary accurate.

## In-game verification

Enable Lua errors first: `/console scriptErrors 1` then `/reload`.

1. Set **Verify with a click** while setting up, customize templates, then enable
   greetings one at a time.
2. Another member logs in → one greeting appears in the private review window. Nothing
   should post before you click Send. Your own login → nothing.
3. A member joins → one welcome in review. Try a **Use default** button in Settings.
4. Another member levels while online → one congratulation. Level your own character →
   **nothing sent**.
5. Switch back to **Automatic** and confirm future messages send without a click while
   *previously pending* messages still require approval or dismissal.
6. Adjust **Automatic message spacing** and **Login greeting cooldown** in Settings and
   again from the Titan menu presets; confirm both surfaces agree and that out-of-range
   typed values are clamped.
7. Open each profession, check `/fgc recipes`, then have a guildmate request a known
   output by name.
8. Have a member post `LFG Deadmines` or `LF healer for quest` → private alert with a
   working Whisper button.
9. `/fgc request`, check the preview, then Send; confirm the 20-second rate limit.
10. Enter and leave a capital city with and without the tabard, with exit reminders both
    off and on.
11. **Languages and accents**: pick a non-English language and confirm the preview and a
    real greeting both change. Turn the race filter on and off and confirm the accent list
    narrows to your race. Then **edit a template** and confirm your text is used verbatim,
    untranslated and un-accented. Check a message containing an item link survives intact.
12. **Key bindings**: assign all three under Options → Key Bindings → AddOns → Forever
    Guild Comms. Confirm no key is bound by default, that **Ask guild for help** opens the
    composer without sending, and that **Rescan open profession** reports honestly both
    with and without a profession window open. A client restart may be needed before the
    bindings appear in the panel.
13. With Titan Panel installed, verify left / shift-left / right click on the broker and
    walk the nested menu. Then confirm the addon still loads with Titan disabled.
14. `/fgc status` and a `/reload`, both in a guild and while guildless, to confirm nothing
    leaks from the baseline or a guild change.

Record anything unverified in the README limitations section. The README is part of the
deliverable, not an afterthought.

## Before tagging a release

The `v*` tag triggers packaging, not testing. Do this first:

1. All nine harnesses run and print `PASSED`.
2. Version strings match in all three places: the TOC `## Version`, `A.version` in
   `Core.lua`, and the `README.md` title.
3. Every shipped `.lua` file is in the TOC in the right load order, and `Bindings.xml` is
   **not** (the client auto-loads it from the addon root).
4. `.pkgmeta` still does not exclude `Bindings.xml` or `Media/Icon.tga`.
5. README features, commands, templates, and limitations reflect the code.
6. The in-game checklist has been walked, or the gaps are written down as limitations.
