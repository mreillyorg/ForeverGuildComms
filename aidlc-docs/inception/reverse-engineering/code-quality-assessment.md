# Code Quality Assessment

**Analysis target**: Forever Guild Comms **0.4.3-beta**
**Supersedes**: the 0.4.1-beta pass of 2026-10-19T02:40:00Z

## Summary

This is the strongest pass yet. 0.4.2 added a feature; 0.4.3 went back and fixed two
defects that had been carried in every previous review. Both landed with a regression
harness, and one of them — the tabard login-ordering race — had been an unverified
inference across three passes and is now reproduced explicitly in a test.

Shipped Lua grew 17% (1,733 to 2,022 lines) while test code grew 36% (589 to 799), taking
coverage to 40% of shipped source. **For the first time every module is loaded by at least
one harness**: `Tabard.lua` was the last gap and `tests/tabard_dedup.lua` closes it.

Three of the four items at the top of the previous recommendation list are now done. The
remaining top item is unchanged and is the one thing that keeps recurring: the project has
an accurate, documented eleven-harness suite and a release pipeline that does not run it.

The new feature is also notable for what it does *not* do. Varying message wording creates
a failure mode that did not previously exist — the preview and the sent message could
diverge — and the implementation closes it with a fingerprinted draft cache before shipping
rather than after a bug report.

## Status of the Previous Recommendations

| # | 0.4.1 recommendation | Status at 0.4.3 |
| --- | --- | --- |
| ~~1~~ | Update `.kiro/steering/testing.md` | **RESOLVED** immediately after that pass. Now accurate, though it predates the two new harnesses and does not list them |
| 1 | Add a test job to CI, or a runner script, that runs every harness and checks the three version strings | **Not done.** Now the longest-standing open item, and the suite it would run has grown to eleven files |
| 2 | Make `OnDefault` preserve `outgoingMode` and voice settings, or warn | **Not done.** Still resets both silently, and still contains the duplicated `UpdateRequestPreview` line |
| 3 | Assert that `.pkgmeta` does not exclude `Bindings.xml` | **Not done** |
| 4 | Bring `Tabard.lua` into the harness | **RESOLVED.** `tests/tabard_dedup.lua`, 117 lines |
| 5 | Verify the tabard initial-check ordering, then fix if confirmed | **RESOLVED in code.** `A:CheckTabard` restructured and the race reproduced in a test. See the caveat below: the fix is verified against the *simulated* ordering, not against a live client |
| 6 | Key approval rows by a monotonic id | **Not done.** `row.entryIndex` still positional |
| 7 | Remove the duplicated `UpdateRequestPreview` line in `OnDefault` | **Not done** |
| 8 | Drive `UpdateApprovalsUI` in a harness | **Partly.** `tests/variations.lua` now drives real `UI.lua` logic (`RequestText`, `UpdateRequestPreview`, `ShowRequest`, `SendHelpRequest`), but the approvals and alerts rendering is still undriven |
| 9 | Clarify that Subtle applies no flair prefix | **Not done** |
| 10 | Test the backlog cap, a 3-4 byte `ChatLimit` case, and the `expressive` punctuation branch | **Not done** |
| 11 | Add a floor between consecutive approvals | **Not done** |
| 12 | Add `.luacheckrc` | **Not done** |
| 13 | Make the review window's auto-show optional | **Not done** |
| 14 | Comment that `pendingMessages` holds records | **Not done** |
| 15 | Note the profession-name fallback in README limitations | **Not done** |
| 16 | Move the README keybindings section below the byline | **Not done** |
| ~~17~~ | Prune expired keys from `A.eventsSeen` | **RESOLVED.** `A:PruneEventsSeen` with a two-source sweep |
| 18 | Extract `A:CanFillRole`, reuse `fillDefaults` in `OnDefault` | **Not done** |

Three resolved this span, one partly. Counting across all four passes, the two oldest
findings in the project — both first reported against 0.1.0 — are now closed.

## Test Coverage

- **Overall**: Good. Eleven harnesses, 799 lines, every module loaded by at least one.
- **This rating comes from reading the harnesses, not running them.** No Lua interpreter is
  installed on this machine, so none of the eleven was executed during this pass. The
  project's own testing rule requires stating this.

### The two new harnesses

**`tests/tabard_dedup.lua` (117 lines) is the most valuable test added to this project so
far**, because it encodes a bug that three reviews could only infer. It drives
`ScheduleTabardCheck`, asserts the scheduled delay is 1.2 seconds, fires that callback, and
confirms it initialises `wasInCity` *without* prompting — then calls `CheckTabard(true)` and
asserts a prompt still appears. That is precisely the race: the test would have failed
against the 0.4.1 code. It continues through per-stay deduplication, city exit with the
tabard equipped, re-entry without it, and the reverse ordering where a transition check
prompts before the login check and must not produce a second prompt.

