# Code Quality Assessment

**Analysis target**: Forever Guild Comms **0.4.1-beta**
**Supersedes**: the 0.2.0-beta pass of 2026-10-19T00:52:00Z

## Summary

Three releases on, the codebase is in materially better shape than at 0.2.0. Shipped Lua
grew 58% (1,097 to 1,733 lines) while test code grew 184% (207 to 589), taking coverage
from 19% to 34% of shipped source by line count. Seven of the seventeen recommendations
from the previous pass are resolved, including three that had been carried since 0.1.0 and
one closed during this pass itself.

The most consequential improvements are structural rather than cosmetic. `A:SetOption` and
`A:SetVoiceOption` turned two independent configuration UIs into one validated write path.
`A:CommsText` made an entire feature layer optional behind a single indirection, and a test
proves the fallback works. `tests/timing.lua` finally asserts the queue's spacing
arithmetic, which had been unverified since 0.1.0. And the voice layer — by far the largest
addition — was built so that it cannot touch text a human wrote.

One finding was closed during this pass itself: `.kiro/steering/testing.md` had been the
number-one recommendation of the previous review and had not been actioned, leaving it
documenting one harness out of nine and asserting an offline-testability limit that three
harnesses disprove. It has now been rewritten to match the code.

That leaves one item standing out: packaging is automated while testing is not, so a `v*`
tag can cut a release without any harness having run.

## Status of the 0.2.0 Findings

| # | 0.2.0 recommendation | Status at 0.4.1 |
| --- | --- | --- |
| 1 | Update `testing.md` to describe all harnesses and drop the stale offline claim | **RESOLVED during this pass.** Rewritten to document all nine harnesses with their run commands and coverage, to state that CI packages but does not test, to replace the offline claim with an accurate per-module breakdown, and to extend the in-game checklist and pre-release gate |
| 2 | Make `OnDefault` preserve `outgoingMode` or warn | **Not done.** Still silently resets the mode, and now also resets per-character voice settings |
| 3 | Key approval rows by a monotonic id rather than list position | **Not done.** `row.entryIndex` is still positional |
| 4 | Verify the tabard initial-check ordering in game | **Not done.** `Tabard.lua` untouched since 0.1.0 |
| 5 | Add a runner that executes all harnesses and checks version strings | **Not done**, and the need grew: 9 harnesses now, plus CI that packages without testing |
| 6 | Bring `UI.lua`'s `UpdateApprovalsUI` into the harness | **Not done.** `UI.lua` is loaded by `titanmenu.lua` but its windows are stubbed |
| 7 | Add a floor between consecutive approvals | **Not done.** `ApproveMessage` still sends immediately with no spacing |
| 8 | Test the 30-entry backlog cap | **Not done** |
| 9 | Remove `A.lastMessages` | **RESOLVED in 0.3.0.** Zero references remain |
| 10 | Expose `messageSpacing` and `loginCooldown` in Options | **RESOLVED in 0.3.0.** Numeric fields in Settings, preset submenus in the Titan menu, clamped through `NormalizeTiming` in both |
| 11 | Make the review window's auto-show optional | **Not done.** `StageApproval` still calls `ShowApprovals` on every staged message |
| 12 | Comment that `pendingMessages` holds records, not strings | **Not done.** Still uncommented |
| 13 | Bring `Tabard.lua` into the harness | **Not done.** The only module with no harness loading it |
| 14 | Note the profession-name fallback in README limitations | **Not done** |
| 15 | Prune expired keys from `A.eventsSeen` | **Not done** |
| 16 | Extract `A:CanFillRole`, reuse `fillDefaults` in `OnDefault` | **Not done.** The duplication and the shallow copy both remain |
| 17 | Add `.luacheckrc` and `.gitattributes` | **Half resolved.** `.gitattributes` added; no `.luacheckrc` |

Also resolved, from the 0.2.0 open-findings list rather than the recommendations:

