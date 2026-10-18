local _, A = ...

local function MakeLabel(parent, text, x, y, width, style)
    local label = parent:CreateFontString(nil, "OVERLAY", style or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 505)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end
local function MakeButton(parent, name, x, y, width, func)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetSize(width, 24)
    btn:SetText(name)
    btn:SetScript("OnClick", func)
    return btn
end
function A:BuildOptions()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then
        self:Print("Modern Settings API unavailable; options page not registered.")
        return
    end
    local panel = CreateFrame("Frame", "ForeverGuildCommsOptionsPanel")
    panel:SetSize(600, 510)
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(540, 1050)
    scroll:SetScrollChild(content)

    local controls = {}
    local edits = {}
    MakeLabel(content, "Forever Guild Comms", 16, -10, 500, "GameFontNormalLarge")
    MakeLabel(content, "Guild chat messages are automatic; crafting/LFG alerts are private.",
        16, -39, 510, "GameFontHighlightSmall")
    local y = -77
    local function section(text)
        MakeLabel(content, text, 16, y, 510, "GameFontNormal")
        y = y - 28
    end
    local function toggle(key, title, description)
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(25, 25)
        cb:SetPoint("TOPLEFT", 17, y)
        cb:SetChecked(A.db[key] and true or false)
        cb:SetScript("OnClick", function(self) A.db[key] = self:GetChecked() end)
        controls[#controls+1] = function() cb:SetChecked(A.db[key] and true or false) end
        MakeLabel(content, title, 47, y-4, 480, "GameFontHighlight")
        y = y - 26
        if description then
            MakeLabel(content, description, 47, y+1, 482, "GameFontHighlightSmall")
            y = y - 24
        end
    end
    local function template(key, title, hint)
        MakeLabel(content, title, 19, y, 500, "GameFontHighlight")
        y = y - 25
        local eb = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT", 29, y)
        eb:SetSize(477, 25)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(250)
        eb:SetText(A.db.templates[key])
        eb:SetScript("OnEditFocusLost", function(self)
            A.db.templates[key] = self:GetText()
            if A.UpdateRequestPreview then A:UpdateRequestPreview() end
        end)
        eb:SetScript("OnEnterPressed", eb.ClearFocus)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText(A.db.templates[key])
            self:ClearFocus()
        end)
        edits[key] = eb
        controls[#controls+1] = function()
            if not eb:HasFocus() then eb:SetText(A.db.templates[key]) end
        end
        y = y - 29
        MakeLabel(content, hint, 29, y, 494, "GameFontHighlightSmall")
        y = y - 27
    end
    section("General")
    toggle("enabled", "Enable addon", "Disabling stops guild chat messages and private monitoring.")
    section("Automatic guild messages")
    toggle("greetLogin", "Greet guild members when they log in", "Only offline -> online changes after the initial guild roster snapshot.")
    toggle("greetJoin", "Welcome newly joined guild members", "Uses the localized guild-join system message; duplicate protected.")
    toggle("congratulateLevel", "Congratulate guild members on leveling", "Only online-to-online level changes. Your character is ALWAYS excluded.")
    section("Private guild requests")
    toggle("craftingAlerts", "Alert when a guildmate needs an item I can craft", "Open each profession to cache known recipes; exact item-name matching.")
    toggle("groupAlerts", "Alert on LFG / LFM / LF group requests", "Reads guild chat only. Use the Alerts window to whisper manually.")
    toggle("alertsSound", "Play sound for private alerts")
    section("Guild tabard")
    toggle("tabardInCity", "Remind me to wear my guild tabard in capital cities", "Supports classic Guild Tabard (item 5976); never equips automatically.")
    toggle("tabardOnExit", "Ask about removing the tabard when leaving a city", "Optional; opens the character equipment page for manual removal.")
    section("Custom messages")
    MakeLabel(content, "Variables: {name}, {level}, {type}, {activity}, {myroles}, {needed}",
        18, y, 510, "GameFontHighlightSmall")
    y = y - 24
    template("login", "Guild login greeting", "Variables: {name}, {level}")
    template("join", "New guild member welcome", "Variables: {name}")
    template("level", "Level-up congratulations", "Variables: {name}, {level}")
    template("help", "Manual guild help request", "Variables: {type}, {activity}, {myroles}, {needed}, {name}")
    section("Quick actions")
    MakeButton(content, "Alerts", 20, y, 110, function() A:ShowAlerts() end)
    MakeButton(content, "Ask for help", 145, y, 140, function() A:ShowRequest() end)
    MakeButton(content, "Rescan profession", 300, y, 180, function()
        A:ScanRecipes()
        A:Print("Current open profession scanned, if available. /fgc recipes shows the count.")
    end)
    y = y - 42
    MakeLabel(content, "Role selection (Tank / Healer / DPS) is in the Ask for Help window.",
        18, y, 500, "GameFontHighlightSmall")
    y = y - 25
    MakeLabel(content, "Automatic messages are queued at least 6 seconds apart.",
        18, y, 500, "GameFontHighlightSmall")
    content:SetHeight(math.max(950, -y+40))
    function panel.OnRefresh()
        for _, fn in ipairs(controls) do fn() end
    end
    function panel.OnCommit()
        for key, edit in pairs(edits) do
            A.db.templates[key] = edit:GetText()
            edit:ClearFocus()
        end
        if A.UpdateRequestPreview then A:UpdateRequestPreview() end
    end
    function panel.OnDefault()
        -- Defaults are applied explicitly, then reflected in the controls.
        for k, value in pairs(A.defaults) do
            if type(value) == "table" then
                A.db[k] = {}
                for sub, v in pairs(value) do A.db[k][sub] = v end
            else A.db[k] = value end
        end
        panel.OnRefresh()
        if A.UpdateRequestPreview then A:UpdateRequestPreview() end
    end
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Forever Guild Comms")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