Its second half covers the dedup cache: retention across a cooldown increase, the 60-second
sweep throttle (asserting an entry survives at 4599 and is gone at 4659), full drainage,
re-admission after expiry, and disposal of malformed and future-dated values. It then loads
a second namespace, runs `Initialize`, and asserts the 300-second idle ticker is registered
and prunes. Thorough.

**`tests/variations.lua` (93 lines) is unusually exhaustive for its size.** It loops every
language and every kind, drawing twice the bag size and asserting no repeat within a bank,
no adjacent repeat, no unfilled placeholder, and that the activity and level values survive.
It then loops all 29 accents asserting each has variants for all four kinds — making a
missing entry a test failure rather than a silent fallback — and that two consecutive draws
differ. Finally it covers the non-consuming Settings preview, the custom-template override
with a real item hyperlink, the disabled setting, and the preview/send stability contract
including that reopening the composer advances the wording.

### Remaining coverage gaps, ranked

1. **No CI runs any of this.** Unchanged and now the top item overall.
2. **The approvals and alerts window rendering is still undriven.** `UpdateApprovalsUI`'s
   paging, clamping, and positional row binding remain untested, and that binding is still
   on the open findings list.
3. **The 30-entry approval backlog cap is untested**, including that it drops the oldest.
4. **`wipe(pendingMessages)` when `CanUse` turns false** remains uncovered.
5. **`A:IsSelf` realm handling and the suspicious-roster-read guard** remain untested,
   carried since 0.1.0.
6. **`A:ChatLimit` is still tested only on a two-byte character.** A three- or four-byte
   sequence would exercise the backtracking loop more than one iteration deep.
7. **The `expressive` punctuation branch** is still unasserted.
8. **Shuffle-bag distribution is unexamined.** The harness proves the structural properties
   but not that draws are well distributed, and `math.random` is never seeded.

## Code Quality Indicators

- **Linting**: still no `.luacheckrc`. `.gitattributes` continues to hold line endings.
- **Code Style**: consistent. `MessageVariants.lua` follows the house pattern, and its
  long single-line data records are the same defensible deviation `Accents.lua` already
  made — uniform literals read better unwrapped. `A:ChooseMessageTemplate` is compact and
  flat.
- **Documentation**: good and still maintained in step. The README gained a dedicated
  "Maintenance fixes in 0.4.3-beta" section describing both fixes in user terms, and the
  0.4.2 feature entry explains the shuffle bag, states the default plainly, and notes that
  custom templates are deliberately excluded. Comments continue to explain *why*: the
  retention-window rationale, the `PLAYER_ENTERING_WORLD` ordering note, the
  "Send must send exactly the preview" requirement, and the "vary sentence structure rather
  than randomly replacing syllables" boundary.
- **Error handling**: good, and improved. The new pruning code defends against three
  distinct bad inputs (non-numeric, future-dated, expired), and `IsDuplicate` gained a
  clock-regression guard. `ChooseMessageTemplate` filters non-strings and empties out of its
  candidate list and degrades to the base template when fewer than two candidates exist.
- **Global hygiene**: unchanged. No new globals.
- **Control flow**: good. The restructured `A:CheckTabard` is slightly denser than before
  but reads as two clear branches with named conditions (`firstLoginCheck`, `enteredCity`)
  rather than nested early returns.

### Observation: the fixes were made defensively rather than minimally

Both 0.4.3 fixes could have been narrower, and both chose the safer option:

| Fix | Minimal version | What was done |
| --- | --- | --- |
| Tabard ordering | Make the initial check run before the transition check | Made the initial check *order-independent*, plus added per-stay deduplication so neither path can double-prompt regardless of sequence |
| Cache pruning | Delete entries older than the configured cooldown | Retain the longest *supported* cooldown, so raising `loginCooldown` later cannot re-admit a suppressed event; plus two sweep triggers covering busy and idle sessions; plus disposal of malformed and future timestamps |

The retention choice is the more interesting one. Using the configured cooldown would have
been the obvious implementation and would have been subtly wrong in a way no test would
likely have caught.

## Technical Debt

### New in this span