| 0.2.0 finding | Status |
| --- | --- |
| Spacing arithmetic unasserted | **RESOLVED.** `tests/timing.lua` asserts the exact computed delay for three successive sends |
| `TitanMenu.lua` / `Broker.lua` untested | **RESOLVED.** `tests/titanmenu.lua` loads and drives both |
| No CI | **RESOLVED for packaging.** Still absent for tests |

Seven resolved (six by the 0.3.0-0.4.1 releases, one during this pass), one half-resolved,
ten carried forward.

## Test Coverage

- **Overall**: Good and improving. Nine harnesses, 589 lines, covering ten of eleven
  modules plus the XML.
- **This rating comes from reading the harnesses, not running them.** No Lua interpreter is
  installed on this machine — `lua5.1`, `lua`, and `luajit` were all checked and none
  resolved — so none of the nine suites was executed during this pass. Per the project's
  own testing rule, this is stated rather than glossed.

### Notable new coverage

**`tests/timing.lua` closes the oldest gap.** It keeps the `delay` argument that
`verify.lua` discarded, so it can assert the queue's arithmetic precisely: first message at
delay 0, second at 11 (spacing 12 minus 1 second elapsed), third at 1. It then exercises
the per-member login cooldown in both directions and confirms `loginCooldown = 0` permits
repeat greetings. The comment explaining why the third delay is 1 rather than 12 shows the
author reasoning about `lastGuildSend` advancing inside a callback — exactly the kind of
subtlety that needed pinning.

**`tests/titanmenu.lua` is the most ambitious harness.** Beyond the widget layer it fakes
the `MenuUtil` node API itself, building nodes that record their children, so the test can
generate the real menu tree and then walk and invoke it. This is what makes a 127-line
presentation module assertable offline without a client.

**`tests/voice.lua` pins the feature's safety properties, not just its happy path.** It
asserts that a custom template containing a real item hyperlink survives translation
untouched, that race-filtered-out accents cannot be set, that changing language resets an
incompatible accent to `auto`, that an unknown race yields only two options, that invalid
values are rejected, and — in a dedicated regression — that a 250-byte cut does not split a
multibyte character.

**`tests/keybindings.lua` tests the artifact rather than a reimplementation.** It reads
`Bindings.xml`, regex-extracts each handler body, and `load()`s it, so the real embedded
Lua executes. It then asserts the bindings are opt-in (no `default=`), unique, and
correctly categorised, drives all three actions, and requires the `SendChatMessage` stub to
have been called zero times. It also covers the disabled-addon and pre-initialisation
paths. As a side effect it loads only `Core.lua` and `Alerts.lua`, which proves the
`CommsText` fallback works without the voice modules.

**`tests/syntax.lua` and `tests/icon.lua` are cheap structural guards.** Six lines to catch
a non-parsing file across all eleven modules; twenty-one to catch icon wiring drifting
apart across the TOC, `Broker.lua`, `Options.lua`, and the installer.

### Remaining coverage gaps, ranked

1. **`Tabard.lua` has no harness that loads it.** The only such module, and it still
   carries the suspected ordering defect below. Two stubbable helpers and a pure state
   machine; the easiest remaining win.
2. **`UI.lua`'s logic is unexercised.** It is loaded by `titanmenu.lua`, but
   `UpdateApprovalsUI`'s paging, clamping, and index binding — the authorization path for
   public messages — are not driven. The widget technique already in the repo would reach
   them.
3. **The 30-entry backlog cap is untested**, including that it drops the oldest.
4. **`wipe(pendingMessages)` when `CanUse` turns false** remains uncovered in both the
   `DrainQueue` branch and the `OnRosterEvent` guild-change branch.
5. **`A:IsSelf` realm handling and the suspicious-roster-read guard** remain untested,
   carried from 0.1.0. Both are explicit anti-spam protections.
6. **`A:ChatLimit` is tested only on a two-byte character.** A three- or four-byte
   sequence (CJK, emoji) would exercise the loop more than one iteration deep.
7. **The `expressive` strength branch is only partly covered.** `voice.lua` asserts the
   flair appears; it does not assert the punctuation intensification.
8. **No CI runs any of this.** See below.

## Code Quality Indicators

