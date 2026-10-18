# API Documentation

**Analysis target**: Forever Guild Comms **0.2.0-beta**
**Supersedes**: the 0.1.0-beta pass of 2026-10-18
New or changed entries are marked **new** or **changed**.

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
| `/fgc verify` | `/fgc review` | **New.** `A:ShowApprovals` — opens the pending outgoing-message review window |
| `/fgc options` | `/fgc settings` | `A:OpenSettings` — opens the Settings category |
| `/fgc request` | `/fgc help` | `A:ShowRequest` — opens the Ask-for-Help compose window |
| `/fgc status` | - | **Changed.** Now prints member count, online count, private alert count, **pending review count, and the current outgoing mode** |
| `/fgc recipes` | - | Prints the number of cached learned recipe names across all professions |
| `/fgc clearrecipes` | - | `wipe(A.char.recipes)` and prints a confirmation |

The login banner also changed, to advertise the new command:
`"Loaded. /fgc for alerts, /fgc verify to review messages, /fgc options for settings."`

## Internal APIs

All public behavior is attached to the single shared table `A`, published once as
`_G.ForeverGuildComms`. 45 `function A:` definitions in total.

### Core.lua — identity and formatting helpers

Unchanged in 0.2.0.

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:Print` | `(s: any)` | nil | Prints `s` behind the coloured `ForeverGuildComms` tag. Every console message goes through here. |
| `A:Key` | `(name: any)` | `string` | Normalizes a character name: lowercase, trim, collapse internal whitespace. Returns `""` for non-strings. |
| `A:IsSelf` | `(name: string?, guid: string?)` | `boolean` | True if the subject is the player. GUID equality first, then the normalized name against `A.selfKeys`, then the name with only an explicit `-Realm` suffix removed. Never shortens further. |
| `A:Format` | `(template: any, vars: table?)` | `string` | Substitutes `{alpha}` placeholders, leaving unknown ones literal. Clamped to 250 characters. |
| `A:CanUse` | `()` | `boolean` | The authorization gate: `A.db.enabled` and `IsInGuild()`. |
| `A:Now` | `()` | `number` | `GetTime()` when available, otherwise `0`. |
| `A:IsDuplicate` | `(key: string, cooldown: number?)` | `boolean` | True if `key` was seen within `cooldown` seconds (default 90). Otherwise stamps `A.eventsSeen[key]` and returns false. Note the side effect: calling this *records* the key. |
| `A:RoleText` | `(roles: table?, noneText: string?)` | `string` | Joins enabled role labels in `A.roleOrder` with `/`, or returns `noneText` (default `"Any"`). |
| `A:OpenSettings` | `()` | nil | Opens the registered Settings category, or prints a fallback note. |

### Core.lua — the send pipeline **(changed)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:SendGuild` | `(message: string)` | `boolean` | Unchanged. The only function that calls `SendChatMessage`. Requires `CanUse`, a non-empty string, and the presence of `SendChatMessage`. Clamps to 250 characters, wraps in `pcall`, reports failure through `A:Print`. |
| `A:QueueGuild` | `(message: string, key: string, cooldown: number?)` | nil | **Changed.** Still the entry point for all roster-driven messages, but now builds a record and branches on the mode. See below. |
| `A:DrainQueue` | `()` | nil | **Changed.** Still releases one queued entry at a time with spacing, but now re-validates guild identity and the outgoing mode at fire time. See below. |

#### `A:QueueGuild` in 0.2.0

```lua
function A:QueueGuild(message, key, cooldown)
    if not self:CanUse() or type(message) ~= "string" or message == "" then return end
    if self:IsDuplicate(key, cooldown or 90) then return end
    local entry = {
        text = message:sub(1, 250),
        kind = (type(key) == "string" and key:match("^([^:]+):")) or "message",
        guild = GetGuildInfo and GetGuildInfo("player") or nil,
        time = date and date("%H:%M") or "",
    }
    if self.db.outgoingMode == "verify" then
        self:StageApproval(entry)
    else
        table.insert(self.pendingMessages, entry)
        self:DrainQueue()
    end
end
```

Three behavioral notes:

1. A **type and emptiness check on `message`** was added, so a blanked template cannot
   produce an empty queue entry. Because this check runs before `IsDuplicate`, an empty
   message does not consume its cooldown key either.
2. **Dedup runs before the mode branch**, so Verify mode inherits the full duplicate
   protection rather than flooding the review window.
