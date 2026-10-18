# Guild chat safety invariants

This addon writes to a shared social channel. Spam, duplicates, or a message sent to the
wrong person is the worst failure mode it has — worse than a missed greeting. Treat every
rule below as a hard invariant and preserve it in any change that touches sending,
roster diffing, or chat parsing.

## Never send without all of these

1. **`A:CanUse()`** — addon enabled *and* `IsInGuild()`.
2. **The feature's own toggle** (`db.greetLogin`, `db.greetJoin`, `db.congratulateLevel`).
3. **Self-exclusion** via `A:IsSelf(name, guid)` — checks GUID first, then the normalized
   name and realm-qualified variants. Never shorten a character name beyond stripping an
   explicit `-Realm` suffix; guildmates can share a first name.
4. **Duplicate suppression** via `A:QueueGuild(message, key, cooldown)`. The key is
   `kind:normalizedName[:detail]`; cooldowns in use are logins `db.loginCooldown` (300s),
   joins 300s, level-ups 1800s, alerts 120s.
5. **The spacing queue** — `A:QueueGuild` → `A:DrainQueue` enforces at least
   `max(3, db.messageSpacing)` seconds between sends. Never call `A:SendGuild` directly
   for automatic messages; direct sends are reserved for explicit user button presses
   (`A:SendHelpRequest`, which additionally rate-limits to one per 20 seconds).

## Roster diffing rules

- The first roster read after login, `/reload`, or a guild change is a **baseline**: it
  updates state and sends nothing. Missing an early transition is preferred over
  greeting everyone at once.
- Login greetings fire only on `offline → online`; level congratulations only on
  `online → online` with a numeric previous level greater than zero and a strictly
  higher new level. Newly seen members never produce a level message.
- Discard suspicious roster reads rather than acting on them: zero members, or a count
  that collapses to under 70% of the known count when the guild has more than 10 members.
- On a guild change, `wipe(A.pendingMessages)` so queued text cannot leak into the new
  guild, and reset `rosterReady` / `roster` / counts.
- Poll the roster at most once per 30 seconds (`A:RequestRoster` throttle) and on a
  60-second ticker. Do not request on every `GUILD_ROSTER_UPDATE`.

## Parsing rules

- Only `CHAT_MSG_GUILD` feeds alert detection, and the sender is dropped if
  `A:IsSelf(sender)`.
- Strip color and hyperlink escapes with the `cleanChat` helper before matching, keeping
  the visible item name.
- Craft alerts require **both** an explicit request phrase and an exact cached
  recipe/output name. Group alerts require a request pattern and must not fire on a
  message already treated as a craft request.
- Guild-join detection must build its pattern from the localized `ERR_GUILD_JOIN_S`
  global, never from a hardcoded English sentence.

## Private vs public

Alerts are **private**: `A:AddAlert` prints to the local chat frame, pushes onto
`A.alerts` (capped at 30), and never emits anything to guild chat or a whisper. Whispering
requires the user to click, and it only opens the chat edit box via `ChatFrame_OpenChat`;
it does not send.

When adding a new automatic message, state in the PR/commit description which cooldown
key it uses and why the chosen window is right.
