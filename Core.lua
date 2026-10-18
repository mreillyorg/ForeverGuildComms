local ADDON, A = ...
_G.ForeverGuildComms = A
A.name = ADDON
A.version = "0.1.0-beta"
A.defaults = {
    enabled = true,
    greetLogin = true,
    greetJoin = true,
    congratulateLevel = true,
    craftingAlerts = true,
    groupAlerts = true,
    tabardInCity = true,
    tabardOnExit = false,
    loginCooldown = 300,
    messageSpacing = 6,
    alertsSound = false,
    templates = {
        login = "Welcome back, {name}!",
        join = "Welcome to the guild, {name}!",
        level = "Congratulations on level {level}, {name}!",
        help = "[LFG] {type}: {activity}. I can fill: {myroles}. Looking for: {needed}. Whisper me!",
    },
}
A.classRoles = {
    WARRIOR = {tank=true, damage=true}, PALADIN = {tank=true, healer=true, damage=true},
    DRUID = {tank=true, healer=true, damage=true}, SHAMAN = {healer=true, damage=true},
    PRIEST = {healer=true, damage=true}, ROGUE = {damage=true},
    MAGE = {damage=true}, WARLOCK = {damage=true}, HUNTER = {damage=true},
}
A.roleNames = {tank="Tank", healer="Healer", damage="DPS"}
A.roleOrder = {"tank", "healer", "damage"}
A.lastMessages = {}
A.eventsSeen = {}
A.alerts = {}
A.onlineCount = 0
A.guildCount = 0
A.lastGuildSend = 0
A.pendingMessages = {}

local function fillDefaults(dest, defaults)
    for key, value in pairs(defaults) do
        if dest[key] == nil then
            if type(value) == "table" then
                dest[key] = {}
                fillDefaults(dest[key], value)
            else
                dest[key] = value
            end
        elseif type(value) == "table" and type(dest[key]) == "table" then
            fillDefaults(dest[key], value)
        end
    end
end

function A:Print(s)
    print("|cff6bcbffForeverGuildComms|r: " .. tostring(s))
end
function A:Key(name)
    if type(name) ~= "string" then return "" end
    return name:lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
end
function A:IsSelf(name, guid)
    if guid and self.playerGuid and guid == self.playerGuid then return true end
    if not name then return false end
    local candidate = self:Key(name)
    if candidate == self.playerKey or (self.selfKeys and self.selfKeys[candidate]) then return true end
    -- Normalize only an explicit -Realm suffix, never shorten a character's
    -- first/last name. Two guildmates may share a first name on Forever.
    local withoutRealm = candidate:match("^(.-)%-[^%-]+$")
    if withoutRealm and (withoutRealm == self.playerKey or
        (self.selfKeys and self.selfKeys[withoutRealm])) then return true end
    return false
end
function A:Format(template, vars)
    local text = tostring(template or "")
    text = text:gsub("{([%a]+)}", function(key)
        local value = vars and vars[key]
        return value == nil and ("{" .. key .. "}") or tostring(value)
    end)
    return text:sub(1, 250)
end
function A:CanUse()
    return self.db and self.db.enabled and IsInGuild and IsInGuild()
end
function A:Now()
    return GetTime and GetTime() or 0
end
function A:IsDuplicate(key, cooldown)
    local now = self:Now()
    if self.eventsSeen[key] and now - self.eventsSeen[key] < (cooldown or 90) then return true end
    self.eventsSeen[key] = now
    return false
end
function A:SendGuild(message)
    if not self:CanUse() or type(message) ~= "string" or message == "" then return false end
    if not SendChatMessage then return false end
    local ok, err = pcall(SendChatMessage, message:sub(1, 250), "GUILD")
    if not ok then self:Print("Couldn't send guild message: " .. tostring(err)) end
    return ok
end
-- Cooldown queue; messages never sent if the character has subsequently left guild.
function A:QueueGuild(message, key, cooldown)
    if not self:CanUse() or self:IsDuplicate(key, cooldown or 90) then return end
    table.insert(self.pendingMessages, message)
    self:DrainQueue()
end
function A:DrainQueue()
    if self.queueTimer or #self.pendingMessages == 0 then return end
    if not self:CanUse() then wipe(self.pendingMessages); return end
    local gap = math.max(3, tonumber(self.db.messageSpacing) or 6)
    local delay = math.max(0, gap - (self:Now() - self.lastGuildSend))
    self.queueTimer = true
    C_Timer.After(delay, function()
        self.queueTimer = false
        local msg = table.remove(self.pendingMessages, 1)
        if msg and self:SendGuild(msg) then self.lastGuildSend = self:Now() end
        if #self.pendingMessages > 0 then self:DrainQueue() end
    end)
