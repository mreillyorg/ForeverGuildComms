# Forever Guild Comms — product context

Guild social/communication addon for **World of Warcraft: Forever** (client 1.60.1,
Interface `16001`), author Michael Reilly, currently `0.1.0-beta`.

## What it does

- Greets guildmates on offline → online transitions, welcomes new members, congratulates
  level-ups of *other* members.
- Private (self-only) alerts for guild-chat crafting requests matching cached known
  recipes, and for LFG/LFM group requests.
- Tabard reminders on entering/leaving capital cities.
- An "Ask for Help" compose window that sends one explicit guild request.
- Optional LibDataBroker/Titan Panel indicator.

## Non-goals — do not implement these

These are deliberate product constraints, not missing features. Do not add them without
the user explicitly asking.

- **No automation of player actions.** Never equip, unequip, or swap gear; never accept
  invites, never auto-whisper, never auto-reply, never queue for content. The tabard
  feature opens the character panel and nothing more.
- **No congratulations for the player's own level-up.** This is a headline behavior; the
  self-exclusion checks in `A:IsSelf` and `A:AcceptRoster` exist for it.
- **No scanning of channels other than guild chat** for alerts.
- **No combat, DPS, threat, or encounter features.** The Forever client secrets the data
  and it is outside the addon's purpose.
- **No hard library dependencies.** Titan/LibDataBroker is optional and detected at
  runtime; the addon must work fully without it.
- **No addon-to-addon comms** (`C_ChatInfo.SendAddonMessage`) unless the user asks for it.

## Voice of user-facing strings

Plain, short, friendly. Chat messages are templates with `{name}`, `{level}`, `{type}`,
`{activity}`, `{myroles}`, `{needed}` placeholders, user-editable in Settings. Prefix
console output through `A:Print` so everything carries the addon tag. Keep default
templates and option text in English; there is no localization layer yet.
