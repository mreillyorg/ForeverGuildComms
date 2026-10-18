---
inclusion: auto
name: ui-frames
description: Frame, widget, and Settings-panel conventions for Forever Guild Comms. Use when editing UI.lua or Options.lua, or when adding windows, buttons, checkboxes, edit boxes, popups, or options controls.
---

# UI and options conventions

All UI is built in Lua at `PLAYER_LOGIN` time from `A:Initialize` → `A:BuildUI` /
`A:BuildOptions`. There is no XML, no layout library, and no texture files — Blizzard
templates and manual offsets only.

## Local widget helpers

Each UI file defines its own small constructors near the top and uses them everywhere
instead of repeating `CreateFrame` boilerplate:

- `UI.lua`: `Label(parent, text, x, y, width, size)`, `Button(parent, text, x, y, width, callback)`,
  `Check(parent, title, x, y, checked, onClick)`
- `Options.lua`: `MakeLabel`, `MakeButton`, plus the panel-scoped `section`, `toggle`,
  and `template` closures that advance a running `y` cursor

Add a new control type by extending these helpers rather than hand-rolling a frame in the
middle of a layout function.

## Templates in use — stay with them

| Need | Template |
| --- | --- |
| Window | `BasicFrameTemplateWithInset` |
| Button | `UIPanelButtonTemplate` |
| Checkbox | `UICheckButtonTemplate` |
| Text input | `InputBoxTemplate` |
| Scrolling options panel | `UIPanelScrollFrameTemplate` + a sized child frame |
| Confirmations | `StaticPopupDialogs` with `timeout = 0`, `whileDead = false`, `hideOnEscape = true`, `preferredIndex = 3` |

## Layout rules

- Anchor with `SetPoint("TOPLEFT", x, y)` and negative `y`, matching the existing
  coordinate math. Windows use `SetPoint("CENTER")`.
- Font strings: `CreateFontString(nil, "OVERLAY", style)` with `GameFontNormal`,
  `GameFontNormalLarge`, `GameFontHighlight`, `GameFontNormalSmall`, or
  `GameFontHighlightSmall`; always `SetWidth` and `SetJustifyH("LEFT")`.
- Windows are movable: `SetMovable(true)`, `EnableMouse(true)`,
  `RegisterForDrag("LeftButton")`, `StartMoving`/`StopMovingOrSizing`, strata `DIALOG`.
- Build every window hidden (`frame:Hide()`) and show it from a `/fgc` command, an
  options button, or the broker click.
- Alert rows are a **fixed pool of 7 reused frames** with Prev/Next paging — never create
  frames per alert.
- In `Options.lua`, let the `section`/`toggle`/`template` closures manage the `y` cursor
  and finish with `content:SetHeight(math.max(950, -y+40))` so the scroll child grows
  with new controls.

## Edit box behavior

`SetAutoFocus(false)`, `SetMaxLetters(...)`, commit on `OnEditFocusLost`, clear focus on
`OnEnterPressed`, and revert to the stored value on `OnEscapePressed`. Any edit that
feeds a chat template calls `A:UpdateRequestPreview` so the preview stays truthful.

## Settings registration

Use the modern API: `Settings.RegisterCanvasLayoutCategory` +
`Settings.RegisterAddOnCategory`, storing the category on `A.settingsCategory` for
`A:OpenSettings`. Guard the whole thing — if `Settings.RegisterCanvasLayoutCategory` is
missing, print a note and skip registration instead of erroring.

Implement all three canvas callbacks:

- `panel.OnRefresh` — push `A.db` values into the controls (the `controls` closure list)
- `panel.OnCommit` — flush edit boxes into `A.db.templates`
- `panel.OnDefault` — copy `A.defaults` back into `A.db`, then refresh

## Settings write directly to the DB

Toggles assign to `A.db[key]` on click; there is no apply/cancel buffer. Keep that
model, and keep every option's description honest about what the feature will and will
not do (for example, that the tabard reminder never equips anything).

## Preview before send

Any feature that sends to guild chat from the UI must show the exact text first
(`A:RequestText` → `A.requestPreview`) and require a deliberate button press.
