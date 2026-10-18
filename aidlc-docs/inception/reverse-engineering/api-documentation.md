# API Documentation

## REST APIs

None. Forever Guild Comms exposes no HTTP surface and makes no network calls. It runs
in-process inside the WoW client. Its only outbound channel of any kind is
`SendChatMessage(message, "GUILD")`.

## User-Facing Command API

Registered in `Core.lua` as `SLASH_FOREVERGUILDCOMMS1 = "/fgc"` and
`SLASH_FOREVERGUILDCOMMS2 = "/guildcomms"`. Input is lowercased and trimmed before
dispatch. The handler returns early with a printed note if `A.initialized` is false.

| Command | Aliases | Behavior |
| --- | --- | --- |
| `/fgc` | `/guildcomms` | Falls through to the alerts window (the default branch) |
| `/fgc alerts` | - | `A:ShowAlerts` — opens the private alert inbox |
| `/fgc options` | `/fgc settings` | `A:OpenSettings` — opens the Settings category |
| `/fgc request` | `/fgc help` | `A:ShowRequest` — opens the Ask-for-Help compose window |
| `/fgc status` | - | Prints guild member count, online count, pending private alert count |
| `/fgc recipes` | - | Prints the number of cached learned recipe names across all professions |
| `/fgc clearrecipes` | - | `wipe(A.char.recipes)` and prints a confirmation |

## Internal APIs

All public behavior is attached to the single shared table `A`, published once as
`_G.ForeverGuildComms`. Methods are called as `self:Method()` within a module or
`A:Method()` across modules, always through an existence check when crossing files.

### Core.lua — identity and formatting helpers

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:Print` | `(s: any)` | nil | Prints `s` to the chat frame behind the coloured `ForeverGuildComms` tag. Every console message goes through here. |
| `A:Key` | `(name: any)` | `string` | Normalizes a character name: lowercase, trim both ends, collapse internal whitespace. Returns `""` for non-strings. All name-keyed table lookups go through this. |
| `A:IsSelf` | `(name: string?, guid: string?)` | `boolean` | True if the subject is the player. Checks GUID equality first, then the normalized name against `A.selfKeys`, then the name with only an explicit `-Realm` suffix removed. Never shortens further, because guildmates can share a first name. |
| `A:Format` | `(template: any, vars: table?)` | `string` | Substitutes `{alpha}` placeholders from `vars`, leaving unknown placeholders literal. Result is clamped to 250 characters. |
| `A:CanUse` | `()` | `boolean` | The authorization gate: requires `A.db.enabled` and `IsInGuild()`. Every guild-facing path checks it. |
| `A:Now` | `()` | `number` | `GetTime()` when available, otherwise `0`. |
| `A:IsDuplicate` | `(key: string, cooldown: number?)` | `boolean` | True if `key` was seen within `cooldown` seconds (default 90). Otherwise stamps `A.eventsSeen[key]` with the current time and returns false. Note the side effect: calling this *records* the key. |
| `A:RoleText` | `(roles: table?, noneText: string?)` | `string` | Joins enabled role labels in `A.roleOrder` with `/`, or returns `noneText` (default `"Any"`) when none are set. |
| `A:OpenSettings` | `()` | nil | Opens the registered Settings category, or prints a fallback note. |
| `A:Initialize` | `()` | nil | Idempotent startup: initializes both SavedVariables tables, backfills defaults, resolves player identity and class role defaults, then calls `BuildOptions`, `BuildUI`, `SetupRoster`, a delayed `CheckTabard(true)`, and `TryBroker`, each guarded. |

### Core.lua — the send pipeline

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:SendGuild` | `(message: string)` | `boolean` | The only function that calls `SendChatMessage`. Requires `CanUse`, a non-empty string, and the presence of `SendChatMessage`. Clamps to 250 characters and wraps the call in `pcall`, reporting failure through `A:Print`. Returns the `pcall` success flag. |
| `A:QueueGuild` | `(message: string, key: string, cooldown: number?)` | nil | The entry point for **all** automatic messages. Requires `CanUse`, then rejects the message if `IsDuplicate(key, cooldown or 90)`. Accepted text is appended to `A.pendingMessages` and `DrainQueue` is kicked. |
| `A:DrainQueue` | `()` | nil | Releases one queued message at a time. Returns early if a drain is already latched or the queue is empty. Wipes the queue entirely if `CanUse` has become false. Waits `max(3, db.messageSpacing)` seconds since `A.lastGuildSend` before each send, then re-arms itself while messages remain. |