3. The **`kind` segment is parsed back out of the cooldown key** (`login`, `join`, or
   `level`) purely so the review window can label the row. The key format is therefore
   now load-bearing for presentation as well as dedup.

#### `A:DrainQueue` in 0.2.0

The timer callback now performs three re-checks before sending, where 0.1.0 sent
unconditionally:

| Re-check | Outcome if it fails |
| --- | --- |
| `self:CanUse()` | Entry silently dropped; the loop continues with the next entry |
| `entry.guild == GetGuildInfo("player")` | Entry silently dropped — it was composed for a different guild |
| `self.db.outgoingMode == "verify"` | Entry is **staged for approval** instead of sent |

The up-front `if not self:CanUse() then wipe(self.pendingMessages); return end` guard is
retained, so an addon that becomes ineligible before the timer fires still discards the
whole queue.

### Core.lua — the approval backlog **(all new)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:StageApproval` | `(entry: table)` | nil | Appends `entry` to `A.pendingApprovals` after re-checking `CanUse`. If the backlog already holds 30 entries it removes index 1 first, so a flood drops the **oldest** unreviewed message. Then calls `UpdateApprovalsUI`, `UpdateBroker`, and `ShowApprovals`, each guarded. |
| `A:ApproveMessage` | `(index: number)` | nil | The explicit send. Returns if no entry sits at `index`. Prints a reason and returns if `CanUse` is false. If `entry.guild` no longer matches the current guild it dismisses the entry and prints "Message discarded: your guild has changed." Otherwise calls `SendGuild` directly, and on success stamps `lastGuildSend`, removes the entry, and refreshes the UI and broker. |
| `A:DismissMessage` | `(index: number)` | nil | Removes the entry at `index` and refreshes the UI and broker. Cannot send anything. |
| `A:ClearApprovals` | `()` | nil | `wipe(A.pendingApprovals)` and refresh. Called by the Dismiss all button and by `Roster.lua` on a guild change. |

**Contract**: `ApproveMessage` deliberately bypasses the spacing queue and schedules no
timer. The source comments the reason: "The Send button is the actual user confirmation.
Do not schedule a delayed automatic send after a click." There is no rate limit on
approvals, unlike `SendHelpRequest`'s 20-second window.

**Invariant**: switching `outgoingMode` to `"automatic"` does **not** flush the backlog.
Staged entries can only leave through `ApproveMessage`, `DismissMessage`, or
`ClearApprovals`. `tests/verify.lua` asserts this directly.

### Core.lua — initialization **(changed)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:Initialize` | `()` | nil | Idempotent startup. Initializes both SavedVariables tables, runs `fillDefaults`, then applies **two new migrations**, resolves player identity and class role defaults, and calls `BuildOptions`, `BuildUI`, `SetupRoster`, a delayed `CheckTabard(true)`, and `TryBroker`, each guarded. |

The two new migrations, both run after `fillDefaults`:

```lua
-- 1. Normalize an unrecognized persisted mode toward the safe documented default.
if ForeverGuildCommsDB.outgoingMode ~= "verify" then
    ForeverGuildCommsDB.outgoingMode = "automatic"
end

-- 2. Refill blank templates; preserve non-empty customizations.
for key, defaultMessage in pairs(self.defaults.templates) do
    if type(ForeverGuildCommsDB.templates[key]) ~= "string"
       or ForeverGuildCommsDB.templates[key]:match("^%s*$") then
        ForeverGuildCommsDB.templates[key] = defaultMessage
    end
end
```

`tests/settings.lua` covers both: a custom login template survives, a blank join template
and a whitespace-only level template are replaced by their defaults, a missing help
template is filled, and the default mode resolves to `"automatic"`.

### Roster.lua **(one-line change)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:RequestRoster` | `(force: boolean?)` | nil | Asks the client to refresh the roster, at most once per 30 seconds unless `force`. Feature-detects `C_GuildInfo.GuildRoster`. |
| `A:ReadRoster` | `()` | `members, count, online` | Iterates `GetNumGuildMembers()` and `GetGuildRosterInfo(i)`, keyed by `A:Key(name)` with `{name, level, online, guid}`. Skips empty names. |
| `A:AcceptRoster` | `(members, count, online, baseline)` | nil | The diff and state commit. When `baseline` is false and `rosterReady` is true, queues level-up then login messages for changed members. Always replaces `A.roster`, the counts, and `rosterReady`, then refreshes the broker. |
| `A:CaptureBaseline` | `()` | nil | Commits the first read with `baseline=true` so nothing is sent. Retries after 4 seconds if the read returned zero members. |
| `A:OnRosterEvent` | `(event: string)` | nil | **Changed.** On a guild change it wipes `pendingMessages` as before and now also calls `ClearApprovals` through an existence check, so staged messages cannot survive into a new guild. |
| `A:OnSystemGuildJoin` | `(message: string)` | nil | Builds a pattern from the localized `ERR_GUILD_JOIN_S` by escaping metacharacters and converting the `%s` slot into a capture, then queues one welcome for a non-self new member. |
| `A:SetupRoster` | `()` | nil | Fires `OnRosterEvent` immediately and again after 5 seconds, then starts a 60-second ticker calling `RequestRoster` while `CanUse` holds. |

