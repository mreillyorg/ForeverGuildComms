# API Documentation

**Analysis target**: Forever Guild Comms **0.4.1-beta**
**Supersedes**: the 0.2.0-beta pass of 2026-10-19T00:52:00Z
New or changed entries are marked **new** or **changed**.

## REST APIs

None. No HTTP surface, no network calls at runtime. The only outbound channel of any kind
is `SendChatMessage(message, "GUILD")`.

## User-Facing Command API

`SLASH_FOREVERGUILDCOMMS1 = "/fgc"`, `SLASH_FOREVERGUILDCOMMS2 = "/guildcomms"`. Input is
lowercased and trimmed; the handler returns early with a printed note if `A.initialized`
is false. Unchanged in this span.

| Command | Aliases | Behaviour |
| --- | --- | --- |
| `/fgc` | `/guildcomms` | Falls through to the alerts window |
| `/fgc alerts` | - | `A:ShowAlerts` |
| `/fgc verify` | `/fgc review` | `A:ShowApprovals` |
| `/fgc options` | `/fgc settings` | `A:OpenSettings` |
| `/fgc request` | `/fgc help` | `A:ShowRequest` |
| `/fgc status` | - | Counts, pending review depth, current mode |
| `/fgc recipes` | - | Cached learned recipe-name count |
| `/fgc clearrecipes` | - | `wipe(A.char.recipes)` plus confirmation |

## Key Binding API **(new in 0.4.1)**

Declared in `Bindings.xml`, which the client **auto-loads from the addon root** and which
must not appear in the TOC. Labels come from four globals set at the top of `Core.lua`.

| Binding name | Label global | Visible label | Action |
| --- | --- | --- | --- |
| - | `BINDING_HEADER_FOREVERGUILDCOMMS` | Forever Guild Comms | Category header |
| `FGC_OPEN_ALERTS` | `BINDING_NAME_FGC_OPEN_ALERTS` | Open guild alerts | `RunQuickAction("alerts")` |
| `FGC_ASK_HELP` | `BINDING_NAME_FGC_ASK_HELP` | Ask guild for help | `RunQuickAction("help")` |
| `FGC_RESCAN_PROFESSION` | `BINDING_NAME_FGC_RESCAN_PROFESSION` | Rescan open profession | `RunQuickAction("rescan")` |

Each body is a single guarded call:

```lua
if ForeverGuildComms then ForeverGuildComms:RunQuickAction("alerts") end
```

**Contract**: no binding carries a `default=` attribute, so the addon claims no key until
the player assigns one. No binding can reach `A:SendGuild`. `tests/keybindings.lua`
asserts both properties, the second by stubbing `SendChatMessage` and requiring the call
count to stay at zero across every action.

## Internal APIs

62 `function A:` definitions on the shared table, published once as
`_G.ForeverGuildComms`.