- **Linting**: still not configured. No `.luacheckrc`. `.gitattributes` now pins LF, which
  removed the CRLF churn git had been warning about.
- **Code Style**: consistent, and the four new modules match the house conventions
  precisely — `local _, A = ...` headers, `function A:Name()` methods, file-local helpers
  kept local, early-return guards, 4-space indentation, compact `{key=value}` data tables.
  The 29 `register(...)` calls in `Accents.lua` exceed the ~100-character guideline
  substantially, but as uniform single-line data records they are more readable this way
  than wrapped; a defensible deviation.
- **Documentation**: good and genuinely maintained. The README grew 80 lines covering
  keybindings, the two sending modes, timing controls, and the languages feature, with a
  revised 10-step in-game checklist. `PACKAGING.md` documents the release process.
  Comments continue to explain *why*: the load-order note on `Languages.lua`'s English
  entry, the asynchronous-panel reason for the deferred scroll, the "editing a template
  always wins" rationale, the "don't prepend an interjection to `[LFG]`" note, the
  Skyborne-token caveat, and the "Bindings.xml must not be in the TOC" comment in two
  places.
- **Error handling**: good. `pcall` still wraps the one failing call. `NormalizeTiming`
  explicitly handles NaN and both infinities. `GetPlayerRace` falls through three
  candidates to `"Unknown"`. `OpenTitanMenu` substitutes `UIParent` for a malformed owner.
  Data-table reads in `RaceProfiles.lua` are all written defensively as
  `(self.table or {})`.
- **Global hygiene**: good. Four new `BINDING_*` globals, which the client's Key Bindings
  UI requires and for which no alternative exists. No new frames, no new namespace
  globals.
- **Control flow**: good. `A:SetOption` and `A:SetVoiceOption` are flat dispatch chains.
  `A:VoiceText` is the densest new function but reads top-to-bottom as a precedence
  ladder.

### Observation: the voice layer was built to be unable to cause harm

Worth recording, because it is the clearest design signal in these three releases. The
highest-risk thing a message-rewriting feature could do is corrupt text a user authored —
breaking an item link, mangling a name, or altering intent. Every structural choice
forecloses that:

| Choice | Effect |
| --- | --- |
| Whole-phrase substitution, never transformation | No regex ever runs over user text to "add an accent" |
| Customized template wins outright | A template that differs from the default is formatted verbatim and returned before any voice logic executes |
| Only four built-in templates are in scope | Nothing else the addon or player writes is reachable |
| No global chat hooks | Stated in the module header and true in the code |
| Flair never applied to `help` | An `[LFG]` line is never prefixed with an interjection |
| Defaults reproduce prior output exactly | English, accent `none` — upgrading changes nothing |
| Per-character storage | One character's RP voice cannot leak into another's |
| Encoding-aware truncation added alongside | The feature that introduced multibyte text also fixed the truncation that would have split it |

`tests/voice.lua` asserts the second row with a real `|cff00ff00|Hitem:1|h[Linen Bag]|h|r`
link, which is the right way to pin it.

## Technical Debt

### New in this span

#### `OnDefault`'s blast radius widened without a warning being added
Previously flagged for silently resetting `outgoingMode`. It now *also* resets all four
per-character voice settings from `A.voiceDefaults`. So a Restore Defaults click moves a
player from Verify back to Automatic *and* discards their language and accent choices, with
no confirmation and no printed note — while the radio button's own handler does print a
reminder for the mode change. The recommendation stands and has grown slightly more
valuable.

#### A duplicated line in `OnDefault`
`if A.UpdateRequestPreview then A:UpdateRequestPreview() end` appears twice in the same
function, once before and once after the broker update. Harmless, but it is the kind of
artifact that suggests the function was edited twice without re-reading.

#### `subtle` strength applies no flair at all
The three strengths are `subtle`, `moderate`, and `expressive`, and `subtle` is the
default. Reading `A:VoiceText`, the flair prefix is applied only for `moderate` and
`expressive`; `subtle` gets the style's phrasing with no prefix. That is a reasonable
design, but the label implies a light touch rather than none, and a player selecting
"Subtle" after seeing "Expressive" may reasonably expect a reduced flourish rather than
its complete absence. Worth a word in the options hint.

