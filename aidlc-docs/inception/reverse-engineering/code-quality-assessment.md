# Code Quality Assessment

## Summary

The codebase is small (882 shipped Lua lines), internally consistent, and unusually
disciplined about its own failure modes. Its stated risk model — that a duplicate or
misdirected guild message is worse than a missed greeting — is visibly enforced in code
through a single send path, layered guards, and deliberate lossiness. The documentation
is honest about what has not been verified.

The weak points are all in verification coverage rather than design: four of seven
modules have no automated test path, the send queue itself is stubbed out of the one test
file, and there is no CI. There is also a small amount of unreachable configuration and
one latent ordering issue in the tabard feature.

## Test Coverage

- **Overall**: Fair. Strong on the safety-critical logic, absent elsewhere.
  This rating comes from reading the harness, not from running it: no Lua interpreter is
  installed on this machine, so the suite was not executed during this pass.
- **Unit Tests**: One offline harness, `tests/smoke.lua`, 72 lines. It stubs the client
  globals it needs, loads `Core.lua`, `Roster.lua`, and `Alerts.lua` via
  `loadfile(...)("ForeverGuildComms", A)`, and asserts against fake tables. It dies on the
  first failed `assert` and prints a `PASSED` summary otherwise.
- **Integration Tests**: None.
- **Performance Tests**: None, and not warranted.
- **Manual verification**: A ten-step in-game checklist is the only path for the four
  modules that cannot load offline.

### What the harness locks down

Notably, each case asserts both the positive outcome and the corresponding "must not
fire" outcome, which is the right shape for this product:

| Invariant | Positive case | Negative case |
| --- | --- | --- |
| Self level-up silence | Bob's level-up queues one message | Hero's own level-up queues nothing |
| Login greeting | Alice offline to online queues one greeting | - |
| Guild join | Localized join line queues one welcome | Hero's own join queues nothing |
| Craft detection | Request naming a cached recipe alerts | - |
| Group detection | `LFG Deadmines` alerts | Hero's own guild chat does not alert |
| Recipe cache | A learned recipe enters the cache | An unlearned recipe does not |

### Coverage gaps, ranked

1. **The send queue has no automated coverage.** `smoke.lua` replaces `A.QueueGuild` with
   a stub that appends to a local table. This is the correct way to observe the diff, but
   it means `QueueGuild`'s dedup call, `DrainQueue`'s spacing arithmetic, the
   `wipe(pendingMessages)` path when `CanUse` turns false, and `SendGuild`'s clamp and
   `pcall` are all untested. These four functions are the single most safety-critical
   code in the project.
2. **`A:IsDuplicate` is untested.** Because `QueueGuild` is stubbed, no test exercises the
   cooldown windows (300s logins, 300s joins, 1800s level-ups, 120s alerts). The
   `GetTime` stub increments by one per call, which would make writing these tests
   straightforward.
3. **`A:IsSelf` realm handling is untested.** The harness covers GUID and plain-name
   matching, but not the `-Realm` suffix branch or the `GetUnitName` / `UnitFullName`
   variants collected into `A.selfKeys`.
4. **The suspicious-roster-read guard is untested.** Neither the `count == 0` rejection
   nor the "collapsed below 70% when over 10 members" rejection has a test, despite both
   being explicit anti-spam protections.
5. **The guild-change path is untested.** `OnRosterEvent`'s reset and
   `wipe(self.pendingMessages)` on a guild change is a stated invariant with no coverage.
6. **Four modules have no offline path at all**: `UI.lua`, `Options.lua`, `Tabard.lua`,
   `Broker.lua`. `Tabard.lua` is the most testable of these — `inMajorCity` and
   `guildTabardEquipped` need only `C_Map`, `GetRealZoneText`, and `GetInventoryItemID`
   stubs, and `CheckTabard`'s transition logic is pure state machine. It is a candidate
   for the harness without restructuring.

## Code Quality Indicators

- **Linting**: Not configured. No `.luacheckrc`, no formatter config. The upstream AI-DLC
  archive carries a `.markdownlint-cli2.yaml`, but that is not part of this project.