#### `A:AcceptRoster` diff conditions (unchanged)

A level-up congratulation requires **all** of: `db.enabled` and `db.congratulateLevel`;
the member existed in the previous roster; `not IsSelf(name, guid)`; `previous.online`
and `member.online`; `type(previous.level) == "number"` and `previous.level > 0`;
`type(member.level) == "number"` and `member.level > previous.level`.
Cooldown key `level:<normalizedName>:<newLevel>`, window 1800 seconds.

A login greeting requires **all** of: `db.enabled` and `db.greetLogin`; the member existed
in the previous roster; `not IsSelf(name, guid)`; `not previous.online` and
`member.online`. Cooldown key `login:<normalizedName>`, window `db.loginCooldown`
(default 300 seconds).

Suspicious-read rejection in `OnRosterEvent`: discarded when `count == 0`, or when
`guildCount > 10` and `count < guildCount * 0.7`.

### Alerts.lua (unchanged in 0.2.0)

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:AddAlert` | `(kind, sender, text)` | nil | Appends a private alert at position 1 with an `HH:MM` timestamp, trims to 30, prints locally, optionally plays `SOUNDKIT.TELL_MESSAGE`, refreshes UI and broker. Dedup key `kind:normalizedSender:lowercasedText`, window 120s. Emits nothing to guild chat or a whisper. |
| `A:ScheduleRecipeScan` | `()` | nil | Debounces behind `A.recipeScanPending` and a 0.5-second timer. |
| `A:ScanRecipes` | `()` | nil | Reads `C_TradeSkillUI.GetAllRecipeIDs()`, resolves the profession name when available (falling back to the literal `"Current Profession"`), and builds a fresh cache for that one profession. Only `learned`, non-`disabled`, non-gathering recipes are included; both the link output name and `info.name` are cached when at least 4 characters. |
| `A:MatchCraft` | `(lower: string)` | `string?` | Returns the matched recipe display name or nil. Requires `looksLikeCraftRequest` first, then a plain-substring hit on a cached recipe key. |
| `A:OnGuildChat` | `(message, sender)` | nil | Requires `CanUse`, a sender, and `not IsSelf(sender)`. Cleans escapes, then raises a craft alert on a `MatchCraft` hit and a group alert on a group pattern that is not also a craft request. |

#### File-local matchers (unchanged)

`cleanChat` rewrites `|H...|h[Name]|h` to `Name`, then strips `|cXXXXXXXX` and `|r`.

`looksLikeCraftRequest` is a plain-substring test over twelve phrases: `wtb`,
`can anyone craft`, `can someone craft`, `need crafted`, `looking for crafter`,
`looking for someone to make`, `lf crafter`, `can anyone make`, `can someone make`,
`who can make`, `anyone able to make`, `need someone to make`.

`looksLikeGroupRequest` combines frontier-anchored `lfg`, `lfm`, `lf%d+m`, a leading
`lf%s+`, and the substrings `looking for group`, `looking for more`, `group for`,
`anyone for`, `need a tank`, `need a healer`.

### Tabard.lua (unchanged in 0.2.0)

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:CheckTabard` | `(initial: boolean?)` | nil | Requires `A.db` and `CanUse`. On the first call `A.wasInCity` is nil, so it records the current state and only prompts when `initial` is true. Thereafter prompts only on a transition. |
| `A:ScheduleTabardCheck` | `()` | nil | Debounces behind `A.tabardCheckScheduled` and a 1.2-second timer. |

`inMajorCity()` prefers `C_Map.GetBestMapForUnit("player")` against eight map IDs
(84, 85, 87, 88, 89, 90, 103, 110), falling back to `GetRealZoneText()` against nine
English zone-name keys covering the eight capitals.
`guildTabardEquipped()` checks `GetInventoryItemID("player", 19) == 5976`.

