---
inclusion: fileMatch
fileMatchPattern: '*.lua'
---

# WoW: Forever client and API constraints

Target client: **World of Warcraft: Forever**, game version 1.60.1, TOC
`## Interface: 16001`. Beta opened 2026-09-17; the beta AddOns path on this machine is
`World of Warcraft\_classic_beta_\Interface\AddOns\`.

## The single most important fact

Forever is **not** the Classic Era client. It runs on the modern (Mainline) UI
architecture — Forever and Midnight are two game types in the same code family, and
Forever exposes the large majority of the 12.1.5-era API. Practical consequences:

- Write against **modern namespaced APIs** (`C_Timer`, `C_Map`, `C_GuildInfo`,
  `C_TradeSkillUI`, `C_Container`, `Settings`), not Vanilla-era equivalents.
  Classic-only patterns (`GuildRoster()`, `SetMapToCurrentZone`, `GetContainerItemInfo`
  as a global, XML-driven `InterfaceOptions_AddCategory`) are the wrong target.
- The **Midnight addon disarmament rules, including secret values, are active in
  Forever.** APIs that expose combat-relevant state can return secret values that addon
  code cannot inspect, and arithmetic or comparison on a secret errors. Stay out of
  combat data entirely (see the product non-goals) and never assume a returned number is
  a plain number if it comes from a unit/combat API.
- Game *content* is Vanilla 1–60: item IDs, zones, professions, and classes are
  Vanilla-era. Hence Guild Tabard `5976` and the nine-class `A.classRoles` table.

Sources, rephrased for compliance with licensing restrictions:
[Patch 1.60.1 API changes notes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes),
[Blizzard on Midnight addon changes](https://news.blizzard.com/en-us/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons),
[Forever addon overview](https://teamoverpowered.com/forever/guides/addons/).

## Chat and messaging restrictions

- `SendChatMessage` to `"SAY"`, `"YELL"`, and `"EMOTE"` requires a hardware event when
  called from addon code outside instances. `"GUILD"` is what this addon uses and is not
  under that restriction — do not move automatic messages to those channel types.
- Chat payloads are capped; keep the existing 250-character clamp.
- Trial accounts cannot send addon messages.
- Creature/vehicle/pet/object GUIDs now carry obfuscated server and spawn ID portions.
  They stay stable and unique within a session, so GUID equality for identity (what
  `A:IsSelf` does with the player GUID) is fine; never parse or compare GUID fragments
  to infer layer or realm.

## Beta volatility — code defensively

Blizzard is still changing this client, and the Forever default frames have already been
reskinned and reorganized once. Therefore:

- Feature-detect before every call to a Blizzard API or global, including ones you
  believe exist. The codebase already does this for `C_GuildInfo`, `C_TradeSkillUI`,
  `C_Map`, `GetInventoryItemID`, `PlaySound`, `SOUNDKIT`, `ToggleCharacter`, `Settings`.
- Degrade gracefully with a `A:Print` note instead of erroring (see
  `A:BuildOptions` when the Settings API is missing).
- Do not anchor to or reskin Blizzard's Forever unit frames or minimap header; they are
  moving targets.
- `Forever` is accepted as an alias for `Camelot` in TOC suffixes, the `[Game]` variable,
  and game-type folder lookup. If multi-client support is ever needed, prefer the
  `## AllowLoadGameType` directive over duplicating TOC files.
- Treat any API behavior not verified in a live client as unverified, and say so in the
  README limitations section rather than claiming it works.

## Taint and protected code

Addon code is tainted. Never call protected functions or modify protected frames from a
non-hardware-event path, never `loadstring` user input, and keep all gear, invite, and
targeting actions in the player's hands (see product non-goals). Securely-templated
buttons are the only acceptable route if a protected action is ever genuinely required.

## Reporting a client-side bug

Capture: the exact Lua error with `/console scriptErrors 1` then `/reload`, the event
that triggered it, and the build from `/dump select(4, GetBuildInfo())`.
