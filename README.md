# Forever Guild Comms 0.2.0-beta

WoW: Forever 1.60.1 / Interface 16001 addon by Michael Reilly.

## Install

1. Extract the archive into `World of Warcraft\\_classic_beta_\\Interface\\AddOns\\` (use the actual Forever client folder if different).
2. Confirm the exact folder is `AddOns\\ForeverGuildComms\\ForeverGuildComms.toc`.
3. Start or reload WoW Forever with `/reload`.
4. Open **Settings > AddOns > Forever Guild Comms** or enter `/fgc options`.
5. If Titan Panel is installed, enable the **Guild Comms** Data Broker plugin on your Titan bar.

## Features

- **Login greetings:** detects an existing guild member changing from offline to online after roster initialization.
- **New member welcomes:** localized system guild-join text with duplicate protection.
- **Level congratulations:** detects increases in guild roster level for *other* guildmates while online; filters both character name and GUID to exclude you. There is *no* congratulations message for your own level-up.
- **Automatic or Verify before Sending:** in Settings choose **Automatic** (default, same behavior as v0.1.0) or **Verify with a click**. Verify puts login greetings, new-member welcomes and level-up congratulations into a private popup. Each row shows the message and has **Send** and **Dismiss** buttons; the popup can be reopened with `/fgc verify` or through Titan Panel. There is no automatic posting while Verify is enabled.
- **Custom messages:** edit the login, join, level and manual group-request templates in Settings. The default text is filled into each edit field for new installations and displayed below it, with a **Use default** button per template. Existing nonempty customizations are preserved when updating.
- **Crafting request alerts:** cache the recipes you know by opening each crafting profession, then watch guild chat for explicit requests matching a learned recipe or output name. The cache is stored per character.
- **LFG alerts:** watches guild chat for LFG, LFM, LF, and other group requests. A private alert allows you to start a whisper.
- **Tabard reminders:** asks when entering a major city without the original Guild Tabard item (5976) equipped, and optionally asks on leaving if it is equipped. **Never swaps gear automatically.**
- **Ask for Help:** a compose window to send an explicit guild request: choose Dungeon/Raid/Quest, enter an activity, select which class-appropriate roles you can fill and which roles you need.
- **Titan Panel:** optional LibDataBroker indicator showing online count, alerts and messages awaiting review. Left-click = review if messages are pending (otherwise alerts); Shift-left-click = ask for help; right-click = settings.

## Commands

- `/fgc` or `/fgc alerts` : private alert inbox.
- `/fgc request` : compose a group/quest/raid request.
- `/fgc options` : Settings addon page.
- `/fgc verify` or `/fgc review` : open the pending outgoing-message review window.
- `/fgc status` : guild roster statistics.
- `/fgc recipes` : number of known recipe names cached.
- `/fgc clearrecipes` : remove cached recipes (use after unlearning a profession).

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
- Titan integration uses Titan Panel's embedded LibDataBroker library; if no broker is detected, the addon remains functional without the Titan button.
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
9. Install Titan Panel and select Guild Comms in Titan configuration; verify left-click opens pending messages, and shift/right clicks work.
10. Change back to Automatic and confirm future messages send without a click while *previously pending* messages do not auto-send.

## Feedback and debugging

Enable Lua errors in game with `/console scriptErrors 1`, then `/reload`. If any feature fails, capture the exact Lua error, what event occurred and the client build from `/dump select(4, GetBuildInfo())`.
