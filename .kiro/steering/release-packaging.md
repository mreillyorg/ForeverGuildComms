---
inclusion: auto
name: release-packaging
description: TOC metadata, version bumping, SavedVariables migration, and packaging rules for Forever Guild Comms releases. Use when editing the .toc, changing the version, adding saved settings, or preparing a distributable zip.
---

# TOC, versioning, and packaging

## TOC rules

`ForeverGuildComms.toc` must keep:

- `## Interface: 16001` — the Forever 1.60.1 interface number. Do not change it to a
  Classic Era or retail value.
- `## SavedVariables: ForeverGuildCommsDB` and
  `## SavedVariablesPerCharacter: ForeverGuildCommsCharDB`.
- `## OptionalDeps: Titan` — optional, never `RequiredDeps`.
- The file list in dependency order, `Core.lua` first.
- `## Version` identical to `A.version` in `Core.lua` and the heading in `README.md`.

Every new `.lua` source file must be added to the TOC, and nothing that is not shipped
code should be listed (`tests/smoke.lua` stays out).

## Version bumps

Three places move together: the TOC `## Version`, `A.version` in `Core.lua`, and the
`README.md` title line. The distributable folder name has carried the version in the
parent directory (`ForeverGuildComms-0.1.0-beta/ForeverGuildComms`), but the **inner
folder must always be exactly `ForeverGuildComms`** or the client will not find the TOC.

While the client is in beta, keep the `-beta` suffix and keep the README's "Limitations
and testing notes" section current — it is the honest record of what has not been
verified in a live client.

## SavedVariables compatibility

- Add new settings to `A.defaults` in `Core.lua`. `fillDefaults` backfills missing keys
  recursively on load, so existing users keep their choices.
- Never rename or repurpose an existing key without a migration step in `A:Initialize`.
- Per-character data (`A.char`): `recipes`, `myRoles`, `needRoles`. Keep the recipe cache
  per character — professions are character-specific.
- Defaults must be the safe choice: new automatic chat features default to the
  conservative setting, and anything that could surprise the user (like
  `tabardOnExit`) defaults to `false`.

## Packaging

Ship a zip whose contents extract to `AddOns\ForeverGuildComms\`. Include the `.lua`
sources, the `.toc`, `README.md`, and `LICENSE`. Exclude `.git`, `.kiro`, and `tests`.
No binaries, no embedded libraries — `.gitignore` already blocks compiled and archive
artifacts, and the Titan/LibDataBroker integration deliberately uses Titan's own copy via
`LibStub("LibDataBroker-1.1", true)`.

## Pre-release pass

1. Offline smoke tests run and print `PASSED`.
2. Version strings match in all three places.
3. Every source file is in the TOC, and load order is still correct.
4. README features, commands, templates, and limitations reflect the code.
5. The in-game checklist has been walked, or the gaps are written down as limitations.
