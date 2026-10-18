local _, A = ...

-- Nested context menu opened by the existing LibDataBroker click handler.
-- Titan Panel displays our LDB object; it does not need a separate Titan plugin
-- or an embedded copy of Titan's menu/library code. Blizzard MenuUtil is used
-- when the client provides it; older builds fall back to the Settings page.

local spacingPresets = {3, 6, 10, 15, 30, 60, 120}
local cooldownPresets = {0, 60, 300, 600, 900, 1800, 3600}

local function SecondsText(seconds)
    if seconds == 0 then return "Off (every detected login)" end
    if seconds < 60 then return seconds .. " seconds" end
    local minutes = math.floor(seconds / 60)
    if minutes == 1 then return "1 minute" end
    return minutes .. " minutes"
end

local function AddSetting(parent, key, label)
    parent:CreateCheckbox(label,
        function() return A.db and A.db[key] == true end,
        function() A:SetOption(key, not A.db[key]) end)
end

local function AddTiming(parent, key, label, values)
    local submenu = parent:CreateButton(label .. ": " .. SecondsText(A.db[key]))
    submenu:CreateTitle(label)
    for i = 1, #values do
        local seconds = values[i]
        submenu:CreateRadio(SecondsText(seconds),
            function() return A.db[key] == seconds end,
            function() A:SetOption(key, seconds) end)
    end
    submenu:CreateDivider()
    submenu:CreateButton("Reset to default (" .. SecondsText(A.defaults[key]) .. ")",
        function() A:SetOption(key, A.defaults[key]) end)
    return submenu
end

function A:PopulateTitanMenu(root)
    if not self.db then return end
    root:CreateTitle("Forever Guild Comms " .. self.version)
    AddSetting(root, "enabled", "Enable addon")
    root:CreateDivider()

    local outgoing = root:CreateButton("Outgoing guild messages")
    outgoing:CreateTitle("Greetings and congratulations")
    local mode = outgoing:CreateButton("Sending mode: " .. (self.db.outgoingMode == "verify" and "Verify with a click" or "Automatic"))
    mode:CreateRadio("Automatic",
        function() return A.db.outgoingMode == "automatic" end,
        function() A:SetOption("outgoingMode", "automatic") end)
    mode:CreateRadio("Verify with a click",
        function() return A.db.outgoingMode == "verify" end,
        function() A:SetOption("outgoingMode", "verify") end)
    outgoing:CreateDivider()
    AddSetting(outgoing, "greetLogin", "Greet members on login")
    AddSetting(outgoing, "greetJoin", "Welcome new guild members")
    AddSetting(outgoing, "congratulateLevel", "Congratulate other members on level-up")
    outgoing:CreateDivider()
    AddTiming(outgoing, "messageSpacing", "Automatic message spacing", spacingPresets)
    AddTiming(outgoing, "loginCooldown", "Login greeting cooldown", cooldownPresets)

    local requests = root:CreateButton("Private guild requests")
    AddSetting(requests, "craftingAlerts", "Alert on craft requests")
    AddSetting(requests, "groupAlerts", "Alert on LFG / LFM / LF requests")
    AddSetting(requests, "alertsSound", "Play private alert sound")

    local tabard = root:CreateButton("Guild tabard")
    AddSetting(tabard, "tabardInCity", "Remind me to wear tabard in cities")
    AddSetting(tabard, "tabardOnExit", "Ask to remove tabard when leaving")

    local quick = root:CreateButton("Quick actions")
    quick:CreateButton("Review pending messages (" .. #self.pendingApprovals .. ")",
        function() A:ShowApprovals() end)
    quick:CreateButton("Show private alerts (" .. #self.alerts .. ")",
        function() A:ShowAlerts() end)
    quick:CreateButton("Ask guild for help...", function() A:ShowRequest() end)
    quick:CreateButton("Rescan open profession", function()
        if A.ScanRecipes then A:ScanRecipes() end
        A:Print("Current open profession scanned, if available. /fgc recipes shows the count.")
    end)

    root:CreateDivider()
    root:CreateButton("Edit custom messages in Settings...", function() A:OpenSettings("messages") end)
    root:CreateButton("Open full Settings...", function() A:OpenSettings() end)
end

function A:OpenTitanMenu(owner)
    if not MenuUtil or not MenuUtil.CreateContextMenu then
        self:Print("Nested menus are unavailable in this client; opening Settings instead.")
        self:OpenSettings()
        return
    end
    -- LDB consumers normally pass their button frame. If a consumer passes
    -- the data object instead, use UIParent rather than an invalid menu owner.
    if not owner or not owner.GetObjectType then owner = UIParent end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        A:PopulateTitanMenu(root)
    end)
end
