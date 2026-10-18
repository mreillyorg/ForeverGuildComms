# Code Quality Assessment

**Analysis target**: Forever Guild Comms **0.2.0-beta**
**Supersedes**: the 0.1.0-beta pass of 2026-10-18

## Summary

0.2.0 is a quality-positive release. The headline feature — an opt-in review step before
any roster-driven message reaches guild chat — directly strengthens the product's primary
safety property, and it arrived with tests rather than after them. Three of the eleven
recommendations from the 0.1.0 assessment are now resolved, including the most important
one: the send pipeline is no longer stubbed out of its own tests.

Test code grew from 72 lines to 207 against 1,097 lines of shipped source, taking test
coverage from 8% to 19% by line count. More significantly, `tests/verify.lua` exercises
the *real* `QueueGuild`, `DrainQueue`, `StageApproval`, and `ApproveMessage`, and
`tests/settings.lua` proves that the Options panel is testable offline — something the
project's own notes had declared impossible.

The remaining concerns are mostly carried forward from 0.1.0 and unchanged. The one new
finding of substance is that `OnDefault` silently resets the outgoing mode without the
warning its sibling control prints.

## Status of the 0.1.0 Findings

| # | 0.1.0 finding | Status in 0.2.0 |
| --- | --- | --- |
| 1 | Send queue (`QueueGuild`, `DrainQueue`, `IsDuplicate`, `SendGuild`) had no automated coverage | **Largely resolved.** `tests/verify.lua` drives all four through the real code path |
| 2 | `IsDuplicate` untested | **Resolved.** Asserted directly: a repeated `login:alice` does not enqueue twice |
| 3 | `IsSelf` realm handling untested | **Open, unchanged** |
| 4 | Suspicious-roster-read guard untested | **Open, unchanged** |
| 5 | Guild-change path untested | **Resolved for the approval path.** `tests/verify.lua` covers the guild-mismatch discard and `ClearApprovals`. The `wipe(pendingMessages)` branch in `OnRosterEvent` is still uncovered |
| 6 | Four modules had no offline path | **Partly resolved.** `Options.lua` is now covered; `UI.lua`, `Tabard.lua`, `Broker.lua` still are not |
| 7 | `A.lastMessages` dead state | **Open, unchanged.** Still declared at `Core.lua:32`, still referenced nowhere |
| 8 | `messageSpacing` and `loginCooldown` have no UI control | **Open, unchanged.** Still 9 toggles and 4 template editors, no numeric inputs |
| 9 | Hardcoded "6 seconds" options label could drift | **Resolved.** Now reads "Automatic messages are rate-limited; verified messages only send when you click Send", which no longer asserts a specific number |
| 10 | Tabard initial-check ordering issue | **Open, unchanged.** `Tabard.lua` was not touched |
| 11 | Unpruned `A.eventsSeen` | **Open, unchanged** |
| 12 | `OnDefault` shallow copy | **Open, and now slightly more consequential** — see new findings |
| 13 | Profession-name fallback degradation | **Open, unchanged** |
| 14 | `A.GetActivityType` convention inconsistency | **Open, unchanged** |
| 15 | No CI | **Open, and the case is stronger** with four harnesses instead of one |

## Test Coverage

- **Overall**: Good on the message pipeline and settings migration, absent on the three
  frame-heavy modules. A clear improvement over 0.1.0.
- **This rating comes from reading the harnesses, not running them.** No Lua interpreter
  is installed on this machine — `lua5.1`, `lua`, `luajit`, `lua5.4`, and `lua54` were all
  checked and none resolved — so none of the four suites was executed during this pass.
- **Unit tests**: four harnesses, 207 lines. Each stubs only the globals its own path
  touches, dies on the first failed `assert`, and prints a `PASSED` summary.
- **Integration tests**: `tests/settings.lua` is arguably one — it loads two modules,
  runs `A:Initialize`, and drives real widget handlers.
- **Performance tests**: none, and not warranted.
- **Manual verification**: the in-game checklist was revised to ten steps and now leads
  with Verify mode, which is the right emphasis for a release whose point is the review
  step.

### What `tests/verify.lua` locks down

This is the most valuable new file in the release. It captures `C_Timer.After` callbacks
into a list rather than running them, which lets it fire the drain timer at a chosen
moment and assert what happens across a mode change. Thirteen assertions cover:

| Invariant | Assertion |
| --- | --- |
| Verify mode never auto-sends | One staged entry, zero sends, review window shown once |
| Dedup applies in Verify mode too | A repeated `login:alice` does not stage a second entry |
| Send posts exactly one message | After approval: one send, correct text, backlog empty |
| Dismiss never sends | Backlog empties, send count unchanged |
| **Mode toggle cannot flush the backlog** | Switching to Automatic leaves the staged entry unsent and still pending |
| An older staged entry can still be approved manually | Approval works after the mode switch |
| Automatic mode enqueues rather than sending immediately | Entry lands in `pendingMessages`, nothing sent yet |
| **A mode switch during the spacing delay captures the message** | Firing the drain timer after switching to Verify stages instead of sending |
| A message cannot cross a guild boundary | After the guild changes, approving discards instead of sending |
| `ClearApprovals` empties the backlog | Asserted directly |
| Automatic still works end to end | Final entry sends without a click |
| The channel is always GUILD | The `SendChatMessage` stub asserts `channel == "GUILD"` on every call |

The two bolded rows are the invariants most likely to be broken by a careless future
refactor, and they are the ones most explicitly pinned. That is good test design.

### What `tests/settings.lua` locks down

A metatable-based fake widget layer makes `Options.lua` loadable offline. `CreateFrame`
records every widget in a flat list, so the test can afterwards locate widgets by
template name or by label text and invoke their stored `OnClick` handlers. It asserts:

- a custom login template survives migration;
- a blank join template and a whitespace-only level template are replaced by defaults;
- a missing help template is filled from defaults;
- `outgoingMode` defaults to `"automatic"`, preserving 0.1.0 behavior for existing users;
- exactly two radio widgets exist and Automatic starts selected;
- exactly four *Use default* buttons exist, one per template;
- clicking each radio switches the mode and updates both buttons.

Running `A:Initialize()` with `IsInGuild` stubbed to `false` is a thoughtful detail: it
tests the migration without any risk of the test triggering the send path.

### Remaining coverage gaps, ranked

1. **`UI.lua` has no automated coverage**, and it now holds the review window — the UI
   through which the user authorizes public messages. `tests/settings.lua` has already
   demonstrated the technique that would reach it. `UpdateApprovalsUI`'s paging, clamping,
   and index binding are pure logic over a list and would be straightforward to assert.
2. **`Tabard.lua` still untested**, and still carries the suspected ordering defect
   below. It remains the easiest of the three to bring in: two stubbable helpers and a
   pure state machine.
3. **`Broker.lua` untested.** Low value; it is 38 lines of string assembly and click
   routing.
4. **The spacing arithmetic is still unasserted.** `tests/verify.lua` fires the captured
   timer directly, so it never checks that the computed delay equals
   `max(3, messageSpacing)`. The stub discards the delay argument entirely.
5. **`wipe(pendingMessages)` when `CanUse` turns false is still uncovered**, both the
   up-front branch in `DrainQueue` and the `OnRosterEvent` guild-change branch.
6. **`IsSelf` realm handling and the suspicious-roster-read guard** remain untested,
   carried forward from 0.1.0.
7. **The 30-entry backlog cap is untested.** `StageApproval` drops index 1 when full;
   nothing asserts that the oldest is the one discarded, or that the UI indices stay
   consistent afterwards.

## Code Quality Indicators

- **Linting**: still not configured. No `.luacheckrc`, no formatter config. Also no
  `.gitattributes`, which is why git reports LF-to-CRLF normalization warnings on all
  seven modified files.
- **Code Style**: consistent, and the new code matches the established conventions. The
  four new `Core.lua` methods follow the `function A:Name()` form with early-return
  guards; the new UI methods mirror the existing build/update/show triple exactly; the
  new `outgoingMode` closure sits alongside `section`, `toggle`, and `template` in the
  same style. Still 12 `local function` definitions and no new globals beyond the one new
  named frame.
- **Documentation**: good, and kept in step with the code. The README gained a dedicated
  "Automatic versus Verify mode" section that states the non-obvious rules explicitly —
  including that switching back to Automatic does not release pending items, and that
  switching to Verify captures an in-flight message. The limitations section was updated
  rather than left stale. New code comments explain *why*: "Never approve messages merely
  by toggling the mode to Automatic: an explicit approval remains explicit" and "The Send
  button is the actual user confirmation. Do not schedule a delayed automatic send after
  a click."