- **Code Style**: Consistent. 4 spaces, no tabs, no trailing whitespace, lines under
  roughly 100 characters, `{key=value}` table constructors for compact data and one entry
  per line for config. Methods are `PascalCase`, state and locals `camelCase`. The style
  is codified in `.kiro/steering/lua-style.md` and the code matches it throughout; the
  consistency appears to be maintained by convention rather than tooling.
- **Documentation**: Good. The README covers install, features, commands, templates, a
  suggested test sequence, and a frank limitations section. Eight steering documents
  record the product's non-goals, safety invariants, client constraints, and conventions.
  Code comments are sparse and explain *why* a guard exists rather than what a line does
  — the realm-suffix note in `A:IsSelf`, the incomplete-roster guard in `OnRosterEvent`,
  the item-5976 note in `Tabard.lua`, the fresh-cache note in `ScanRecipes`.
- **Error handling**: Good. The one call that can genuinely fail, `SendChatMessage`, is
  wrapped in `pcall` with the error surfaced through `A:Print`. Every Blizzard API is
  feature-detected before use. External data is type-checked before use
  (`type(message) ~= "string"`, `type(previous.level) == "number"`).
- **Global hygiene**: Good. Exactly one namespace global (`_G.ForeverGuildComms`), two
  `SLASH_*` variables, one `SlashCmdList` entry, three named frames, and two popup keys.
  No `getglobal`, no `loadstring`, no `/run`-style string loading.
- **Control flow**: Good. Early-return guards throughout, little nesting. `A:BuildOptions`
  is the deepest function but its nesting is closure definitions, not branching.

## Technical Debt

### Dead state
- **`A.lastMessages = {}`** (`Core.lua:32`) is declared and never read or written
  anywhere in the codebase, including the test harness. `A.eventsSeen` performs the
  duplicate-tracking role it was presumably intended for. Safe to remove.

### Unreachable configuration
- **`messageSpacing` and `loginCooldown` have no UI control.** Both are account settings
  in `A.defaults` and both are consumed by code (`DrainQueue` and the login cooldown key
  respectively), but `Options.lua` builds nine toggles and four template edit boxes and
  no numeric inputs. A user cannot change either value without editing the SavedVariables
  file by hand.
- **A hardcoded options label can drift from behavior.** `Options.lua` states
  "Automatic messages are queued at least 6 seconds apart." That is correct for the
  default, but `DrainQueue` computes `max(3, db.messageSpacing)`, so the label would be
  wrong for any other value. Deriving the text from `A.db.messageSpacing` would keep it
  honest, and is more worthwhile if a control is added.

### Latent ordering issue in the tabard reminder
`A:Initialize` schedules `CheckTabard(true)` at 3 seconds. `PLAYER_ENTERING_WORLD` also
fires around login and routes to `ScheduleTabardCheck`, which runs `CheckTabard(false)`
at 1.2 seconds. On the 1.2-second call `A.wasInCity` is nil, so the function records the
current state and returns without prompting because `initial` is false. By the time the
3-second call arrives, `before == nowCity`, so it returns early too.

The consequence is that the "you logged in already standing in a capital city without
your tabard" prompt is likely never shown, which is precisely the case the `initial`
parameter exists to handle. Zone-transition prompts after login are unaffected.

This is inferred from reading the code and the event registrations; the actual firing
order of `PLAYER_LOGIN` versus `PLAYER_ENTERING_WORLD` and the timer resolution in the
live Forever client have **not** been verified. It should be confirmed in game before
being treated as a defect. The straightforward fix would be to have the initial check
own the first observation, for example by not letting the debounced path populate
`A.wasInCity` until the initial check has run.

### Degradation path in the recipe cache
`ScanRecipes` resolves the profession name through
`C_TradeSkillUI.GetProfessionChildSkillLineID` and
`GetProfessionInfoBySkillLineID`, and falls back to the literal string
`"Current Profession"` when either is missing. Because the function then assigns
`self.char.recipes[profession] = known` — a fresh table for one profession — a client
where the skill-line APIs are absent collapses every profession into that one bucket, so
each scan overwrites the previous profession's recipes and only the most recently opened
profession stays cached. Craft alerts would silently narrow to one profession.