**Contract**: automatic messages must use `QueueGuild`. `SendGuild` is called directly
only from `A:SendHelpRequest`, which is driven by an explicit button press and enforces
its own 20-second limit.

### Roster.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:RequestRoster` | `(force: boolean?)` | nil | Asks the client to refresh the roster, at most once per 30 seconds unless `force` is set. Feature-detects `C_GuildInfo.GuildRoster`. |
| `A:ReadRoster` | `()` | `members: table, count: number, online: number` | Iterates `GetNumGuildMembers()` and reads `GetGuildRosterInfo(i)`, building a table keyed by `A:Key(name)` with `{name, level, online, guid}` values. Skips empty names. |
| `A:AcceptRoster` | `(members, count, online, baseline: boolean)` | nil | The diff and the state commit. When `baseline` is false and `rosterReady` is true, compares each member against the retained roster and queues level-up then login messages. Always replaces `A.roster`, `guildCount`, `onlineCount`, sets `rosterReady`, and refreshes the broker. |
| `A:CaptureBaseline` | `()` | nil | Takes the first roster read for a guild and commits it with `baseline=true` so nothing is sent. If the read returns zero members it requests a refresh and retries after 4 seconds. |
| `A:OnRosterEvent` | `(event: string)` | nil | Event entry point. Detects a guild change and resets state, wiping `pendingMessages` so queued text cannot leak into a new guild. Schedules a baseline when not ready. Otherwise reads and diffs, discarding suspicious reads. |
| `A:OnSystemGuildJoin` | `(message: string)` | nil | Builds a pattern from the localized `ERR_GUILD_JOIN_S` global by escaping Lua pattern metacharacters and turning the `%s` slot into a capture, then queues one welcome for a non-self new member. |
| `A:SetupRoster` | `()` | nil | Called from `Initialize`. Fires `OnRosterEvent` immediately and again after 5 seconds, then starts a 60-second `C_Timer.NewTicker` that calls `RequestRoster` while `CanUse` holds. |

#### `A:AcceptRoster` diff conditions

A level-up congratulation requires **all** of:
`db.enabled` and `db.congratulateLevel`; the member existed in the previous roster;
`not IsSelf(name, guid)`; `previous.online` and `member.online`;
`type(previous.level) == "number"` and `previous.level > 0`;
`type(member.level) == "number"` and `member.level > previous.level`.
Cooldown key `level:<normalizedName>:<newLevel>`, window 1800 seconds.

A login greeting requires **all** of:
`db.enabled` and `db.greetLogin`; the member existed in the previous roster;
`not IsSelf(name, guid)`; `not previous.online` and `member.online`.
Cooldown key `login:<normalizedName>`, window `db.loginCooldown` (default 300 seconds).

Suspicious-read rejection in `OnRosterEvent`: the read is discarded when `count == 0`, or
when `guildCount > 10` and `count < guildCount * 0.7`.

