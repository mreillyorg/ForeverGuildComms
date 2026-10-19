local _, A = ...

local function cleanChat(message)
    if type(message) ~= "string" then return "" end
    -- Keep displayed item names but remove WoW colour/hyperlink codes.
    return message:gsub("|H.-|h%[([^%]]+)%]|h", "%1")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local function looksLikeCraftRequest(message)
    return message:find("wtb", 1, true) or message:find("can anyone craft", 1, true)
        or message:find("can someone craft", 1, true) or message:find("need crafted", 1, true)
        or message:find("looking for crafter", 1, true) or message:find("looking for someone to make", 1, true)
        or message:find("lf crafter", 1, true) or message:find("can anyone make", 1, true)
        or message:find("can someone make", 1, true) or message:find("who can make", 1, true)
        or message:find("anyone able to make", 1, true) or message:find("need someone to make", 1, true)
end
local function looksLikeGroupRequest(message)
    return message:match("%f[%a]lfg%f[%A]") or message:match("%f[%a]lfm%f[%A]")
        or message:match("%f[%a]lf%d+m%f[%A]") or message:match("^lf%s+")
        or message:find("looking for group", 1, true)
        or message:find("looking for more", 1, true)
        or message:find("group for", 1, true) or message:find("anyone for", 1, true)
        or message:find("need a tank", 1, true) or message:find("need a healer", 1, true)
end
function A:AddAlert(kind, sender, text)
    local dedup = kind .. ":" .. self:Key(sender) .. ":" .. text:lower()
    if self:IsDuplicate(dedup, 120) then return end
    table.insert(self.alerts, 1, {kind=kind, sender=sender, text=text, time=date("%H:%M")})
    if #self.alerts > 30 then table.remove(self.alerts) end
    self:Print("|cffffcc66" .. kind .. "|r from " .. sender .. ": " .. text)
    if self.db.alertsSound and PlaySound then
        if SOUNDKIT and SOUNDKIT.TELL_MESSAGE then PlaySound(SOUNDKIT.TELL_MESSAGE) end
    end
    if self.UpdateAlertsUI then self:UpdateAlertsUI() end
    if self.UpdateBroker then self:UpdateBroker() end
end
function A:ScheduleRecipeScan()
    if self.recipeScanPending then return end
    self.recipeScanPending = true
    C_Timer.After(0.5, function()
        self.recipeScanPending = false
        self:ScanRecipes()
    end)
end
function A:ScanRecipes()
    if not self.char or not C_TradeSkillUI or not C_TradeSkillUI.GetAllRecipeIDs then return false end
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    if type(recipeIDs) ~= "table" or #recipeIDs == 0 then return false end
    local profession = "Current Profession"
    if C_TradeSkillUI.GetProfessionChildSkillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local skillLine = C_TradeSkillUI.GetProfessionChildSkillLineID()
        if skillLine then
            local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLine)
            if info and info.professionName then profession = info.professionName end
        end
    end
    -- Build a fresh cache for only the profession currently being viewed.
    local known = {}
    for _, id in ipairs(recipeIDs) do
        local info = C_TradeSkillUI.GetRecipeInfo(id)
        if info and info.learned and not info.disabled and not info.isGatheringRecipe then
            local names = {}
            if C_TradeSkillUI.GetRecipeItemLink then
                local link = C_TradeSkillUI.GetRecipeItemLink(id)
                if type(link) == "string" then
                    local output = link:match("%[([^%]]+)%]")
                    if output then table.insert(names, output) end
                end
            end
            if info.name then table.insert(names, info.name) end
            for _, itemName in ipairs(names) do
                if #itemName >= 4 then known[itemName:lower()] = itemName end
            end
        end
    end
    if next(known) then self.char.recipes[profession] = known end
    return true
end
function A:MatchCraft(lower)
    -- Require an exact known recipe/output name within an actual crafting request.
    if not looksLikeCraftRequest(lower) then return nil end
    for _, professionRecipes in pairs(self.char.recipes or {}) do
        for recipeLower, recipeName in pairs(professionRecipes) do
            if lower:find(recipeLower, 1, true) then return recipeName end
        end
    end
end
function A:OnGuildChat(message, sender)
    if not self:CanUse() or not sender or self:IsSelf(sender) then return end
    local cleaned = cleanChat(message)
    local lower = cleaned:lower()
    if self.db.craftingAlerts then
        local matched = self:MatchCraft(lower)
        if matched then self:AddAlert("Craft: " .. matched, sender, cleaned) end
    end
    if self.db.groupAlerts and looksLikeGroupRequest(lower) and not looksLikeCraftRequest(lower) then
        self:AddAlert("Group request", sender, cleaned)
    end
end