This is a graceful degradation rather than a crash, and the harness exercises exactly
this fallback bucket. It is worth a note in the README limitations section, since the
user-visible symptom (some known recipes stop matching) is hard to attribute.

### Unbounded session growth in `A.eventsSeen`
Cooldown keys are written and never pruned. The alert key embeds the full lowercased
message text, so a busy guild produces a new key for every distinct request line. Growth
is bounded by session length and the table holds only short strings against numbers, so
the practical memory cost is small, but a long-lived session accumulates entries that can
never match again. A sweep of expired keys during `DrainQueue` or on a timer would bound
it.

### Minor convention inconsistency
`A.GetActivityType` is assigned as a plain closure inside `BuildRequestUI`
(`self.GetActivityType = function() ... end`) and called as `self.GetActivityType()` with
a dot rather than a colon. Every other public entry point on `A` is a
`function A:Method()` definition. Functionally fine, since it closes over `currentType`
and `types`, but it is the one place the module pattern is not followed.

### Shallow copy in `OnDefault`
`Options.lua`'s restore-defaults handler copies `A.defaults` one level deep: table values
get a fresh table and their immediate children are copied. This is correct for the
current shape, where `templates` is the only nested table and it is flat. Any future
default nested two levels deep would be shared by reference with `A.defaults`, letting a
user edit corrupt the defaults table for the session. `fillDefaults` already recurses
properly and could be reused here.

### No CI
Nothing runs the harness automatically. The pre-release checklist in
`.kiro/steering/release-packaging.md` is a manual gate: offline tests print `PASSED`,
version strings match in three places, every source file is in the TOC in the right
order, the README reflects the code, and the in-game checklist has been walked or the
gaps written down. A single script that runs the harness and verifies the three version
strings agree would remove the most error-prone items from that list.

## Patterns and Anti-patterns

### Good Patterns

- **Single outbound chat path.** Every automatic message goes `QueueGuild` to
  `DrainQueue` to `SendGuild`. One place to audit, one place to add a guard. The one
  bypass is explicit, user-initiated, and separately rate-limited.
- **Single event dispatcher.** 14 events on one frame, with the
  `if not A.initialized then return end` gate enforced once rather than in every handler.
- **Baseline-first roster diffing.** The first read after login, reload, or a guild change
  updates state and sends nothing. Choosing to miss early transitions rather than risk
  greeting everyone at once is the correct trade for the product and is documented as
  such.
- **Layered independent guards on every public message.** `CanUse`, then the feature
  toggle, then self-exclusion, then dedup by key, then queue spacing. No single guard is
  load-bearing alone.
- **Defense in depth where two events can describe one fact.** `OnSystemGuildJoin` is
  reachable from both `CHAT_MSG_SYSTEM` and `UI_INFO_MESSAGE`, so the same guild join can
  arrive twice; the 300-second `join:` cooldown key is what makes that harmless. The
  dedup layer is genuinely load-bearing here, not belt-and-braces.
- **Cheap gate before expensive match.** `MatchCraft` requires a request phrase (twelve
  plain substring tests) before scanning the recipe cache, so the O(recipes) substring
  search runs only on lines that are actually requests.
- **Type-checking external data.** Roster levels, chat messages, and Blizzard globals are
  validated before use. `type(previous.level) == "number" and previous.level > 0` prevents
  an uninitialized level from producing a spurious congratulation.
- **Feature detection everywhere**, including for APIs believed to exist, which is the
  right posture against a beta client that has already been reorganized once.
- **Debounce via timer plus boolean latch** rather than `OnUpdate` polling, applied
  consistently in four places.
- **Forward-compatible SavedVariables.** `fillDefaults` backfills recursively, so new
  settings appear without disturbing existing choices, and conservative defaults are the
  stated policy for anything that could surprise a user (`tabardOnExit` is `false`).