### Core.lua — identity, formatting, and encoding

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:Print` | `(s: any)` | nil | Prints behind the coloured addon tag |
| `A:Key` | `(name: any)` | `string` | Lowercase, trim, collapse whitespace. `""` for non-strings |
| `A:IsSelf` | `(name: string?, guid: string?)` | `boolean` | GUID first, then normalized name against `A.selfKeys`, then the name with only an explicit `-Realm` suffix removed |
| `A:ChatLimit` | `(text: any)` | `string` | **New.** Truncates to 250 **bytes** without splitting a UTF-8 character: from byte 251, walk back while the byte is a continuation byte (`>= 128 and < 192`), then cut. Added because translations introduced multibyte text |
| `A:Format` | `(template: any, vars: table?)` | `string` | **Changed.** Substitutes `{alpha}` placeholders, leaving unknown ones literal, then applies `ChatLimit` instead of a raw `sub(1, 250)` |
| `A:CommsText` | `(kind: string, vars: table?)` | `string` | **New.** The voice indirection. Delegates to `A:VoiceText` when the voice modules are loaded, otherwise formats `A.db.templates[kind]` directly. This is what makes the three voice modules optional |
| `A:CanUse` | `()` | `boolean` | `A.db.enabled` and `IsInGuild()` |
| `A:Now` | `()` | `number` | `GetTime()` or `0` |
| `A:IsDuplicate` | `(key: string, cooldown: number?)` | `boolean` | True if seen within the window; otherwise records the key. Note the side effect |
| `A:RoleText` | `(roles: table?, noneText: string?)` | `string` | Untranslated role labels joined with `/` |

### Core.lua — the send pipeline

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:SendGuild` | `(message: string)` | `boolean` | **Changed.** Still the only `SendChatMessage` caller; now clamps with `ChatLimit` rather than `sub` |
| `A:QueueGuild` | `(message, key, cooldown?)` | nil | **Changed.** Entry `text` now built with `ChatLimit`. Otherwise as 0.2.0: `CanUse`, non-empty string, `IsDuplicate`, build a `{text, kind, guild, time}` record, then branch on `outgoingMode` |
| `A:DrainQueue` | `()` | nil | Unchanged. Spacing is `max(3, messageSpacing)`; the timer re-checks `CanUse`, guild identity, and the mode |
| `A:StageApproval` | `(entry: table)` | nil | Unchanged. Caps the backlog at 30 by dropping index 1 |
| `A:ApproveMessage` | `(index: number)` | nil | Unchanged. Re-checks `CanUse` and the recorded guild; sends directly with no spacing |
| `A:DismissMessage` | `(index: number)` | nil | Unchanged |
| `A:ClearApprovals` | `()` | nil | Unchanged |

### Core.lua — settings validation **(all new in 0.3.0/0.4.0)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:NormalizeTiming` | `(key, value, fallback?)` | `number?` | Clamps and rounds a timing value. Returns nil for an unknown key. Rejects non-numbers, NaN, and both infinities by substituting `fallback` or the shipped default, then rounds with `floor(n + 0.5)` and clamps to the key's `min`/`max` |
| `A:RefreshOptions` | `()` | nil | Replays the Settings panel's `OnRefresh` if the panel exists, so a write from any surface re-syncs visible controls |
| `A:SetOption` | `(key, value)` | `boolean` | **The only account-settings writer.** Rejects unknown keys. `outgoingMode` must be `"automatic"` or `"verify"`; timing keys pass through `NormalizeTiming`; boolean-defaulted keys require a boolean; **everything else is refused**, which is how template text is kept out of the Titan menu. On an actual change it prints the pending-approval reminder when switching to automatic, then refreshes the panel and broker |
| `A:VoiceOptionLabel` | `(key, id)` | `string` | Display label for a voice value: language name, accent label (with `auto` and `none` special-cased), or strength name |
| `A:SetVoiceOption` | `(key, value)` | `boolean` | **The only per-character voice writer.** Validates `language` against `languageByID`, `accent` against the currently available list (with `auto`/`none` always allowed), `accentStrength` against the three-value enum, and `raceFilter` as a boolean. After a `language` or `raceFilter` change it revalidates the chosen accent and reverts to `auto` if it is no longer available. Then refreshes options, the request preview, and the broker |
| `A:VoiceChoices` | `(key)` | `table` | The option list for a voice key: languages, available accents, or the three strengths |

#### Timing limits

| Key | Min | Max | Default |
| --- | --- | --- | --- |
| `messageSpacing` | 3 | 120 | 6 |
| `loginCooldown` | 0 | 3600 | 300 |

`loginCooldown = 0` is meaningful: it disables the repeat-login cooldown, and the Titan
menu labels it "Off (every detected login)".

### Core.lua — quick actions **(new in 0.4.1)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:RunQuickAction` | `(action: string)` | nil | Single dispatcher for the Titan menu, key bindings, and any future shortcut. Returns immediately unless `A.initialized`. Handles `"alerts"` (`ShowAlerts`), `"help"` (`ShowRequest`, composer only), and `"rescan"` (calls `ScanRecipes` and prints either a confirmation or a prompt to open a profession first) |