### Alerts.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:AddAlert` | `(kind: string, sender: string, text: string)` | nil | Appends a private alert at position 1 with a `HH:MM` timestamp, trims the list to 30, prints it locally, optionally plays `SOUNDKIT.TELL_MESSAGE`, and refreshes the UI and broker. Dedup key `kind:normalizedSender:lowercasedText`, window 120 seconds. Emits nothing to guild chat or a whisper. |
| `A:ScheduleRecipeScan` | `()` | nil | Debounces a scan behind `A.recipeScanPending` and a 0.5-second timer. |
| `A:ScanRecipes` | `()` | nil | Reads `C_TradeSkillUI.GetAllRecipeIDs()`, resolves the profession name when the skill-line APIs exist (falling back to the literal `"Current Profession"`), and builds a fresh cache for that one profession. Only recipes that are `learned`, not `disabled`, and not `isGatheringRecipe` are included; both the output item name from the recipe link and `info.name` are cached when at least 4 characters long. Writes `A.char.recipes[profession]` only if non-empty. |
| `A:MatchCraft` | `(lower: string)` | `string?` | Returns the matched recipe display name, or nil. Requires `looksLikeCraftRequest(lower)` first, then a plain-substring hit on a cached recipe key. |
| `A:OnGuildChat` | `(message: string, sender: string)` | nil | Requires `CanUse`, a sender, and `not IsSelf(sender)`. Cleans escapes, then raises a craft alert when `db.craftingAlerts` and `MatchCraft` hit, and a group alert when `db.groupAlerts`, a group pattern hits, and the line is *not* also a craft request. |

#### File-local matchers

`cleanChat(message)` rewrites `|H...|h[Name]|h` to `Name`, then strips `|cXXXXXXXX`
colour openers and `|r` closers, so matching sees visible item names.

`looksLikeCraftRequest(message)` is a plain-substring test (`find(..., 1, true)`) over
twelve phrases: `wtb`, `can anyone craft`, `can someone craft`, `need crafted`,
`looking for crafter`, `looking for someone to make`, `lf crafter`, `can anyone make`,
`can someone make`, `who can make`, `anyone able to make`, `need someone to make`.

`looksLikeGroupRequest(message)` combines frontier-anchored patterns `lfg`, `lfm`,
`lf%d+m`, a leading `lf%s+`, and the substrings `looking for group`,
`looking for more`, `group for`, `anyone for`, `need a tank`, `need a healer`.

### Tabard.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:CheckTabard` | `(initial: boolean?)` | nil | Requires `A.db` and `CanUse`. On the first call `A.wasInCity` is nil, so it records the current state and only prompts when `initial` is true. Thereafter it prompts only on a transition: entering a city without the tabard when `db.tabardInCity`, or leaving a city wearing it when `db.tabardOnExit`. |
| `A:ScheduleTabardCheck` | `()` | nil | Debounces behind `A.tabardCheckScheduled` and a 1.2-second timer. |

`inMajorCity()` prefers `C_Map.GetBestMapForUnit("player")` against eight map IDs
(84, 85, 87, 88, 89, 90, 103, 110) and falls back to `GetRealZoneText()` against nine
English zone-name keys covering the eight capitals.
`guildTabardEquipped()` checks `GetInventoryItemID("player", 19) == 5976`, the Vanilla-era
Guild Tabard.

### UI.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildUI` | `()` | nil | Creates `FGCAlertsFrame` (570x440, movable, DIALOG strata) with seven reusable rows, a page indicator, Prev/Next/Clear/Ask-for-help buttons, then builds the request window and does a first refresh. Starts hidden. |
| `A:UpdateAlertsUI` | `()` | nil | Clamps `A.alertPage` to the computed page count, maps `A.alerts` onto the seven rows seven-at-a-time, shows or hides each row, and truncates row text over 78 characters to 75 plus an ellipsis. |
| `A:ShowAlerts` | `()` | nil | Refreshes then shows the alerts frame. |
| `A:BuildRequestUI` | `()` | nil | Creates `FGCRequestFrame` (518x390) with the activity edit box (max 100 letters), a Dungeon/Raid/Quest cycling button, "my roles" checkboxes disabled where the player's class cannot fill the role, "needed roles" checkboxes, a live preview, and Send/Cancel. Starts hidden. |
| `A:RequestText` | `()` | `string` | Renders `db.templates.help` with `activity` (trimmed, or the literal `[activity]`), `type`, `myroles` (default `"Flexible"`), `needed` (default `"Any role"`), and `name`. |
| `A:UpdateRequestPreview` | `()` | nil | Writes `RequestText()` into the preview label when the frame and `db` exist. |
| `A:ShowRequest` | `()` | nil | Refreshes the preview then shows the compose frame. |
| `A:SendHelpRequest` | `()` | nil | The only direct `SendGuild` caller. Requires `CanUse`, a non-empty activity, and 20 seconds since `A.lastManualRequest`; prints a specific reason for each refusal. On success stamps the timestamp and hides the frame. |