- **Escaping localized globals properly.** `ERR_GUILD_JOIN_S` has its pattern
  metacharacters escaped before the `%s` slot becomes a capture, instead of a hardcoded
  English sentence.
- **Conservative identity normalization.** `A:IsSelf` strips only an explicit `-Realm`
  suffix and never shortens further, with a comment explaining that guildmates can share
  a first name.
- **Privacy boundary held.** Alerts print locally, push onto a capped list, and never
  reach guild chat or a whisper. The Whisper button only opens the chat edit box via
  `ChatFrame_OpenChat`; it sends nothing.
- **No automation of player actions.** The tabard feature opens the character panel and
  stops. No gear swap, no invite handling, no auto-reply, no queueing.
- **Honest documentation.** The README limitations section states plainly that the source
  is written against documented API but has not been run in a real client, and explains
  why early transitions are deliberately missed.

### Anti-patterns

- **Dead state left in place** (`A.lastMessages`). Minor, but it invites a future reader
  to assume it is part of the dedup design.
- **Settings that exist in code but not in the UI** (`messageSpacing`, `loginCooldown`).
  The user-visible contract and the implemented contract have diverged slightly.
- **Duplicated role-availability logic.** `(self.classRoles[self.playerClass] or {})[role]`
  appears in both `A:Initialize` and `BuildRequestUI`. A small `A:CanFillRole(role)`
  helper would remove the repetition and give the rule one home.
- **A hardcoded number inside a user-facing string** (the "6 seconds" label) that can
  disagree with the value actually used.
- **Unpruned cache** (`A.eventsSeen`), as described above.

## Security Posture

No network surface, no credential handling, no file I/O outside the client's own
SavedVariables mechanism, no `loadstring`, no dynamic code loading, and no addon-to-addon
messaging. The relevant risks for an addon of this kind are taint and unintended social
output, and both are addressed:

- All gear, invite, and targeting actions stay in the player's hands, so no protected
  function is called from a tainted path.
- User-supplied template text is clamped at three separate points (`A:Format`,
  `A:SendGuild`, and `SetMaxLetters` on the edit boxes) and is only ever used as a chat
  payload, never as code or as a pattern.
- The one spot where user-influenced text becomes a Lua pattern is
  `OnSystemGuildJoin`, and that input is a Blizzard global rather than user input, with
  its metacharacters escaped before use.

## Recommendations

Ordered by value relative to effort.

| # | Recommendation | Effort | Rationale |
| --- | --- | --- | --- |
| 1 | Add harness coverage for `QueueGuild`, `DrainQueue`, `IsDuplicate`, and `SendGuild` | Low | These are the most safety-critical functions and currently the only ones stubbed out of their own tests |
| 2 | Verify the tabard initial-check ordering in game, then fix if confirmed | Low | A documented feature probably never fires on login |
| 3 | Add tests for the suspicious-roster-read guard and the guild-change wipe | Low | Both are explicit anti-spam invariants with no coverage |
| 4 | Remove `A.lastMessages` | Trivial | Dead state |
| 5 | Expose `messageSpacing` and `loginCooldown` in Options, and derive the spacing label from the value | Low | Closes the gap between documented and reachable configuration |
| 6 | Add a release script that runs the harness and checks the three version strings agree | Low | Removes the most error-prone manual pre-release steps |
| 7 | Bring `Tabard.lua` into the offline harness | Medium | The most testable of the four untested modules; pure state machine behind two stubbable helpers |
| 8 | Note the profession-name fallback degradation in the README limitations | Trivial | A silent narrowing of craft alerts that is otherwise hard to attribute |
| 9 | Prune expired keys from `A.eventsSeen` | Low | Bounds session growth |
| 10 | Extract `A:CanFillRole(role)` and reuse `fillDefaults` in `OnDefault` | Low | Removes duplicated logic and a latent shallow-copy issue |
| 11 | Add a `.luacheckrc` | Low | Would catch dead state and accidental globals automatically rather than by review |

None of these are blocking. The codebase is in good shape for a 0.1.0 beta whose own
documentation is clear that live-client verification is still outstanding.