### UI.lua **(three new methods)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildUI` | `()` | nil | **Changed.** Creates `FGCAlertsFrame` (570x440, movable, DIALOG strata) with seven reusable rows, a page indicator, repositioned Prev/Next/Clear/Ask-for-Help buttons, and the **new `Review (n)` shortcut** that opens the review window. Then builds the approvals window and the request window and does a first refresh. Starts hidden. |
| `A:UpdateAlertsUI` | `()` | nil | **Changed.** Now refreshes the `Review (n)` button label from `#A.pendingApprovals` before the early return, so the count stays live even when the rows are not built. Then clamps the page, maps alerts onto the seven rows, and truncates row text over 78 characters. |
| `A:ShowAlerts` | `()` | nil | Refreshes then shows the alerts frame. |
| `A:BuildApprovalsUI` | `()` | nil | **New.** Creates `FGCApprovalsFrame` (625x446, movable, DIALOG strata) titled "Verify Guild Messages", with four reusable rows of a heading, a full-text message label, a `Send` button, and a `Dismiss` button; plus a page indicator, Prev/Next, a `Dismiss all` button, and an empty-state label. Starts hidden. |
| `A:UpdateApprovalsUI` | `()` | nil | **New.** Refreshes the `Review (n)` label, clamps `A.approvalPage` to `ceil(total/4)`, toggles the empty-state label, and maps the backlog onto the four rows four-at-a-time. Each visible row records `row.entryIndex` and shows the `HH:MM` time plus a friendly kind label from `{login="Login greeting", join="New member welcome", level="Level congratulations"}`, defaulting to "Guild message". Unlike the alerts rows, the message text is **not** truncated. |
| `A:ShowApprovals` | `()` | nil | **New.** Refreshes then shows the approvals frame. |
| `A:BuildRequestUI` | `()` | nil | Creates `FGCRequestFrame` (518x390) with the activity edit box (max 100 letters), a Dungeon/Raid/Quest cycling button, "my roles" checkboxes disabled where the class cannot fill the role, "needed roles" checkboxes, a live preview, and Send/Cancel. Starts hidden. |
| `A:RequestText` | `()` | `string` | Renders `db.templates.help` with `activity` (trimmed, or the literal `[activity]`), `type`, `myroles` (default `"Flexible"`), `needed` (default `"Any role"`), and `name`. |
| `A:UpdateRequestPreview` | `()` | nil | Writes `RequestText()` into the preview label. |
| `A:ShowRequest` | `()` | nil | Refreshes the preview then shows the compose frame. |
| `A:SendHelpRequest` | `()` | nil | Requires `CanUse`, a non-empty activity, and 20 seconds since `A.lastManualRequest`; prints a specific reason for each refusal. On success stamps the timestamp and hides the frame. |

The Whisper button on an alert row still calls `ChatFrame_OpenChat("/w " .. sender .. " ")`,
which populates the chat edit box and sends nothing.

**Row index binding**: the approval rows capture `row.entryIndex` at refresh time and
their click handlers pass that index to `A:ApproveMessage` / `A:DismissMessage`. Every
code path that mutates the backlog calls `UpdateApprovalsUI`, which re-binds the indices.
That discipline is what keeps the binding correct; see `code-quality-assessment.md`.

### Options.lua **(changed)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildOptions` | `()` | nil | Prints a note and returns if `Settings.RegisterCanvasLayoutCategory` is missing. Otherwise builds `ForeverGuildCommsOptionsPanel` with a scrolling content frame (height now `max(1200, ...)`), the **new outgoing-mode radio pair**, nine toggles across four sections, four template editors **each with a Use default button and its default text displayed**, three quick-action buttons, and the `OnRefresh` / `OnCommit` / `OnDefault` handlers, then registers the canvas category. |

#### The `outgoingMode` builder **(new)**

Builds two `UIRadioButtonTemplate` check buttons from
`{{key="automatic", title="Automatic"}, {key="verify", title="Verify with a click"}}`.
Each `OnClick` writes `A.db.outgoingMode` and then re-syncs both buttons so they behave
as a mutually exclusive pair. A single refresh closure is registered with the panel's
`controls` list and invoked immediately to set the initial state.

One behavior worth knowing: selecting **Automatic** while the backlog is non-empty prints
`"Earlier pending messages still need approval or dismissal. /fgc verify"`. The mode
switch does not touch those entries.

#### The `template` builder **(changed)**