- **Error handling**: good. `pcall` still wraps the one call that can fail. The new
  methods all guard their inputs (`if not entry`, `if not self.pendingApprovals[index]`)
  and re-check `CanUse` at the moment of action rather than trusting an earlier check.
- **Global hygiene**: good. One new named frame (`FGCApprovalsFrame`), bringing the total
  to four. No new namespace globals.
- **Control flow**: good. The new `DrainQueue` body nests one level deeper than before
  (`if entry and CanUse` then `if sameGuild` then the mode branch), which is the deepest
  point in the file but still readable.

### Observation: the new code fails safe at every branch

Worth recording because it is the clearest signal of intent in the release. Every edge
case introduced by the mode feature resolves toward *not sending*:

| Situation | Resolution |
| --- | --- |
| Unrecognized persisted mode value | Coerced to `"automatic"`, the documented default, rather than left undefined |
| Mode switched to Verify mid-flight | Message staged, not posted |
| Mode switched to Automatic with a backlog | Backlog untouched; a console note points at `/fgc verify` |
| Guild changed before the drain timer fires | Entry silently discarded |
| Guild changed before an approval click | Entry discarded with an explanatory message |
| `CanUse` false at drain time | Entry dropped |
| `CanUse` false at approval time | Refused with a printed reason |
| Backlog at capacity | Oldest *unsent* entry dropped, rather than flushing anything |
| Template blanked by the user | Empty message rejected by `QueueGuild` before it can consume a cooldown key |

## Technical Debt

### New in 0.2.0

#### `OnDefault` resets the outgoing mode without the warning its sibling prints
`Options.lua`'s restore-defaults handler copies all of `A.defaults` over `A.db`, which
now includes `outgoingMode`. A user in Verify mode who clicks Restore Defaults is
silently switched to Automatic, after which future greetings post without review.

The radio button's own `OnClick` prints a note when switching to Automatic with a
non-empty backlog; `OnDefault` performs the same switch with no note. The behavior is
also safe in the important respect — already-staged messages are not released, since
`OnDefault` does not touch `pendingApprovals` — but the inconsistency is worth closing,
either by printing the same note or by preserving the mode across a defaults restore.
Given that this setting governs whether the addon speaks publicly without the user
present, preserving it is arguably the better choice.

#### The shallow copy in `OnDefault` is now closer to mattering
The handler copies one level deep. That is still correct for the current shape, where
`templates` is the only nested table and it is flat. But `A.defaults` gained a key this
release, and the pattern will silently break the first time a default is nested two
levels. `fillDefaults` already recurses properly and could be reused.

#### No rate limit on approvals
`ApproveMessage` calls `SendGuild` directly with no spacing and no cooldown of its own.
A user with four rows visible can click Send four times in quick succession and post four
messages back to back, with none of the `max(3, messageSpacing)` protection the automatic
path enforces.

This looks deliberate: the README states that "Messages sent via deliberate Send clicks
are not delayed", and the code comments that the click is the confirmation. The precedent
is `SendHelpRequest`, which also bypasses the queue — but that one still imposes a
20-second self-limit, so the asymmetry is real. Since the user is present and clicking,
this is a far smaller risk than unattended spam, but a modest floor (even one second)
would close the gap without harming the experience.