**Contract**: no branch sends guild chat. The source comment states it: "None of these
actions sends guild chat; help only opens the composer."

### Core.lua — settings navigation and startup

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:OpenSettings` | `(section: string?)` | nil | **Changed.** Opens the category, then for `section == "messages"` or `"languages"` defers a `SetVerticalScroll` through `C_Timer.After(0, ...)` to the matching anchor, because the panel is displayed asynchronously. Prints a fallback note when the Settings API is absent |
| `A:Initialize` | `()` | nil | **Changed.** Idempotent. Beyond the 0.2.0 behaviour it now also: clamps both timing values through `NormalizeTiming` as a migration; creates and backfills `A.char.voice` from `A.voiceDefaults`; forces an unknown language to `"en"`; forces an unknown `accentStrength` to `"subtle"`; forces a non-boolean `raceFilter` to `true`; and reverts the accent to `"auto"` if it is not in the available list |

Migration sequence in `A:Initialize`, in order: `fillDefaults`, mode coercion, blank
template refill, **timing clamp**, then **voice table creation and validation**, then
identity and class roles, then the guarded module hooks.

### Languages.lua — data only (zero methods) **(new)**

| Table | Shape | Contents |
| --- | --- | --- |
| `A.languages` | array of `{id, label}` | 8 entries: `en`, `es`, `fr`, `de`, `it`, `pt`, `pl`, `nl` |
| `A.languageByID` | `id -> label` | Derived from the above at load |
| `A.localeTemplates` | `lang -> {login, join, level, help}` | Curated translations of the four built-in templates. The `en` entry aliases `A.defaults.templates`, which is why this file must load after `Core.lua` |
| `A.localeRoleNames` | `lang -> {tank, healer, damage, flexible, any}` | Localized role labels and the two fallback words |
| `A.localeActivityTypes` | `lang -> {Dungeon, Raid, Quest}` | Localized activity names |

The header comment is explicit that these are offline curated translations, not a
machine-translation service, and that they never rewrite a custom message or guild chat.

### Accents.lua — data only (zero methods) **(new)**

| Table | Shape | Contents |
| --- | --- | --- |
| `A.accents` | `id -> {id, label, language, text={login,join,level,help}, flair}` | 29 styles, populated by a file-local `register(id, label, lang, login, join, level, help, flair)` |
| `A.accentOrder` | array of ids | Stable presentation order, independent of table iteration |

Distribution by language: **21 English** (8 regional human: australian, british, american,
scottish, irish, canadian, newzealand, southafrican; 13 WoW-race RP: dwarf, wildhammer,
darkiron, gnome, nightelf, orc, troll, tauren, forsaken, skyborne, goblin, bloodelf,
draenei), **3 Spanish** (mexican, cuban, spanish), **1 French** (quebec), **1 German**
(bavarian), **2 Portuguese** (brazilian, portuguese), **1 Italian** (southernitalian).

The header comment records the design boundary: phrase-level styles only, no global chat
hooks, no rewriting of arbitrary text, names, hyperlinks, colours, or variables, and the
variants are creative RP flavour rather than phonetic claims about real people.

### RaceProfiles.lua — the voice layer **(new)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:GetPlayerRace` | `()` | `string` | Reads `UnitRace("player")` for the locale-independent token, falling back to the localized name then `"Unknown"`. Probes both for a case-insensitive `skyborne` substring and returns `"Skyborne"` if found, because the Forever client may not publish that race's token |
| `A:GetAvailableAccents` | `()` | `array of {id, label}` | Always starts with `auto` and `none`. Walks `accentOrder` and includes a style when its `language` matches the selected language and, if `raceFilter` is on, when it is in `raceAccents[GetPlayerRace()]`. A Human additionally gets the eight regional non-English variants, so a Spanish-speaking Human sees the Mexican, Cuban, and Spain styles |
| `A:ResolveAccent` | `()` | `table?` | nil for `none`. For `auto`, walks `raceAccents` for the player's race and returns the first style that is still in the available list, else nil. Otherwise returns the chosen style if still valid, else nil |
| `A:VoiceText` | `(kind, vars)` | `string` | The core rule. Returns `""` if the template is missing. **If the stored template differs from the shipped default, formats it verbatim and returns** — the player's text always wins. Otherwise takes `localeTemplates[lang][kind]`, overlays the resolved accent's phrase for that kind, applies flair by strength (never for `help`), then `Format`s |
| `A:LocalizeRoleText` | `(roles, fallback)` | `string` | Joins localized role labels with `/`, falling back to the localized word for `flexible` or `any` |
| `A:LocalizeActivityType` | `(kind)` | `string` | Localized `Dungeon`/`Raid`/`Quest`, falling back to the input |