Per template it now also: seeds the edit box with
`A.db.templates[key] or A.defaults.templates[key]`; adds a **Use default** button that
writes the default into both `A.db.templates[key]` and the edit box, clears focus, and
refreshes the request preview; and renders a `Default: <text>` label beneath the box. The
edit box narrowed from 477 to 363 pixels to make room for the button.

#### Panel callbacks

- `OnRefresh` replays every collected control-sync closure, which now includes the radio
  pair.
- `OnCommit` writes each template edit box back into `A.db.templates` and clears focus.
- `OnDefault` deep-copies `A.defaults` over `A.db` one level down, then refreshes. Note
  that this now also resets `outgoingMode` to `"automatic"`, without the warning the
  radio's own handler prints.

### Broker.lua **(changed)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:TryBroker` | `()` | nil | **Changed.** Idempotent; returns if already created or if `LibStub("LibDataBroker-1.1", true)` yields nothing. Publishes the `ForeverGuildComms` data object with type `data source` and a guild tabard icon. The `OnClick` order is now: right-click opens settings, shift-left opens the help request, **left-click opens the review window when `#A.pendingApprovals > 0`**, otherwise left-click opens alerts. The tooltip gained a **messages-awaiting-approval line** and an **outgoing-mode line**. |
| `A:UpdateBroker` | `()` | nil | **Changed.** Label is now `Guild <online> / <total> | Alerts <count>` plus `| Review <n>` appended only when the backlog is non-empty. |

## Data Models

### Setting record — `A.defaults`, persisted as `ForeverGuildCommsDB` (`A.db`)

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `enabled` | boolean | `true` | Master switch, half of `CanUse` |
| `outgoingMode` | string | `"automatic"` | **New.** `"automatic"` or `"verify"`. Governs only BT-1, BT-2, and BT-3. Normalized on load: anything other than exactly `"verify"` becomes `"automatic"` |
| `greetLogin` | boolean | `true` | Enables BT-1 |
| `greetJoin` | boolean | `true` | Enables BT-2 |
| `congratulateLevel` | boolean | `true` | Enables BT-3 |
| `craftingAlerts` | boolean | `true` | Enables BT-4 |
| `groupAlerts` | boolean | `true` | Enables BT-5 |
| `tabardInCity` | boolean | `true` | Prompt on entering a capital without the tabard |
| `tabardOnExit` | boolean | `false` | Prompt on leaving wearing it. Defaults off as the surprising option |
| `loginCooldown` | number | `300` | Dedup window for login greetings, in seconds. Still has no UI control |
| `messageSpacing` | number | `6` | Requested gap between automatic sends; the queue enforces `max(3, this)`. Still has no UI control |
| `alertsSound` | boolean | `false` | Play a sound on a private alert |
| `templates.login` | string | `"Welcome back, {name}!"` | Supports `{name}`, `{level}` |
| `templates.join` | string | `"Welcome to the guild, {name}!"` | Supports `{name}` |
| `templates.level` | string | `"Congratulations on level {level}, {name}!"` | Supports `{name}`, `{level}` |
| `templates.help` | string | `"[LFG] {type}: {activity}. I can fill: {myroles}. Looking for: {needed}. Whisper me!"` | Supports `{type}`, `{activity}`, `{myroles}`, `{needed}`, `{name}` |

- **Validation**: `fillDefaults` backfills missing keys recursively, which is how
  `outgoingMode` reached existing profiles without disturbing anything else. The mode is
  then coerced to a known value, and nil or whitespace-only templates are refilled from
  defaults while non-empty customizations are preserved. `messageSpacing` passes through
  `tonumber` with a fallback of 6 and a hard floor of 3. Template strings are clamped to
  250 characters in `A:Format`, again in the `QueueGuild` entry builder, and again in
  `A:SendGuild`; edit boxes cap input with `SetMaxLetters(250)`.

### Message entry record **(new shape)** — `A.pendingMessages[i]` and `A.pendingApprovals[i]`

| Field | Type | Meaning |
| --- | --- | --- |
| `text` | string | The rendered message, already clamped to 250 characters |
| `kind` | string | The leading segment of the cooldown key: `"login"`, `"join"`, `"level"`, or the fallback `"message"`. Used only to label the review row |
| `guild` | string? | The guild name captured at composition time. Compared against the current guild before any send; a mismatch discards the entry |
| `time` | string | `HH:MM` capture at composition time, shown in the review row |