#### `moderate` and `expressive` differ only in terminal punctuation
Both prepend the same flair string. `expressive` additionally doubles a trailing `!` or
converts a trailing `.` to `!`. The distinction is real but very small, and the code comment
("A stronger flourish without repeating the catchphrase") reads as if more was intended.
Either is fine; it is worth knowing the two levels are nearly identical in effect.

#### Packaging is automated but testing is not
`.github/workflows/package.yml` fires on a `v*` tag and publishes a release. Nothing in CI
runs the nine harnesses or checks that the three version strings agree. A tag therefore
cuts a release with no automated verification whatsoever. Since the harnesses are pure Lua
with no dependencies beyond an interpreter, a test job would be a handful of lines and
would convert the existing suite from "run when remembered" to "enforced".

#### `.pkgmeta` retention of `Bindings.xml` is unasserted
`Bindings.xml` must reach users but cannot be in the TOC. Two mechanisms carry it: the
installer appends it explicitly and fails if absent, and `.pkgmeta` simply does not exclude
it. `tests/icon.lua` checks the installer path for the icon, and `tests/keybindings.lua`
checks the XML's content, but nothing asserts that `.pkgmeta` still includes
`Bindings.xml`. A future exclusion added to `.pkgmeta` would silently ship an addon with no
bindings via the automated channel while the manual installer kept working — an
asymmetric failure that would be hard to diagnose.

#### README section ordering
The keybindings section was inserted between the `# Forever Guild Comms 0.4.1-beta` title
and the `WoW: Forever 1.60.1 / Interface 16001 addon by Michael Reilly.` byline, leaving
the byline orphaned beneath a long block. Cosmetic, but the README is explicitly treated as
part of the deliverable.

### Carried forward unchanged

- **`A.eventsSeen` is never pruned.** Three references, no sweep. Bounded by session length.
- **The tabard initial-check ordering issue.** `Tabard.lua` is byte-identical to 0.1.0, so
  the analysis stands: the 1.2-second debounced check from `PLAYER_ENTERING_WORLD`
  populates `A.wasInCity` before the 3-second `CheckTabard(true)` runs, so the latter sees
  no transition and returns early, and the login-time prompt likely never fires. Still
  inferred from source and still **not verified in a live client**.
- **The profession-name fallback** in `ScanRecipes` still collapses every profession into a
  single `"Current Profession"` bucket when the skill-line APIs are missing. Still
  undocumented in the README limitations.
- **`A.GetActivityType`** is still a dot-called closure rather than a `function A:` method —
  the one place the module pattern is not followed.
- **Positional approval-row binding.** `row.entryIndex` is captured at refresh and passed to
  `ApproveMessage`. Safe today because every mutation path refreshes the UI and WoW's Lua is
  single-threaded, but the invariant is undocumented and its failure mode is sending the
  wrong message.
- **No rate limit on approvals.** Four visible rows can be clicked in rapid succession,
  producing back-to-back guild posts with none of the automatic path's spacing. Documented
  as intentional in the README; still asymmetric with `SendHelpRequest`'s 20-second limit.
- **`ShowApprovals` on every staged message.** The review window re-shows each time a
  message is staged.
- **`OnDefault` shallow copy.** One level deep. Correct for the current shape; `fillDefaults`
  already recurses and could be reused.
- **Duplicated role-availability logic**, `(self.classRoles[self.playerClass] or {})[role]`
  in both `A:Initialize` and `BuildRequestUI`.
- **`pendingMessages` holds records, not strings**, still without a comment saying so.
- **No `.luacheckrc`.**

### Resolved, with credit

- **`A.lastMessages` removed** in 0.3.0 — dead state flagged in two consecutive passes.
- **`messageSpacing` and `loginCooldown` are now reachable**, with validated limits, from
  both UIs. This was arguably the most user-visible of the carried findings.