#### Accent strength semantics

| Strength | Effect |
| --- | --- |
| `subtle` | The style's phrasing only. **No flair prefix at all** |
| `moderate` | Prepends `accent.flair` |
| `expressive` | Prepends `accent.flair`, then intensifies terminal punctuation: a trailing `!` is doubled, a trailing `.` becomes `!` |

Flair is never applied when `kind == "help"`, so an `[LFG]` line is never prefixed with an
interjection.

### Roster.lua **(changed: three call sites)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:RequestRoster` | `(force?)` | nil | 30-second throttle unless forced; feature-detects `C_GuildInfo.GuildRoster` |
| `A:ReadRoster` | `()` | `members, count, online` | Keyed by `A:Key(name)` with `{name, level, online, guid}` |
| `A:AcceptRoster` | `(members, count, online, baseline)` | nil | **Changed.** The level and login messages are now built with `A:CommsText` instead of `A:Format`. All diff conditions are unchanged |
| `A:CaptureBaseline` | `()` | nil | Commits the first read with `baseline=true`; retries after 4s on an empty read |
| `A:OnRosterEvent` | `(event)` | nil | Guild-change reset wipes `pendingMessages` and calls `ClearApprovals`; schedules a baseline when not ready; discards suspicious reads |
| `A:OnSystemGuildJoin` | `(message)` | nil | **Changed.** Pattern built from the escaped `ERR_GUILD_JOIN_S`; the welcome is now built with `A:CommsText` |
| `A:SetupRoster` | `()` | nil | Immediate and 5s `OnRosterEvent`, then a 60s ticker calling `RequestRoster` |

Diff conditions (unchanged). Level-up requires `db.enabled`, `db.congratulateLevel`, the
member existed previously, `not IsSelf`, both online, a numeric previous level above zero,
and a strictly higher numeric new level; key `level:<name>:<level>`, window 1800s. Login
requires `db.enabled`, `db.greetLogin`, the member existed previously, `not IsSelf`,
previously offline and now online; key `login:<name>`, window `db.loginCooldown`.
Suspicious reads are discarded when `count == 0`, or `guildCount > 10` and
`count < guildCount * 0.7`.

### Alerts.lua **(one changed signature)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:AddAlert` | `(kind, sender, text)` | nil | Private alert at position 1 with an `HH:MM` stamp, trimmed to 30, printed locally, optional sound. Dedup `kind:sender:text`, 120s |
| `A:ScheduleRecipeScan` | `()` | nil | 0.5s debounce behind `A.recipeScanPending` |
| `A:ScanRecipes` | `()` | **`boolean`** | **Changed.** Returns `false` on each early exit (no `char`, no `C_TradeSkillUI`, no `GetAllRecipeIDs`, or an empty/non-table id list) and `true` after a completed pass. Lets `RunQuickAction` report the real outcome instead of an unconditional optimistic message |
| `A:MatchCraft` | `(lower)` | `string?` | Requires a craft request phrase, then a plain-substring hit on a cached recipe key |
| `A:OnGuildChat` | `(message, sender)` | nil | Requires `CanUse`, a sender, `not IsSelf`; cleans escapes; raises craft and group alerts under their toggles |

