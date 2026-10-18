local _, A = ...
A.roster = {}
A.rosterReady = false
A.rosterGuild = nil
A.baselineTimer = false
A.lastRosterRequest = 0

local function guildName()
    if not IsInGuild() then return nil end
    return GetGuildInfo("player")
end
function A:RequestRoster(force)
    if not IsInGuild() then return end
    local now = self:Now()
    if not force and now - self.lastRosterRequest < 30 then return end
    self.lastRosterRequest = now
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
end
function A:ReadRoster()
    local members, count, online = {}, 0, 0
    local total = GetNumGuildMembers and GetNumGuildMembers() or 0
    for i = 1, total do
        local name, _, _, level, _, _, _, _, isOnline, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        if name and name ~= "" then
            local key = self:Key(name)
            members[key] = {name=name, level=level, online=isOnline and true or false, guid=guid}
            count = count + 1
            if isOnline then online = online + 1 end
        end
    end
    return members, count, online
end
function A:AcceptRoster(members, count, online, baseline)
    local old = self.roster
    if not baseline and self.rosterReady then
        for key, member in pairs(members) do
            local previous = old[key]
            if previous and not self:IsSelf(member.name, member.guid) then
                -- No level congratulations for newly seen guildmates, an offline
                -- transition, an uninitialized level, or the player themself.
                if self.db.enabled and self.db.congratulateLevel
                    and previous.online and member.online
                    and type(previous.level) == "number" and previous.level > 0
                    and type(member.level) == "number" and member.level > previous.level then
                    local msg = self:Format(self.db.templates.level, {
                        name=member.name, level=member.level,
                    })
                    self:QueueGuild(msg, "level:"..key..":"..member.level, 1800)
                end
                if self.db.enabled and self.db.greetLogin and not previous.online and member.online then
                    local msg = self:Format(self.db.templates.login, {name=member.name, level=member.level})
                    self:QueueGuild(msg, "login:"..key, self.db.loginCooldown)
                end
            end
        end
    end
    self.roster = members
    self.guildCount = count
    self.onlineCount = online
    self.rosterReady = true
    if self.UpdateBroker then self:UpdateBroker() end
end
function A:CaptureBaseline()
    self.baselineTimer = false
    if not self:CanUse() then return end
    local guild = guildName()
    if not guild then return end
    local members, count, online = self:ReadRoster()
    if count == 0 then
        self:RequestRoster()
        C_Timer.After(4, function() if not self.rosterReady then self:CaptureBaseline() end end)
        return
    end
    self.rosterGuild = guild
    self:AcceptRoster(members, count, online, true)
end
function A:OnRosterEvent(event)
    local guild = guildName()
    if not guild or guild ~= self.rosterGuild then
        -- Don't leak queued greetings into a different guild after a guild change.
        if self.rosterGuild and guild ~= self.rosterGuild then
            wipe(self.pendingMessages)
        end
        self.rosterReady = false
        self.roster = {}
        self.rosterGuild = guild
        self.guildCount = 0
        self.onlineCount = 0
        if guild then self:RequestRoster() end
    end
    if not guild then return end
    if not self.rosterReady then
        if not self.baselineTimer then
            self.baselineTimer = true
            C_Timer.After(2, function() self:CaptureBaseline() end)
        end
        return
    end
    local members, count, online = self:ReadRoster()
    -- Defensive guard against a briefly incomplete roster cache.
    if count == 0 or (self.guildCount > 10 and count < self.guildCount * 0.7) then return end
    self:AcceptRoster(members, count, online, false)
end

function A:OnSystemGuildJoin(message)
    if not self:CanUse() or not self.db.greetJoin or type(message) ~= "string" then return end
    if type(ERR_GUILD_JOIN_S) ~= "string" then return end
    -- Escape Lua pattern characters and replace Blizzard's localized %s slot.
    local escaped = ERR_GUILD_JOIN_S:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    escaped = escaped:gsub("%%%%s", "(.+)")
    local newMember = message:match("^" .. escaped .. "$")
    if not newMember or self:IsSelf(newMember) then return end
    local text = self:Format(self.db.templates.join, {name=newMember})
    self:QueueGuild(text, "join:" .. self:Key(newMember), 300)
end
function A:SetupRoster()
    self:OnRosterEvent("PLAYER_GUILD_UPDATE")
    C_Timer.After(5, function() self:OnRosterEvent("PLAYER_GUILD_UPDATE") end)
    C_Timer.NewTicker(60, function()
        if A:CanUse() then A:RequestRoster() end
    end)
end