#### `randomizeMessages` defaults to on, changing existing output
Every prior optional feature defaulted to preserving existing behaviour — `outgoingMode`
to `automatic`, `accent` to `none`, and the README said so explicitly for 0.4.0. This one
defaults to `true`, so an existing user's greetings start varying after the upgrade. The
change is confined to curated text that still honours their language and accent, and the
README documents the default openly, so this reads as a deliberate product decision. It is
recorded here because it is the first break in an otherwise consistent convention, and
because a user who had settled on specific wording will see it change without acting.

#### `math.random` is never seeded
`A:ChooseMessageTemplate` is the project's first use of randomness and does not call
`math.randomseed`. In practice the WoW client's Lua state makes this a non-issue for
message variety, and the exhaust-before-repeat property does not depend on distribution.
Worth a one-line comment so a future reader does not go looking for the seed.

#### `A.messageVariantBags` is unbounded in principle
It accumulates one bag per `kind:language:accentId` combination used in a session. The
realistic ceiling is small — four kinds times the handful of language and accent
combinations a player actually switches between — and each bag holds a short integer array.
Not a practical concern, but it is now the only structure in the addon without an explicit
bound, which is a notable distinction given 0.4.3 was spent adding one to the other.

#### The `tests/syntax.lua` module list is maintained by hand
It was correctly updated to include `MessageVariants.lua`, but it duplicates the TOC's file
list in a second place. A future module added to the TOC and not here would compile-check
silently. Reading the TOC and deriving the list would remove the duplication — the
installer already does exactly that parse.

### Carried forward unchanged

- **`OnDefault`** still silently resets `outgoingMode` and all four voice settings, still
  copies one level deep, and still contains the duplicated `UpdateRequestPreview` call.
- **Positional approval-row binding.** `row.entryIndex` remains a list position. Safe today
  because every mutation refreshes the UI, but undocumented and its failure mode is sending
  the wrong message.
- **No rate limit on approvals.**
- **`ShowApprovals` fires on every staged message.**
- **`.pkgmeta` retention of `Bindings.xml` is unasserted.**
- **`A.GetActivityType`** is still a dot-called closure.
- **Duplicated role-availability logic** in `A:Initialize` and `BuildRequestUI`.
- **`pendingMessages` holds records, not strings**, still uncommented.
- **The profession-name fallback** still collapses professions into one bucket when the
  skill-line APIs are missing, still undocumented in the README limitations.
- **`subtle` applies no flair prefix**, which the label does not convey.
- **No `.luacheckrc`.**
- **README section ordering** leaves the byline orphaned below the keybindings block.

### Resolved, with credit

- **The tabard login-ordering race**, first flagged against 0.1.0 and inferred across three
  passes, is fixed and reproduced in a test.
- **The unbounded `A.eventsSeen` cache**, also flagged against 0.1.0, is now pruned by two
  complementary triggers with a deliberately chosen retention window.
- **`Tabard.lua` is no longer untested.** Every module now has a harness.
- **`.kiro/steering/testing.md`** was corrected immediately after the previous pass.

## Patterns and Anti-patterns

### Good Patterns

Carried forward and intact: everything recorded in the previous pass. New this span:

- **Shuffle bag with cross-bag memory.** Exhaust-before-repeat within a bag plus
  no-adjacent-repeat across bag boundaries, with self-invalidation when the candidate count
  changes. A small, correct piece of work that avoids the usual "random feels clumpy"
  complaint without any statistical machinery.
- **Fingerprinted draft caching.** The new feature created the possibility that the
  approved preview and the sent message differ; the fix is a cache keyed on everything that
  could change the output, cleared at the two points where a fresh choice is wanted. The
  comment states the requirement as a rule rather than describing the code.
- **A non-consuming preview path.** Threading a `preview` flag through two functions so the
  Settings sample cannot perturb session state is a small detail that would have been easy
  to miss and annoying to diagnose.
- **Retention chosen against the supported range, not the configured value.** Protects
  against a setting change re-admitting a suppressed event.
- **Two sweep triggers for two regimes.** An activity-throttled sweep for busy sessions and
  an idle ticker for quiet ones, rather than picking one and accepting the other's failure.
- **Clock-regression hardening.** `now >= seenAt` guards plus disposal of future-dated
  entries, anticipating `GetTime` discontinuity across a reload.
- **A test that encodes the bug, not just the fix.** `tabard_dedup.lua` reconstructs the
  original event ordering, so the test would fail against the previous implementation.
- **Completeness asserted rather than assumed.** `variations.lua` requires every accent to
  have variants for every kind, converting a silent fallback into a failure.
- **A decoupled data module.** `MessageVariants.lua` takes the base template and resolved
  accent as arguments instead of reading its siblings' tables, making it independently
  removable.

### Anti-patterns