- **The spacing arithmetic is now asserted** by `tests/timing.lua`.
- **`TitanMenu.lua` and `Broker.lua` are now covered** by `tests/titanmenu.lua`.
- **`.gitattributes` added**, and the LF/CRLF churn is gone.
- **CI exists** for packaging.

## Patterns and Anti-patterns

### Good Patterns

Carried forward and intact: single outbound chat path; single event dispatcher; baseline-first
roster diffing; layered independent guards; defense in depth where two events describe one
fact; cheap gate before expensive match; type-checking external data; feature detection
everywhere; debounce via timer plus latch; forward-compatible SavedVariables; escaped
localized globals; conservative identity normalization; the private/public boundary; no
automation of player actions; late-bound delivery; identity-bound message records;
asymmetric mode transitions; fail-safe setting normalization; honest documentation.

New and worth naming:

- **One validating setter per scope.** `A:SetOption` and `A:SetVoiceOption` are the only
  writers, and both configuration UIs go through them. This is why a Titan preset and a
  Settings edit box cannot disagree, and why clamping is unconditional. The explicit refusal
  of template keys in `SetOption` — rather than an omission — is the detail that makes it
  airtight.
- **Optional layer behind a one-line indirection.** `A:CommsText` makes 234 lines of voice
  feature removable, and a harness that omits those modules proves the fallback.
- **Pure data modules.** Adding a language or style is a data edit. `accentOrder` gives
  deterministic presentation independent of table iteration order, which also makes the
  menu and Settings lists stable between sessions.
- **Self-healing dependent selections.** A stored accent that becomes incompatible reverts
  to `auto` rather than being used invisibly, at both write time and load time.
- **Encoding-aware truncation introduced with the feature that needed it**, plus a
  regression test. The sequencing matters: the limit was fixed in the same release that
  made multibyte text possible.
- **Declarative input funnelled through one dispatcher.** The key bindings added a third
  input surface and *removed* duplication, because `TitanMenu.lua` was refactored onto
  `RunQuickAction` in the same change.
- **Honest return values.** `ScanRecipes` returning a boolean replaced an unconditional
  optimistic message with accurate feedback. Small change, real UX improvement.
- **Testing the artifact, not a copy.** `keybindings.lua` loads the real XML and executes
  the real handlers; `icon.lua` reads the real TOC and installer. Both resist the classic
  failure where a test mirrors the implementation and both drift together.
- **Declining a convenient dependency.** The nested menu used Blizzard's `MenuUtil` rather
  than Titan's menu library, preserving the no-hard-dependency policy at the exact moment it
  was under pressure.

### Anti-patterns

- **A generic defaults handler resetting safety-relevant and per-character state** without
  the warning its dedicated control prints.
- **A duplicated statement** in `OnDefault`.
- **Positional index binding between a UI row and a mutable list.**
- **An unasserted packaging invariant** (`.pkgmeta` retaining `Bindings.xml`).
- **Automated release with no automated verification.**
- ~~**A steering document that contradicts the code it governs.**~~ Resolved during this
  pass; `testing.md` now matches the nine-harness reality.
- **Unpruned cache** (`A.eventsSeen`).
- **Duplicated role-availability logic.**

## Security Posture

Unchanged and still sound. No network surface, no credential handling, no file I/O outside
SavedVariables, no `loadstring` in shipped code, no dynamic code loading, no addon-to-addon
messaging. All gear, invite, and targeting actions remain in the player's hands, so no
protected function is called from a tainted path.

Three observations specific to this span:

- **The voice layer does not widen the attack surface.** It substitutes from static tables
  and never compiles, evaluates, or pattern-matches user text. The one place user-influenced
  text becomes a Lua pattern is still `OnSystemGuildJoin`, whose input is a Blizzard global
  with its metacharacters escaped.
- **`Bindings.xml` embeds Lua that the client executes.** This is the standard mechanism and
  the content is static, guarded, and limited to a single dispatcher call. Note that
  `tests/keybindings.lua` uses `load()` on that content — appropriate in a test, and it is
  worth keeping that confined to tests.