**Breaking change from 0.1.0**: `A.pendingMessages` previously held bare strings. Both
lists now hold these records. `A.pendingApprovals` is newest-last (plain
`table.insert`), capped at 30 by removing index 1, and is **not persisted** across a
reload.

Note the asymmetry with `A.alerts`, which is newest-*first* and capped by removing the
last element. The two lists are ordered oppositely; both are capped at 30.

### Per-character record — `ForeverGuildCommsCharDB` (`A.char`)

| Field | Type | Meaning |
| --- | --- | --- |
| `recipes` | `table<professionName, table<lowercaseName, displayName>>` | Known recipe and output names, rebuilt per profession on each scan |
| `myRoles` | `table<role, boolean>` | Which of tank/healer/damage the player offers. Seeded from `A.classRoles[playerClass]` where unset |
| `needRoles` | `table<role, boolean>` | Which roles the player wants to recruit. Empty means any |

### Roster member record — `A.roster[key]`

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Display name as returned by the client |
| `level` | number | Character level; type-checked before any comparison |
| `online` | boolean | Coerced from the client's truthy value |
| `guid` | string | Used for the primary self-exclusion check |

Keyed by `A:Key(name)`. The previous accepted roster is the only input to the diff; there
is no history beyond one generation.

### Private alert record — `A.alerts[i]`

| Field | Type | Meaning |
| --- | --- | --- |
| `kind` | string | `"Craft: <recipeName>"` or `"Group request"` |
| `sender` | string | Guild chat sender, as received |
| `text` | string | The cleaned message body |
| `time` | string | `HH:MM` capture at insert time |

Newest first, hard-capped at 30 by dropping the oldest.

### Cooldown record — `A.eventsSeen[key]`

A flat map from cooldown key to the `A:Now()` timestamp at which the key was last
accepted. Unchanged, and now also applied to Verify-mode messages.

| Kind | Key format | Window |
| --- | --- | --- |
| Login greeting | `login:<normalizedName>` | `db.loginCooldown`, default 300s |
| Guild join | `join:<normalizedName>` | 300s |
| Level-up | `level:<normalizedName>:<level>` | 1800s |
| Private alert | `<kind>:<normalizedSender>:<lowercasedText>` | 120s |

Still never pruned.

## Blizzard API Surface Consumed

Every one of these is feature-detected at the call site, except the frame templates,
which are reached only after the Settings API check.

| API | Used in | Purpose |
| --- | --- | --- |
| `C_Timer.After`, `C_Timer.NewTicker` | Core, Roster, Alerts, Tabard | All deferred and periodic work; no `OnUpdate` anywhere |
| `C_GuildInfo.GuildRoster` | Roster | Request a roster refresh |
| `GetNumGuildMembers`, `GetGuildRosterInfo`, `IsInGuild` | Core, Roster | Roster read and eligibility |
| `GetGuildInfo` | Core, Roster | Guild identity. **Now also called in `QueueGuild`, `DrainQueue`, and `ApproveMessage`** to bind and re-verify each message's guild |
| `ERR_GUILD_JOIN_S` | Roster | Localized guild-join sentence, parsed into a pattern |
| `C_TradeSkillUI.*` | Alerts | Recipe cache construction |
| `C_Map.GetBestMapForUnit`, `GetRealZoneText` | Tabard | City detection, map ID preferred |
| `GetInventoryItemID` | Tabard | Tabard slot check |
| `StaticPopupDialogs`, `StaticPopup_Show`, `ToggleCharacter` | Tabard | Reminder popups and opening the character panel |
| `SendChatMessage` | Core | The single outbound channel, `"GUILD"` only |
| `UnitGUID`, `UnitName`, `GetUnitName`, `UnitFullName`, `UnitClass` | Core | Self-identity and class role defaults |
| `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory` | Core, Options | Modern settings panel |
| `CreateFrame` with `BasicFrameTemplateWithInset`, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`, `UIPanelScrollFrameTemplate`, **`UIRadioButtonTemplate`** | UI, Options, Core | All frames and widgets. The radio template is new in 0.2.0 |
| `ChatFrame_OpenChat` | UI | Populate the chat box for a manual whisper |
| `PlaySound`, `SOUNDKIT.TELL_MESSAGE` | Alerts | Optional alert sound |
| `IsShiftKeyDown` | Broker | Click modifier routing |
| `LibStub` | Broker | Optional LibDataBroker lookup |
| `GetTime`, `date`, `wipe` | Core, Alerts, Roster | Timing, timestamps, table clearing |