### Tabard.lua (unchanged since 0.1.0)

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:CheckTabard` | `(initial?)` | nil | Records state on the first call and only prompts when `initial`; thereafter prompts on a transition under the relevant toggle |
| `A:ScheduleTabardCheck` | `()` | nil | 1.2s debounce |

### UI.lua **(one changed method)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildUI` | `()` | nil | `FGCAlertsFrame`, seven rows, paging, the `Review (n)` shortcut |
| `A:UpdateAlertsUI` | `()` | nil | Refreshes the review count, clamps the page, maps alerts onto rows, truncates over 78 chars |
| `A:ShowAlerts` | `()` | nil | Refresh then show |
| `A:BuildApprovalsUI` | `()` | nil | `FGCApprovalsFrame`, four rows with Send and Dismiss, paging, Dismiss all, empty state |
| `A:UpdateApprovalsUI` | `()` | nil | Clamps the page, toggles the empty label, binds `row.entryIndex`, labels rows from the entry `kind` |
| `A:ShowApprovals` | `()` | nil | Refresh then show |
| `A:BuildRequestUI` | `()` | nil | `FGCRequestFrame`: activity box (100 chars), type cycler, role checkboxes, preview, Send and Cancel |
| `A:RequestText` | `()` | `string` | **Changed.** Computes `custom = db.templates.help ~= defaults.templates.help`. When custom, uses the raw activity type and `A:RoleText`; otherwise uses `A:LocalizeActivityType` and `A:LocalizeRoleText`. Routes through `A:CommsText("help", ...)`. So a customized help template keeps English labels, matching the template the player actually wrote |
| `A:UpdateRequestPreview` | `()` | nil | Writes `RequestText()` into the preview |
| `A:ShowRequest` | `()` | nil | Refresh then show |
| `A:SendHelpRequest` | `()` | nil | Requires `CanUse`, a non-empty activity, and 20s since the last manual request |

### Options.lua **(substantially extended)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:BuildOptions` | `()` | nil | Returns with a printed note if `Settings.RegisterCanvasLayoutCategory` is missing. Builds the canvas panel with the addon icon, the Automatic/Verify radio pair, nine toggles, **numeric timing fields**, four template editors with Use default buttons and default text, **a Languages and accents section with language, accent, race filter, strength, and a live preview**, quick-action buttons, and the panel callbacks. Publishes `A.optionsPanel`, `A.optionsScroll`, `A.messagesScrollY`, and `A.languagesScrollY` for deep linking, then registers the category |

Panel callbacks: `OnRefresh` replays every control closure; `OnCommit` writes template
edit boxes back; `OnDefault` **now also resets `A.char.voice` from `A.voiceDefaults`** in
addition to copying `A.defaults` one level deep over `A.db`.

