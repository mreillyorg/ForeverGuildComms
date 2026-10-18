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
    local numericEdits = {}
    local addonIcon = content:CreateTexture(nil, "ARTWORK")
    addonIcon:SetSize(48, 48)
    addonIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -10)
    addonIcon:SetTexture("Interface\\AddOns\\ForeverGuildComms\\Media\\Icon")
    MakeLabel(content, "Forever Guild Comms", 75, -10, 430, "GameFontNormalLarge")
    MakeLabel(content, "Choose automatic greetings or review each before sending. Guild alerts remain private.",
        75, -39, 445, "GameFontHighlightSmall")
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
        cb:SetScript("OnClick", function(self) A:SetOption(key, self:GetChecked() and true or false) end)
        controls[#controls+1] = function() cb:SetChecked(A.db[key] and true or false) end
        MakeLabel(content, title, 47, y-4, 480, "GameFontHighlight")
        y = y - 26
        if description then
            MakeLabel(content, description, 47, y+1, 482, "GameFontHighlightSmall")
            y = y - 24
        end
    end
    local function timingOption(key, title, description)
        local limits = A.timingLimits[key]
        MakeLabel(content, title, 19, y, 495, "GameFontHighlight")
        y = y - 26
        local eb = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT", 29, y)
        eb:SetSize(95, 25)
        eb:SetAutoFocus(false)
        eb:SetNumeric(true)
        eb:SetMaxLetters(5)
        eb:SetText(tostring(A.db[key]))
        local function apply()
            local raw = eb:GetText()
            -- Empty or malformed input keeps the current saved number.
            A:SetOption(key, raw)
            eb:SetText(tostring(A.db[key]))
        end
        eb:SetScript("OnEditFocusLost", apply)
        eb:SetScript("OnEnterPressed", function(self)
            apply()
            self:ClearFocus()
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText(tostring(A.db[key]))
            self:ClearFocus()
        end)
        MakeLabel(content, "seconds", 140, y-4, 100, "GameFontHighlightSmall")
        MakeButton(content, "Use default", 407, y, 105, function()
            A:SetOption(key, A.defaults[key])
            eb:SetText(tostring(A.db[key]))
            eb:ClearFocus()
        end)
        numericEdits[#numericEdits+1] = apply
        controls[#controls+1] = function()
            if not eb:HasFocus() then eb:SetText(tostring(A.db[key])) end
        end
        y = y - 30
        MakeLabel(content, description .. " (" .. limits.min .. "–" .. limits.max .. " seconds; default: " .. A.defaults[key] .. ")",
            29, y, 490, "GameFontHighlightSmall")
        y = y - 30
    end
    local function outgoingMode()
        MakeLabel(content, "Guild greetings and congratulations:", 19, y, 495, "GameFontHighlight")
        y = y - 27
        local radios = {}
        for i, choice in ipairs({{key="automatic", title="Automatic"},
                {key="verify", title="Verify with a click"}}) do
            local cb = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("TOPLEFT", 22+(i-1)*210, y)
            MakeLabel(content, choice.title, 53+(i-1)*210, y-3, 195, "GameFontHighlight")
            cb:SetScript("OnClick", function()
                A:SetOption("outgoingMode", choice.key)
            end)
            radios[#radios+1] = {button=cb, key=choice.key}
        end
        controls[#controls+1] = function()
            for _, entry in ipairs(radios) do
                entry.button:SetChecked(entry.key == A.db.outgoingMode)
            end
        end
        controls[#controls]()
        y = y - 30
        MakeLabel(content, "Automatic posts to guild chat. Verify opens a private review window with Send and Dismiss buttons.",
            46, y, 485, "GameFontHighlightSmall")
        y = y - 42
    end
    local function template(key, title, hint)
        MakeLabel(content, title, 19, y, 500, "GameFontHighlight")
        y = y - 25
        local eb = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT", 29, y)
        eb:SetSize(363, 25)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(250)
        eb:SetText(A.db.templates[key] or A.defaults.templates[key])
        eb:SetScript("OnEditFocusLost", function(self)
            A.db.templates[key] = self:GetText()
            if A.UpdateRequestPreview then A:UpdateRequestPreview() end
        end)
        eb:SetScript("OnEnterPressed", eb.ClearFocus)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText(A.db.templates[key])
            self:ClearFocus()
        end)
        MakeButton(content, "Use default", 407, y, 105, function()
            A.db.templates[key] = A.defaults.templates[key]
            eb:SetText(A.defaults.templates[key])
            eb:ClearFocus()
            if A.UpdateRequestPreview then A:UpdateRequestPreview() end
        end)
        edits[key] = eb
        controls[#controls+1] = function()
            if not eb:HasFocus() then eb:SetText(A.db.templates[key]) end
        end
        y = y - 32
        MakeLabel(content, "Default: " .. A.defaults.templates[key], 29, y, 490, "GameFontHighlightSmall")
        y = y - (key == "help" and 37 or 25)
        MakeLabel(content, hint, 29, y, 494, "GameFontHighlightSmall")
        y = y - 30
    end
    section("General")
    toggle("enabled", "Enable addon", "Disabling stops guild chat messages and private monitoring.")
    section("Outgoing guild messages")
    outgoingMode()
    toggle("greetLogin", "Greet guild members when they log in", "Only offline -> online changes after the initial guild roster snapshot.")
    toggle("greetJoin", "Welcome newly joined guild members", "Uses the localized guild-join system message; duplicate protected.")
    toggle("congratulateLevel", "Congratulate guild members on leveling", "Only online-to-online level changes. Your character is ALWAYS excluded.")
    timingOption("messageSpacing", "Automatic message spacing", "Minimum gap between automatic guild messages")
    timingOption("loginCooldown", "Login greeting cooldown", "Wait before greeting the same guildmate again; 0 disables the cooldown")
    section("Private guild requests")
    toggle("craftingAlerts", "Alert when a guildmate needs an item I can craft", "Open each profession to cache known recipes; exact item-name matching.")
    toggle("groupAlerts", "Alert on LFG / LFM / LF group requests", "Reads guild chat only. Use the Alerts window to whisper manually.")
    toggle("alertsSound", "Play sound for private alerts")
    section("Guild tabard")
    toggle("tabardInCity", "Remind me to wear my guild tabard in capital cities", "Supports classic Guild Tabard (item 5976); never equips automatically.")
    toggle("tabardOnExit", "Ask about removing the tabard when leaving a city", "Optional; opens the character equipment page for manual removal.")
    -- Mark the scroll position so Titan's shortcut can open the editor here.
    self.messagesScrollY = math.max(0, -y - 25)
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
    MakeLabel(content, "Automatic messages are rate-limited; verified messages only send when you click Send.",
        18, y, 500, "GameFontHighlightSmall")
    content:SetHeight(math.max(1200, -y+40))
    function panel.OnRefresh()
        for _, fn in ipairs(controls) do fn() end
    end
    function panel.OnCommit()
        for _, apply in ipairs(numericEdits) do apply() end
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
        if A.UpdateBroker then A:UpdateBroker() end
        if A.UpdateRequestPreview then A:UpdateRequestPreview() end
    end
    self.optionsPanel = panel
    self.optionsScroll = scroll
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Forever Guild Comms")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