- **The installer validates its manifest.** `Get-InstallManifest` rejects any TOC entry that
  is not a bare `[A-Za-z0-9_-]+\.(lua|xml)` filename, explicitly blocking paths, traversal,
  and unexpected extensions. For a script that copies files into a game directory, that is
  the right instinct.
- **CI permissions are minimal.** `contents: write` is what attaching a release asset
  requires, and the optional third-party tokens are inert when unset.

## Recommendations

Ordered by value relative to effort. *(carried)* marks items from the 0.2.0 list.

| # | Recommendation | Effort | Rationale |
| --- | --- | --- | --- |
| ~~1~~ | ~~Update `.kiro/steering/testing.md`~~ *(carried, was #1)* | Trivial | **Done during this pass.** Now documents all nine harnesses and their coverage, states that CI packages but does not test, replaces the offline claim with a per-module breakdown identifying `Tabard.lua` as the only uncovered module, and extends the in-game checklist to 14 steps plus a pre-tag gate |
| 1 | Add a test job to `package.yml`, or a local runner script, that runs all nine harnesses and verifies the three version strings agree *(carried, was #5)* | Low | **Now the top item.** A tag currently publishes a release with zero automated verification. The suite is pure Lua with no dependencies, and `testing.md` now documents the exact commands a runner would wrap |
| 3 | Make `OnDefault` preserve `outgoingMode` and voice settings, or print the same warning the radio prints *(carried, was #2)* | Trivial | Restore Defaults silently re-enables unattended public messaging and discards language choices |
| 4 | Assert in a harness that `.pkgmeta` does not exclude `Bindings.xml` | Trivial | Prevents an asymmetric failure where the automated channel ships without keybindings and the installer does not |
| 5 | Bring `Tabard.lua` into the harness *(carried, was #13)* | Low | The only module no harness loads; pure state machine behind two stubbable helpers |
| 6 | Verify the tabard initial-check ordering in game, then fix if confirmed *(carried, was #4)* | Low | A documented feature probably never fires on login |
| 7 | Key approval rows by a monotonic entry id *(carried, was #3)* | Low | Removes a fragile undocumented invariant whose failure mode is sending the wrong message |
| 8 | Remove the duplicated `UpdateRequestPreview` line in `OnDefault` | Trivial | Obvious editing artifact |
| 9 | Drive `UpdateApprovalsUI` in a harness *(carried, was #6)* | Medium | The review window is part of the authorization path for public messages |
| 10 | Clarify in the options hint that Subtle applies no flair prefix | Trivial | The label implies a light touch, not absence |
| 11 | Test the backlog cap, a 3-4 byte `ChatLimit` case, and the `expressive` punctuation branch *(partly carried, was #8)* | Low | Three small gaps in otherwise strong coverage |
| 12 | Add a modest floor between consecutive approvals *(carried, was #7)* | Low | Closes the one spacing gap; consistent with `SendHelpRequest` |
| 13 | Add `.luacheckrc` *(carried, was #17)* | Low | Would have caught the duplicated line and would guard against accidental globals |
| 14 | Make the review window's auto-show optional *(carried, was #11)* | Low | Repeated popups during a busy login period |
| 15 | Comment that `pendingMessages` holds records *(carried, was #12)* | Trivial | Prevents a contract trip-up |
| 16 | Note the profession-name fallback in README limitations *(carried, was #14)* | Trivial | A silent narrowing of craft alerts that is hard to attribute |
| 17 | Move the README keybindings section below the byline | Trivial | The byline is currently orphaned |
| 18 | Prune expired keys from `A.eventsSeen` *(carried, was #15)* | Low | Bounds session growth |
| 19 | Extract `A:CanFillRole`, reuse `fillDefaults` in `OnDefault` *(carried, was #16)* | Low | Removes duplication and a latent shallow-copy issue |

None are blocking. The trajectory across four releases is good: each one closed real
findings from the prior review while adding features that extended the safety model rather
than straining it.

With `testing.md` corrected, the remaining top item is the other half of the same problem:
the project now has an accurate, documented nine-harness suite and a release pipeline that
does not run it. Wiring the two together is the highest-value change left on this list.