end
function A:RoleText(roles, noneText)
    local labels = {}
    for _, role in ipairs(self.roleOrder) do
        if roles and roles[role] then table.insert(labels, self.roleNames[role]) end
    end
    return #labels > 0 and table.concat(labels, "/") or (noneText or "Any")
end
function A:OpenSettings()
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    else
        self:Print("Settings page is not available yet. Try /reload.")
    end
end
function A:Initialize()
    if self.initialized then return end
    self.initialized = true
    ForeverGuildCommsDB = type(ForeverGuildCommsDB) == "table" and ForeverGuildCommsDB or {}
    ForeverGuildCommsCharDB = type(ForeverGuildCommsCharDB) == "table" and ForeverGuildCommsCharDB or {}
    fillDefaults(ForeverGuildCommsDB, self.defaults)
    self.db = ForeverGuildCommsDB
    self.char = ForeverGuildCommsCharDB
    self.char.recipes = self.char.recipes or {}
    self.char.myRoles = self.char.myRoles or {}
    self.char.needRoles = self.char.needRoles or {}
    self.playerGuid = UnitGUID("player")
    self.playerName = UnitName("player") or ""
    self.playerKey = self:Key(self.playerName)
    self.selfKeys = {[self.playerKey]=true}
    if GetUnitName then
        local full = GetUnitName("player", true)
        if full and full ~= "" then self.selfKeys[self:Key(full)] = true end
    end
    if UnitFullName then
        local full = UnitFullName("player")
        if full and full ~= "" then self.selfKeys[self:Key(full)] = true end
    end
    local _, playerClass = UnitClass("player")
    self.playerClass = playerClass or ""
    for _, role in ipairs(self.roleOrder) do
        if self.char.myRoles[role] == nil then
            self.char.myRoles[role] = (self.classRoles[self.playerClass] or {})[role] or false
        end
    end
    if self.BuildOptions then self:BuildOptions() end
    if self.BuildUI then self:BuildUI() end
    if self.SetupRoster then self:SetupRoster() end
    if self.CheckTabard then C_Timer.After(3, function() self:CheckTabard(true) end) end
    if self.TryBroker then self:TryBroker() end
    self:Print("Loaded. /fgc for alerts and requests; /fgc options for settings.")
end

SLASH_FOREVERGUILDCOMMS1 = "/fgc"
SLASH_FOREVERGUILDCOMMS2 = "/guildcomms"
SlashCmdList.FOREVERGUILDCOMMS = function(input)
    input = (input or ""):lower():match("^%s*(.-)%s*$")
    if not A.initialized then A:Print("Not initialized yet."); return end
    if input == "options" or input == "settings" then A:OpenSettings()
    elseif input == "request" or input == "help" then A:ShowRequest()
    elseif input == "alerts" then A:ShowAlerts()
    elseif input == "recipes" then
        local count = 0
        for _, recipes in pairs(A.char.recipes) do for _ in pairs(recipes) do count = count + 1 end end
        A:Print(count .. " learned recipe names cached. Open each profession to refresh the cache.")
    elseif input == "clearrecipes" then
        wipe(A.char.recipes)
        A:Print("Recipe cache cleared. Open your professions again to repopulate it.")
    elseif input == "status" then
        A:Print("Guild members: " .. A.guildCount .. ", online: " .. A.onlineCount .. ", private alerts: " .. #A.alerts)
    else A:ShowAlerts() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_GUILD_UPDATE")
events:RegisterEvent("CHAT_MSG_GUILD")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("UI_INFO_MESSAGE")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
events:RegisterEvent("NEW_RECIPE_LEARNED")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then A:Initialize(); return end
    if event == "ADDON_LOADED" then
        if A.initialized and A.TryBroker then A:TryBroker() end
        return
    end
    if not A.initialized then return end
    if event == "CHAT_MSG_GUILD" then
        if A.OnGuildChat then A:OnGuildChat(...) end
    elseif event == "CHAT_MSG_SYSTEM" then
        if A.OnSystemGuildJoin then A:OnSystemGuildJoin(...) end
    elseif event == "UI_INFO_MESSAGE" then
        if A.OnSystemGuildJoin then A:OnSystemGuildJoin(select(2, ...)) end
    elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
        if A.OnRosterEvent then A:OnRosterEvent(event) end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "NEW_RECIPE_LEARNED" then
        if A.ScheduleRecipeScan then A:ScheduleRecipeScan() end
    elseif A.ScheduleTabardCheck and (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "PLAYER_ENTERING_WORLD") then
        A:ScheduleTabardCheck()
    end
end)