- **A default that changes existing behaviour**, breaking the project's own convention.
- **A hand-maintained duplicate of the TOC file list** in `tests/syntax.lua`.
- **A generic defaults handler resetting safety-relevant and per-character state** without
  a warning, plus a duplicated statement inside it.
- **Positional index binding between a UI row and a mutable list.**
- **An unasserted packaging invariant** (`.pkgmeta` retaining `Bindings.xml`).
- **Automated release with no automated verification.**
- **Duplicated role-availability logic.**

## Security Posture

Unchanged and still sound. No network surface, no credential handling, no file I/O outside
SavedVariables, no `loadstring` in shipped code, no addon-to-addon messaging. All gear,
invite, and targeting actions remain in the player's hands.

The new feature does not widen the surface: variants are static table entries substituted
wholesale, with no pattern matching, evaluation, or transformation of user text. The
customized-template short-circuit means authored content — including item links — is never
touched, which `tests/variations.lua` asserts with a real hyperlink.

One observation on the pruning code: it iterates `A.eventsSeen` with `pairs` while
assigning `nil` to keys inside the loop. That is explicitly permitted in Lua for the
current key, so it is correct, not merely working by accident.

## Recommendations

Ordered by value relative to effort. *(carried)* marks items from the 0.4.1 list.

| # | Recommendation | Effort | Rationale |
| --- | --- | --- | --- |
| 1 | Add a test job to `package.yml`, or a runner script, that runs all eleven harnesses and checks the three version strings *(carried, was #1)* | Low | The longest-standing open item. A tag publishes a release with zero automated verification, and there are now eleven dependency-free suites it could run |
| 2 | Add the two new harnesses to `.kiro/steering/testing.md` | Trivial | The document was corrected last pass but predates `tabard_dedup.lua` and `variations.lua`. Keeping it current is cheaper than a periodic rewrite |
| 3 | Confirm the tabard fix in a live client | Low | The fix is defensive enough to be correct under either event ordering, but the ordering itself has never been observed. One login in a capital city settles it |
| 4 | Make `OnDefault` preserve `outgoingMode` and voice settings, and remove its duplicated line *(carried, was #2 and #7)* | Trivial | Restore Defaults silently re-enables unattended public messaging and discards language choices |
| 5 | Derive `tests/syntax.lua`'s module list from the TOC | Low | Removes a hand-maintained duplicate that fails silently |
| 6 | Assert that `.pkgmeta` does not exclude `Bindings.xml` *(carried, was #3)* | Trivial | Prevents an asymmetric failure where the automated channel ships without keybindings |
| 7 | Key approval rows by a monotonic id *(carried, was #6)* | Low | Removes a fragile undocumented invariant whose failure mode is sending the wrong message |
| 8 | Drive `UpdateApprovalsUI` in a harness *(carried, was #8)* | Medium | The review window is part of the authorization path for public messages, and item 7 would be safer with a test behind it |
| 9 | Note in the README that `randomizeMessages` changes existing wording on upgrade | Trivial | The default is documented; the fact that it differs from prior convention is not |
| 10 | Seed `math.random`, or comment that seeding is intentionally omitted | Trivial | Removes a question a future reader will have |
| 11 | Test the approval backlog cap, a 3-4 byte `ChatLimit` case, and the `expressive` branch *(carried, was #10)* | Low | Three small gaps in otherwise strong coverage |
| 12 | Add a floor between consecutive approvals *(carried, was #11)* | Low | The one remaining spacing gap |
| 13 | Add `.luacheckrc` *(carried, was #12)* | Low | Would catch the duplicated line and guard against accidental globals |
| 14 | Clarify that Subtle applies no flair prefix *(carried, was #9)* | Trivial | The label implies a light touch, not absence |
| 15 | Make the review window's auto-show optional *(carried, was #13)* | Low | Repeated popups during a busy login period |
| 16 | Comment that `pendingMessages` holds records *(carried, was #14)* | Trivial | Prevents a contract trip-up |
| 17 | Note the profession-name fallback in README limitations *(carried, was #15)* | Trivial | A silent narrowing of craft alerts |
| 18 | Move the README keybindings section below the byline *(carried, was #16)* | Trivial | The byline is orphaned |
| 19 | Extract `A:CanFillRole`, reuse `fillDefaults` in `OnDefault` *(carried, was #18)* | Low | Removes duplication and a latent shallow-copy issue |

None are blocking. Six releases in, the pattern is consistent: features extend the safety
model rather than straining it, and review findings get closed — the two oldest in the
project were closed this span. The top item has now been the same for three passes, and it
is the cheapest of the lot: the suite exists, is documented, and has no dependencies. It
just needs something to run it.