### TitanMenu.lua **(new)**

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:PopulateTitanMenu` | `(root)` | nil | Builds the tree: title with version, enable toggle, Outgoing guild messages (mode radios, three event toggles, spacing and cooldown preset submenus each with a reset), Private guild requests (three toggles), **Languages & accents** (language, accent, race filter showing the detected race, strength, and a Settings shortcut), Guild tabard (two toggles), Quick actions (review, alerts, help, rescan), and Settings shortcuts |
| `A:OpenTitanMenu` | `(owner)` | nil | Requires `MenuUtil.CreateContextMenu`; otherwise prints a note and opens Settings. Substitutes `UIParent` when the owner is absent or lacks `GetObjectType`, because an LDB consumer may pass the data object instead of its button frame |

File-local helpers: `SecondsText` (renders `0` as "Off (every detected login)", values under
60 as seconds, otherwise minutes), `AddSetting` (a checkbox bound to `A:SetOption`),
`AddTiming` (a preset submenu plus reset, also bound to `A:SetOption`).

Presets: spacing `{3, 6, 10, 15, 30, 60, 120}`, cooldown `{0, 60, 300, 600, 900, 1800, 3600}`.

**Contract**: every write goes through `A:SetOption` or `A:SetVoiceOption`. The menu
deliberately cannot edit template text and offers "Edit custom messages in Settings..."
instead.

### Broker.lua (unchanged)

| Method | Signature | Returns | Purpose |
| --- | --- | --- | --- |
| `A:TryBroker` | `()` | nil | Publishes the LDB object with the shared icon path; click routing is right-click settings, shift-left help, left review when pending else alerts; tooltip reports counts, pending reviews, and mode |
| `A:UpdateBroker` | `()` | nil | `Guild <online> / <total> | Alerts <n>` plus `| Review <n>` when the backlog is non-empty |

## Data Models

### Account settings — `A.defaults`, persisted as `ForeverGuildCommsDB` (`A.db`)

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `enabled` | boolean | `true` | Half of `CanUse` |
| `outgoingMode` | string | `"automatic"` | `"automatic"` or `"verify"`; coerced on load |
| `greetLogin` | boolean | `true` | BT-1 |
| `greetJoin` | boolean | `true` | BT-2 |
| `congratulateLevel` | boolean | `true` | BT-3 |
| `craftingAlerts` | boolean | `true` | BT-4 |
| `groupAlerts` | boolean | `true` | BT-5 |
| `tabardInCity` | boolean | `true` | BT-6 |
| `tabardOnExit` | boolean | `false` | Conservative default |
| `loginCooldown` | number | `300` | **Now reachable from both UIs.** Clamped 0-3600 |
| `messageSpacing` | number | `6` | **Now reachable from both UIs.** Clamped 3-120 |
| `alertsSound` | boolean | `false` | Private alert sound |
| `templates.login` | string | `"Welcome back, {name}!"` | `{name}`, `{level}` |
| `templates.join` | string | `"Welcome to the guild, {name}!"` | `{name}` |
| `templates.level` | string | `"Congratulations on level {level}, {name}!"` | `{name}`, `{level}` |
| `templates.help` | string | `"[LFG] {type}: {activity}. I can fill: {myroles}. Looking for: {needed}. Whisper me!"` | `{type}`, `{activity}`, `{myroles}`, `{needed}`, `{name}` |

**Validation**: `fillDefaults` backfills recursively; the mode is coerced; blank templates
are refilled; **both timing values are clamped through `NormalizeTiming` as a migration**,
so a hand-edited or out-of-range saved value is corrected on load. Text is clamped to 250
bytes at four points, all now UTF-8-aware via `ChatLimit`.

### Per-character voice **(new)** — `A.char.voice`, defaults in `A.voiceDefaults`

| Field | Type | Default | Domain |
| --- | --- | --- | --- |
| `language` | string | `"en"` | Any key in `A.languageByID` |
| `accent` | string | `"none"` | `"auto"`, `"none"`, or an id from `GetAvailableAccents()` |
| `raceFilter` | boolean | `true` | Restricts the accent list to the player's race |
| `accentStrength` | string | `"subtle"` | `"subtle"`, `"moderate"`, `"expressive"` |

Backfilled with `fillDefaults` and then individually revalidated in `A:Initialize`. The
defaults deliberately reproduce 0.3.0 output, so upgrading changes nothing.

### Per-character record — `ForeverGuildCommsCharDB` (`A.char`)

| Field | Type | Meaning |
| --- | --- | --- |
| `voice` | table | **New.** The four voice selections above |
| `recipes` | `table<profession, table<lowerName, displayName>>` | Known recipe and output names |
| `myRoles` | `table<role, boolean>` | Roles the player offers |
| `needRoles` | `table<role, boolean>` | Roles the player wants |

### Message entry record — `A.pendingMessages[i]` and `A.pendingApprovals[i]`

| Field | Type | Meaning |
| --- | --- | --- |
| `text` | string | Rendered message, clamped to 250 bytes on a character boundary |
| `kind` | string | Leading segment of the cooldown key: `login`, `join`, `level`, or `message` |
| `guild` | string? | Guild captured at composition time; re-verified before any send |
| `time` | string | `HH:MM` at composition |

`pendingApprovals` is newest-last, capped at 30 by dropping index 1, and not persisted.
`alerts` is newest-first, capped at 30 by dropping the last. The two are ordered
oppositely.

### Roster member record — `A.roster[key]`

`{name, level, online, guid}`, keyed by `A:Key(name)`. One generation of history only.

### Private alert record — `A.alerts[i]`

`{kind, sender, text, time}`. `kind` is `"Craft: <recipeName>"` or `"Group request"`.

### Cooldown record — `A.eventsSeen[key]`

Flat map from cooldown key to timestamp. Still never pruned.

| Kind | Key format | Window |
| --- | --- | --- |
| Login greeting | `login:<normalizedName>` | `db.loginCooldown`, default 300s, `0` disables |
| Guild join | `join:<normalizedName>` | 300s |
| Level-up | `level:<normalizedName>:<level>` | 1800s |
| Private alert | `<kind>:<normalizedSender>:<lowercasedText>` | 120s |

## Blizzard API Surface Consumed

| API | Used in | Purpose |
| --- | --- | --- |
| `C_Timer.After`, `C_Timer.NewTicker` | Core, Roster, Alerts, Tabard | All deferred and periodic work; also the deferred Settings scroll |
| `C_GuildInfo.GuildRoster` | Roster | Roster refresh request |
| `GetNumGuildMembers`, `GetGuildRosterInfo`, `IsInGuild` | Core, Roster | Roster read and eligibility |
| `GetGuildInfo` | Core, Roster | Guild identity; also binds and re-verifies each message's guild |
| `ERR_GUILD_JOIN_S` | Roster | Localized join sentence, escaped into a pattern |
| `C_TradeSkillUI.*` | Alerts | Recipe cache construction |
| `C_Map.GetBestMapForUnit`, `GetRealZoneText` | Tabard | City detection |
| `GetInventoryItemID` | Tabard | Tabard slot check |
| `StaticPopupDialogs`, `StaticPopup_Show`, `ToggleCharacter` | Tabard | Reminder popups |
| `SendChatMessage` | Core | The single outbound channel, `"GUILD"` only |
| `UnitGUID`, `UnitName`, `GetUnitName`, `UnitFullName`, `UnitClass` | Core | Self-identity and class roles |
| **`UnitRace`** | RaceProfiles | **New.** Race token for accent filtering, with Skyborne probing |
| `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory` | Core, Options | Settings panel |
| **`MenuUtil.CreateContextMenu`** | TitanMenu | **New.** Nested menu, feature-detected with a Settings fallback |
| `CreateFrame` with `BasicFrameTemplateWithInset`, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `UIRadioButtonTemplate`, `InputBoxTemplate`, `UIPanelScrollFrameTemplate` | UI, Options, Core | Frames and widgets |
| **`Bindings.xml` plus `BINDING_HEADER_*` / `BINDING_NAME_*`** | Core, Bindings.xml | **New.** Key binding declaration and labels |
| `ChatFrame_OpenChat` | UI | Populates the chat box for a manual whisper |
| `PlaySound`, `SOUNDKIT.TELL_MESSAGE` | Alerts | Optional alert sound |
| `IsShiftKeyDown` | Broker | Click modifier routing |
| `LibStub` | Broker | Optional LibDataBroker lookup |
| `GetTime`, `date`, `wipe` | Core, Alerts, Roster | Timing, timestamps, table clearing |
