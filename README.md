# Forever Guild Comms 0.3.0-beta

WoW: Forever 1.60.1 / Interface 16001 addon by Michael Reilly.

## Install (integrated Windows installer)

1. **Extract All** from `ForeverGuildComms-0.3.0-beta.zip` into any convenient folder. Do not launch scripts directly from inside a compressed ZIP.
2. Double-click **`Install-ForeverGuildComms.cmd`** in the extracted folder, next to the `ForeverGuildComms` subfolder.
3. Choose your WoW Forever client folder if it is not found automatically. You can supply the client (`_classic_beta_`), `Interface`, or `Interface\AddOns` directory.
4. Restart WoW Forever or enter `/reload`, then open **Settings > AddOns > Forever Guild Comms** (or `/fgc options`).
5. If Titan Panel is installed, enable the **Guild Comms** Data Broker plugin.

The integrated installer reads `ForeverGuildComms.toc` and copies **only the `.toc` and loadable Lua/XML files**. Files that are already identical are skipped. It never copies the README, tests, or installer scripts into the AddOns folder, and it does not replace your entire addon directory. Before overwriting addon files, it backs up those specific previous files to `Interface\AddOnBackups`. It leaves all character settings and SavedVariables untouched.

**Manual installation:** Copy the `ForeverGuildComms` subfolder from the extracted archive into `World of Warcraft\_classic_beta_\Interface\AddOns\`. The required folder is `AddOns\ForeverGuildComms\ForeverGuildComms.toc`. Manual copying also copies the included documentation and tests unless you omit them yourself; neither is loaded by WoW.

## Features

- **Login greetings:** detects an existing guild member changing from offline to online after roster initialization.
- **New member welcomes:** localized system guild-join text with duplicate protection.
- **Level congratulations:** detects increases in guild roster level for *other* guildmates while online; filters both character name and GUID to exclude you. There is *no* congratulations message for your own level-up.
- **Automatic or Verify before Sending:** in Settings choose **Automatic** (default, same behavior as v0.1.0) or **Verify with a click**. Verify puts login greetings, new-member welcomes and level-up congratulations into a private popup. Each row shows the message and has **Send** and **Dismiss** buttons; the popup can be reopened with `/fgc verify` or through Titan Panel. There is no automatic posting while Verify is enabled.
- **Message timing controls:** Settings has independent numeric fields for **Automatic message spacing** (3–120 seconds, default 6) and **Login greeting cooldown** (0–3600 seconds, default 300; 0 disables repeat-login cooldown). Both are saved, clamped to supported limits, and have a **Use default** button. Automatic spacing applies to queued automatic greetings, not explicitly approved messages.
- **Custom messages:** edit the login, join, level and manual group-request templates in Settings. The default text is filled into each edit field for new installations and displayed below it, with a **Use default** button per template. Existing nonempty customizations are preserved when updating.
- **Crafting request alerts:** cache the recipes you know by opening each crafting profession, then watch guild chat for explicit requests matching a learned recipe or output name. The cache is stored per character.
- **LFG alerts:** watches guild chat for LFG, LFM, LF, and other group requests. A private alert allows you to start a whisper.
- **Tabard reminders:** asks when entering a major city without the original Guild Tabard item (5976) equipped, and optionally asks on leaving if it is equipped. **Never swaps gear automatically.**
- **Ask for Help:** a compose window to send an explicit guild request: choose Dungeon/Raid/Quest, enter an activity, select which class-appropriate roles you can fill and which roles you need.
- **Titan Panel:** optional LibDataBroker indicator showing online count, alerts and messages awaiting review. Left-click = review if messages are pending (otherwise alerts); Shift-left-click = ask for help; **right-click = nested Guild Comms menu**. No Titan-specific library needs to be bundled. Settings remains usable without Titan.

## Titan Panel nested menu (new in 0.3.0-beta)

**Right-click Guild Comms on the Titan bar** to open the nested menu:

- **Enable addon:** on/off checkbox.
- **Outgoing guild messages:** Automatic / Verify with a click radio modes; individual login / new-member / level-up controls; **Automatic message spacing** presets (3, 6, 10, 15, 30, 60, 120 seconds) and **Login greeting cooldown** presets (0, 60, 300, 600, 900, 1800, 3600 seconds). Each timing submenu has **Reset to default**.
- **Private guild requests:** crafting-request and group-request detection, plus alert sounds.
- **Guild tabard:** the two independent city/exit reminders.
- **Quick actions:** review pending messages, view alerts, ask for help, rescan your currently open profession.
- **Edit custom messages in Settings...:** opens the full Settings page and scrolls to the message editor; **custom text is never edited inside the Titan menu**.
- **Open full Settings...:** opens the normal addon Settings page.

Titan menu and Settings page use the same saved variables and a shared update function. A menu change immediately refreshes existing Settings controls; reopening the menu reflects any Settings changes. Exact custom timing values (such as 17 or 480 seconds) are still editable in Settings and are **not** reset when the Titan menu is opened. Choosing one of the Titan presets changes only the selected timing setting.

Previously queued Verify messages **remain in the review list** if you switch back to Automatic. This behaviour has not changed. If Blizzard's `MenuUtil` context menus are unavailable, right-click falls back to opening the normal Settings page.

## Commands

- `/fgc` or `/fgc alerts` : private alert inbox.
- `/fgc request` : compose a group/quest/raid request.
- `/fgc options` : Settings addon page.
- `/fgc verify` or `/fgc review` : open the pending outgoing-message review window.
- `/fgc status` : guild roster statistics.
- `/fgc recipes` : number of known recipe names cached.
- `/fgc clearrecipes` : remove cached recipes (use after unlearning a profession).

## Timing settings

- `messageSpacing` is the minimum number of seconds between **automatic** guild-chat sends, default **6**. It does not delay a user-confirmed **Send** click.
- `loginCooldown` is the number of seconds between repeated login greetings **to the same guildmate**, default **300** (5 minutes). Set to **0** to allow repeat greetings on every detected offline-to-online transition.
- Both settings are configurable in the AddOns Settings page and persist across reloads; old invalid SavedVariables are normalized automatically. The unused `A.lastMessages` field has been removed; `A.eventsSeen` remains responsible for duplicate suppression.

## Automatic versus Verify mode

- **Automatic** is the default for existing installs; greetings, welcomes, and congratulations continue to post without interaction. Auto sends are spaced apart using the existing queue.
- **Verify with a click** keeps outgoing event messages in a *private* review window. Nothing posts to guild chat until you click the **Send** button for that specific message. Click **Dismiss** to discard it or **Dismiss all** to clear the review list. The popup appears as new review items are created.
- Switching **Verify** back to **Automatic** does not send older pending items; they must still be manually approved or dismissed. Conversely, changing from Automatic to Verify before a queued message is sent moves it to review rather than auto-posting it.
- The review window holds up to 30 items. It clears pending messages if you leave or switch guilds; old messages cannot be approved into another guild. Disabling the addon or leaving guild prevents sending.
- Crafting and LFG alerts are private and unaffected by this setting. Manual help requests already have their own explicit **Send to Guild** button.

## Templates

- Login: `Welcome back, {name}!`
- New guild member: `Welcome to the guild, {name}!`
- Level-up: `Congratulations on level {level}, {name}!`
- Help: `[LFG] {type}: {activity}. I can fill: {myroles}. Looking for: {needed}. Whisper me!`

## Limitations and testing notes

- **Beta / in-game testing required.** Source is written against documented Forever 1.60.1 API, but not run in a real client. Blizzard can adjust APIs during beta.
- Guild roster updates are not a guaranteed instantaneous level-up feed. Updates may be delayed or missed if someone levels when their roster entry is not observed as online. The addon polls no more than once per minute.
- Initial guild roster is treated as a baseline: it never sends messages for everyone already online on login or `/reload`. Very early transitions while initializing may be missed on purpose rather than risk spam.
- Guild welcomes require Blizzard's localized guild-join system message; automatically posted greetings are rate-limited. Messages sent via deliberate Send clicks are not delayed.
- Craft alerts are *not* a guaranteed craftability promise: recipe matching checks what you have learned, not whether you currently have materials, tools or sufficient bag space. You must open your tradeskill panels once after installing; if you unlearn a profession, `/fgc clearrecipes` and rescan to remove stale recipes.
- Group-alert matching is text-based and may pick up ambiguous `LF` messages. It only scans **guild chat** and never automatically whispers.
- Tabard detection currently checks the original Guild Tabard item ID (5976) and a set of capital city maps/English zone names. Other tabard items and localized capitals can be added in a later revision.
- Titan integration uses Titan Panel's embedded LibDataBroker library; if no broker is detected, the addon remains functional without the Titan button. Its right-click menu uses Blizzard `MenuUtil` (expected in the Forever client); if the API is missing, right-click opens the Settings page instead. In-game testing on your particular Titan/Forever combination is still necessary.
- Character role defaults use traditional Vanilla-capable classes, and are selectable in the request window. Roles are labels for communication; the addon does not attempt to inspect your spec.

## Suggested test sequence

1. Set **Verify with a click** while setting up, customize templates, and then enable greetings one at a time.
2. Have another guild member log in; verify a greeting appears in your private review window, then click Send or Dismiss. Nothing should post before clicking Send.
3. Have a member join; check for one welcome in review. Try the Use default button in Settings if you changed a message.
4. Have another member level while online; verify one congratulations. Level yourself and verify **nothing** is sent.
5. Open Tailoring and Enchanting (or your professions), type `/fgc recipes`; ask a guildmate to request a *known output* by name.
6. Have another member write `LFG Deadmines` or `LF healer for quest`; verify the private alert and Whisper button.
7. Request help using `/fgc request` and examine the preview before clicking Send.
8. Move into and out of a capital city with the original Guild Tabard to check the prompts; turn exit reminders on in Settings.
9. Install Titan Panel and select Guild Comms in Titan configuration; verify left-click opens pending messages and shift-left-click opens Ask for Help. Right-click the Titan bar item, explore each nested submenu, toggle greetings, select Verify, change the spacing and cooldown presets and confirm Settings reflects them. Check the custom-message shortcut scrolls to the text fields.
10. Change back to Automatic and confirm future messages send without a click while *previously pending* messages do not auto-send.

## Build and tests

Run `texlua tests/syntax.lua`, then `texlua tests/smoke.lua`, `texlua tests/settings.lua`, `texlua tests/verify.lua`, `texlua tests/timing.lua`, and `texlua tests/titanmenu.lua`. The new Titan test uses a mocked Blizzard menu and Data Broker frame to check menu hierarchy, settings synchronization, mode safety, preset updates, quick actions, and fallback behaviour. These tests **do not replace in-game testing**.

## Feedback and debugging

Enable Lua errors in game with `/console scriptErrors 1`, then `/reload`. If any feature fails, capture the exact Lua error, what event occurred and the client build from `/dump select(4, GetBuildInfo())`.