The Whisper button on an alert row calls `ChatFrame_OpenChat("/w " .. sender .. " ")`.
It populates the chat edit box and sends nothing.

### Options.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildOptions` | `()` | nil | Prints a note and returns if `Settings.RegisterCanvasLayoutCategory` is missing. Otherwise builds `ForeverGuildCommsOptionsPanel` with a scrolling content frame, nine toggles across four sections, four template edit boxes (max 250 letters), three quick-action buttons, and the `OnRefresh` / `OnCommit` / `OnDefault` handlers, then registers the canvas category and stores it on `A.settingsCategory`. |

Panel callbacks: `OnRefresh` replays every collected control-sync closure;
`OnCommit` writes each template edit box back into `A.db.templates` and clears focus;
`OnDefault` deep-copies `A.defaults` over `A.db` one level down, then refreshes.

### Broker.lua

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:TryBroker` | `()` | nil | Idempotent. Returns if already created or if `LibStub("LibDataBroker-1.1", true)` yields nothing. Otherwise publishes the `ForeverGuildComms` data object with type `data source`, a guild tabard icon, an `OnClick` handler (right-click settings, shift-left request, left alerts), and an `OnTooltipShow` handler listing counts and the click bindings. |
| `A:UpdateBroker` | `()` | nil | Rewrites the broker label to `Guild <online> / <total> | Alerts <count>` when a broker exists. |

## Data Models

### Setting record — `A.defaults`, persisted as `ForeverGuildCommsDB` (`A.db`)

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `enabled` | boolean | `true` | Master switch, half of `CanUse` |
| `greetLogin` | boolean | `true` | Enables BT-1 |
| `greetJoin` | boolean | `true` | Enables BT-2 |
| `congratulateLevel` | boolean | `true` | Enables BT-3 |
| `craftingAlerts` | boolean | `true` | Enables BT-4 |
| `groupAlerts` | boolean | `true` | Enables BT-5 |
| `tabardInCity` | boolean | `true` | Prompt on entering a capital without the tabard |
| `tabardOnExit` | boolean | `false` | Prompt on leaving a capital wearing it. Defaults off as the surprising option |
| `loginCooldown` | number | `300` | Dedup window for login greetings, in seconds |
| `messageSpacing` | number | `6` | Requested gap between queued sends; the queue enforces `max(3, this)` |
| `alertsSound` | boolean | `false` | Play a sound on a private alert |
| `templates.login` | string | `"Welcome back, {name}!"` | Supports `{name}`, `{level}` |
| `templates.join` | string | `"Welcome to the guild, {name}!"` | Supports `{name}` |
| `templates.level` | string | `"Congratulations on level {level}, {name}!"` | Supports `{name}`, `{level}` |
| `templates.help` | string | `"[LFG] {type}: {activity}. I can fill: {myroles}. Looking for: {needed}. Whisper me!"` | Supports `{type}`, `{activity}`, `{myroles}`, `{needed}`, `{name}` |

- **Validation**: `fillDefaults` backfills any missing key recursively on load, so new
  settings appear for existing users without disturbing their choices. `messageSpacing`
  passes through `tonumber` with a fallback of 6 and a hard floor of 3. Template strings
  are clamped to 250 characters in `A:Format` and again in `A:SendGuild`, and the edit
  boxes additionally cap input with `SetMaxLetters(250)`.

### Per-character record — `ForeverGuildCommsCharDB` (`A.char`)

| Field | Type | Meaning |
| --- | --- | --- |
| `recipes` | `table<professionName, table<lowercaseName, displayName>>` | Known recipe and output names, rebuilt per profession on each scan. Per character because professions are character-specific. |
| `myRoles` | `table<role, boolean>` | Which of tank/healer/damage the player offers. Seeded from `A.classRoles[playerClass]` where unset. |
| `needRoles` | `table<role, boolean>` | Which roles the player wants to recruit. Empty means any. |

### Roster member record — `A.roster[key]`

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Display name as returned by the client |
| `level` | number | Character level; type-checked before any comparison |
| `online` | boolean | Coerced from the client's truthy value |
| `guid` | string | Used for the primary self-exclusion check |

Keyed by `A:Key(name)`. **Relationships**: the previous accepted `A.roster` is the only
input to the diff; there is no history beyond one generation.

### Private alert record — `A.alerts[i]`

| Field | Type | Meaning |
| --- | --- | --- |
| `kind` | string | `"Craft: <recipeName>"` or `"Group request"` |
| `sender` | string | Guild chat sender, as received |
| `text` | string | The cleaned message body |
| `time` | string | `HH:MM` capture at insert time |

Newest first (`table.insert(..., 1, ...)`), hard-capped at 30 entries by dropping the
oldest. **Relationships**: read by `UpdateAlertsUI` for paging and by `UpdateBroker` for
its count.

### Cooldown record — `A.eventsSeen[key]`

A flat map from cooldown key to the `A:Now()` timestamp at which the key was last
accepted. Key formats in use:

| Kind | Key format | Window |
| --- | --- | --- |
| Login greeting | `login:<normalizedName>` | `db.loginCooldown`, default 300s |
| Guild join | `join:<normalizedName>` | 300s |
| Level-up | `level:<normalizedName>:<level>` | 1800s |
| Private alert | `<kind>:<normalizedSender>:<lowercasedText>` | 120s |

The table is never pruned, so it grows with the number of distinct keys observed in a
session. See `code-quality-assessment.md`.

## Blizzard API Surface Consumed

Every one of these is feature-detected at the call site, because the client is in beta.

| API | Used in | Purpose |
| --- | --- | --- |
| `C_Timer.After`, `C_Timer.NewTicker` | Core, Roster, Alerts, Tabard | All deferred and periodic work; no `OnUpdate` anywhere |
| `C_GuildInfo.GuildRoster` | Roster | Request a roster refresh |
| `GetNumGuildMembers`, `GetGuildRosterInfo`, `GetGuildInfo`, `IsInGuild` | Core, Roster | Roster read and guild identity |
| `ERR_GUILD_JOIN_S` | Roster | Localized guild-join sentence, parsed into a pattern |
| `C_TradeSkillUI.GetAllRecipeIDs`, `GetRecipeInfo`, `GetRecipeItemLink`, `GetProfessionChildSkillLineID`, `GetProfessionInfoBySkillLineID` | Alerts | Recipe cache construction |
| `C_Map.GetBestMapForUnit`, `GetRealZoneText` | Tabard | City detection, map ID preferred over zone name |
| `GetInventoryItemID` | Tabard | Tabard slot check |
| `StaticPopupDialogs`, `StaticPopup_Show`, `ToggleCharacter` | Tabard | Reminder popups and opening the character panel |
| `SendChatMessage` | Core | The single outbound channel, `"GUILD"` only |
| `UnitGUID`, `UnitName`, `GetUnitName`, `UnitFullName`, `UnitClass` | Core | Self-identity and class role defaults |
| `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory` | Core, Options | Modern settings panel |
| `CreateFrame` and the Basic/UIPanel/UICheck/InputBox templates | UI, Options, Core | All frames and widgets |
| `ChatFrame_OpenChat` | UI | Populate the chat box for a manual whisper |
| `PlaySound`, `SOUNDKIT.TELL_MESSAGE` | Alerts | Optional alert sound |
| `LibStub` | Broker | Optional LibDataBroker lookup |
| `GetTime`, `date`, `wipe` | Core, Alerts, Roster | Timing, timestamps, table clearing |