#### `ShowApprovals` is called on every staged message
`StageApproval` ends with `if self.ShowApprovals then self:ShowApprovals() end`, so the
review window re-shows each time a new message is staged. With several guildmates logging
in during a busy evening this will surface the window repeatedly, possibly over whatever
the player is doing. The README documents it ("The popup appears as new review items are
created"), so it is intentional, and a user who wants quiet can choose Automatic. Still,
an option to suppress the auto-show, or showing only on the first staged entry while the
window is closed, would be a reasonable refinement.

#### Row index binding depends on an undocumented discipline
Approval rows capture `row.entryIndex` during `UpdateApprovalsUI`, and the Send and
Dismiss handlers pass that stored index to `ApproveMessage` / `DismissMessage`. Because
the backlog shifts whenever an entry is removed — and whenever the 30-cap drops index 1 —
a stale index would act on the *wrong message*, which is precisely the product's worst
failure mode.

In the current code this is safe: every mutation path calls `UpdateApprovalsUI`, which
re-binds all four rows, and WoW's Lua is single-threaded so a click handler cannot
interleave with an event handler mid-function. The risk is not a present defect but a
fragile invariant — the safety depends on every future mutation path remembering to
refresh. Keying rows by a monotonic entry id instead of a positional index would make the
binding robust by construction. Worth a comment at minimum.

#### The queue contract changed without a compatibility note
`A.pendingMessages` holds records now, not strings. Nothing in the current codebase reads
it expecting a string, and `tests/smoke.lua` is unaffected because it stubs `QueueGuild`
entirely. But this is the kind of silent contract change that is easy to trip over later,
and it is not mentioned in any comment.

#### `.kiro/steering/testing.md` is now out of date
The steering document still says only `Core.lua`, `Roster.lua`, and `Alerts.lua` are
loadable offline and that `Options.lua` must be tested in game — which
`tests/settings.lua` disproves. It also documents only `tests/smoke.lua` and gives a
single run command, with no mention of the three new harnesses. Since the steering files
are what guide future work on this project, a stale one actively misdirects. This is the
highest-value documentation fix in the list.

### Carried forward unchanged from 0.1.0

- **`A.lastMessages`** is still declared and still referenced nowhere. Safe to remove.
- **`messageSpacing` and `loginCooldown` still have no UI control**, despite both being
  consumed by code. Reaching them still requires hand-editing SavedVariables. The new
  options text now refers to automatic messages being "rate-limited" without saying by
  how much, which is accurate but leaves the user unable to see or change the value.
- **`A.eventsSeen` is never pruned.** Unchanged, and Verify mode does not add keys beyond
  what Automatic already created.
- **The tabard initial-check ordering issue.** `Tabard.lua` was not modified, so the
  analysis stands: the 1.2-second debounced check from `PLAYER_ENTERING_WORLD` populates
  `A.wasInCity` before the 3-second `CheckTabard(true)` runs, so the latter sees no
  transition and returns early, and the login-time prompt likely never fires. Still
  inferred from source and still **not verified in a live client**.
- **The profession-name fallback** in `ScanRecipes` still collapses all professions into
  one `"Current Profession"` bucket when the skill-line APIs are missing, so each scan
  overwrites the last. Still worth a README note.
- **`A.GetActivityType`** is still a dot-called closure rather than a `function A:`
  method, the one place the module pattern is not followed.
- **No CI.** With four harnesses, the manual pre-release checklist now has more steps to
  get wrong, not fewer.

## Patterns and Anti-patterns

### Good Patterns

Carried forward and still intact: the single outbound chat path; the single event
dispatcher; baseline-first roster diffing; layered independent guards; defense in depth
where two events describe one fact; cheap gate before expensive match; type-checking
external data; feature detection everywhere; debounce via timer plus boolean latch;
forward-compatible SavedVariables; properly escaped localized globals; conservative
identity normalization; the private/public boundary; no automation of player actions;
honest documentation.

New in 0.2.0:

- **Late-bound delivery decision.** Reading `outgoingMode` again inside the drain timer,
  rather than only at composition time, is what makes a mid-flight mode change do the
  right thing. This is a small design choice with a large safety payoff, and it is
  explicitly tested.
- **Identity-bound message records.** Stamping each entry with the guild it was composed
  in, then re-verifying at both delivery points, closes a cross-guild leak that the
  0.1.0 `wipe(pendingMessages)` approach could only handle for messages still in the
  queue. Staged messages can now outlive a queue flush and are still protected.
- **Asymmetric mode transitions.** Automatic-to-Verify captures in-flight messages;
  Verify-to-Automatic does not release staged ones. Treating the two directions
  differently is correct precisely because they carry different risk, and both halves are
  asserted in tests.
- **Fail-safe setting normalization.** Coercing an unrecognized `outgoingMode` to
  `"automatic"` on load means a corrupted profile cannot leave delivery in an undefined
  state.
- **Dedup before the mode branch.** Verify mode inherits full duplicate protection for
  free, so the review window cannot be flooded with repeats.
- **Tests that pin the non-obvious rules.** The two hardest-to-reason-about behaviors in
  the feature are exactly the two with the most pointed assertions.
- **A compile-only smoke check.** `tests/syntax.lua` is six lines and catches the single
  most embarrassing possible regression — shipping a file that does not parse. Cheap,
  and it covers all seven modules including the three nothing else loads.
- **Synthetic widget layer for offline UI testing.** A genuinely useful technique that
  moved a module out of the "in-game only" bucket, and that generalizes to `UI.lua`.

### Anti-patterns

- **Positional index binding between a UI row and a mutable list**, as described above.
- **A safety-relevant setting reset by a generic defaults handler** without the warning
  its dedicated control prints.
- **Dead state left in place** (`A.lastMessages`), now one release older.
- **Settings that exist in code but not in the UI** (`messageSpacing`, `loginCooldown`),
  now one release older.
- **Duplicated role-availability logic**, `(self.classRoles[self.playerClass] or {})[role]`
  in both `A:Initialize` and `BuildRequestUI`. Unchanged.
- **A stale steering document** that contradicts the code it is meant to guide.
- **Unpruned cache** (`A.eventsSeen`). Unchanged.

## Security Posture

Unchanged and still sound. No network surface, no credential handling, no file I/O
outside SavedVariables, no `loadstring`, no dynamic code loading, no addon-to-addon
messaging. All gear, invite, and targeting actions remain in the player's hands, so no
protected function is called from a tainted path.

The new feature slightly *improves* the posture in one respect: Verify mode gives the
user a way to run the addon with zero unattended public output while keeping every
private feature, which is a meaningful option for anyone cautious about an addon speaking
in their guild.

User-supplied template text is now clamped at four points rather than three — `A:Format`,
the `QueueGuild` entry builder, `A:SendGuild`, and `SetMaxLetters` on the edit boxes —
and is still only ever used as a chat payload, never as code or as a pattern. The one
place user-influenced text becomes a Lua pattern remains `OnSystemGuildJoin`, whose input
is a Blizzard global with its metacharacters escaped.

## Recommendations

Ordered by value relative to effort. Items marked *carried* were in the 0.1.0 list.

| # | Recommendation | Effort | Rationale |
| --- | --- | --- | --- |
| 1 | Update `.kiro/steering/testing.md` to describe all four harnesses and drop the claim that `Options.lua` cannot be tested offline | Trivial | A stale steering file misdirects every future change; the code has already outrun it |
| 2 | Make `OnDefault` either preserve `outgoingMode` or print the same warning the radio prints | Trivial | A defaults restore should not quietly re-enable unattended public messaging |
| 3 | Key approval rows by a monotonic entry id rather than a list position | Low | Removes a fragile invariant whose failure mode is sending the wrong message |
| 4 | Verify the tabard initial-check ordering in game, then fix if confirmed *(carried)* | Low | A documented feature probably never fires on login |
| 5 | Add a single runner script that executes all four harnesses and checks the three version strings agree | Low | Four harnesses and a three-place version rule is more manual pre-release work than before |
| 6 | Bring `UI.lua`'s `UpdateApprovalsUI` into the harness using the `settings.lua` widget technique | Medium | The review window is now part of the authorization path for public messages |
| 7 | Add a modest floor between consecutive approvals | Low | Closes the one spacing gap, consistent with `SendHelpRequest`'s existing self-limit |
| 8 | Test the 30-entry backlog cap, and that it drops the oldest | Low | Untested bound on a safety-relevant list |
| 9 | Remove `A.lastMessages` *(carried)* | Trivial | Dead state, two releases running |
| 10 | Expose `messageSpacing` and `loginCooldown` in Options *(carried)* | Low | Closes the gap between documented and reachable configuration |
| 11 | Make the review window's auto-show optional, or show only when it is closed and the backlog was empty | Low | Repeated popups during a busy login period will annoy |
| 12 | Add a comment noting that `pendingMessages` holds records, not strings | Trivial | Prevents a future contract trip-up |
| 13 | Bring `Tabard.lua` into the harness *(carried)* | Medium | Pure state machine behind two stubbable helpers |
| 14 | Note the profession-name fallback degradation in the README limitations *(carried)* | Trivial | A silent narrowing of craft alerts that is hard to attribute |
| 15 | Prune expired keys from `A.eventsSeen` *(carried)* | Low | Bounds session growth |
| 16 | Extract `A:CanFillRole(role)` and reuse `fillDefaults` in `OnDefault` *(carried)* | Low | Removes duplicated logic and a latent shallow-copy issue |
| 17 | Add a `.luacheckrc` and a `.gitattributes` *(partly carried)* | Low | Would catch dead state and accidental globals automatically; would also stop the LF/CRLF churn git is warning about |

None of these are blocking. The release improves on 0.1.0 in exactly the dimension that
matters most for this product, and it did so with tests. The most valuable follow-ups are
the two trivial ones at the top: the steering file and `OnDefault`.
