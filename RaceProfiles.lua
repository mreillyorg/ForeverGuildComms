local _, A = ...

-- UnitRace returns a locale-independent second value. The custom client may
-- add races without publishing their IDs; unknown races fall back gracefully.
A.raceAccents = {
    Human={"british", "american", "australian", "scottish", "irish", "canadian", "newzealand", "southafrican"},
    Dwarf={"dwarf", "wildhammer", "darkiron"},
    Gnome={"gnome"}, NightElf={"nightelf"},
    Orc={"orc"}, Troll={"troll"}, Tauren={"tauren"}, Scourge={"forsaken"},
    Undead={"forsaken"}, Goblin={"goblin"}, BloodElf={"bloodelf"}, Draenei={"draenei"},
    Skyborne={"skyborne"},
}
function A:GetPlayerRace()
    local localName, token = nil, nil
    if UnitRace then localName, token = UnitRace("player") end
    local probe = tostring(token or localName or "")
    if probe:lower():find("skyborne", 1, true) then return "Skyborne" end
    return token or localName or "Unknown"
end
function A:GetAvailableAccents()
    local selected = self.char and self.char.voice or self.voiceDefaults
    local language = selected.language or "en"
    local allowed = nil
    if selected.raceFilter then
        allowed = {}
        for _, key in ipairs(self.raceAccents[self:GetPlayerRace()] or {}) do allowed[key] = true end
        if self:GetPlayerRace() == "Human" then
            -- Regional human styles are available in their own languages.
            for _, key in ipairs({"mexican", "cuban", "spanish", "quebec", "bavarian", "brazilian", "portuguese", "southernitalian"}) do
                allowed[key] = true
            end
        end
    end
    local options = {{id="auto", label="Auto (character race)"}, {id="none", label="None"}}
    for _, key in ipairs(self.accentOrder or {}) do
        local accent = self.accents[key]
        if accent and accent.language == language and (not allowed or allowed[key]) then
            options[#options+1] = {id=key, label=accent.label}
        end
    end
    return options
end
function A:ResolveAccent()
    local voice = self.char and self.char.voice or self.voiceDefaults
    local chosen = voice.accent
    if chosen == "none" then return nil end
    local options = self:GetAvailableAccents()
    local valid = {}
    for _, entry in ipairs(options) do valid[entry.id] = true end
    if chosen == "auto" then
        for _, preferred in ipairs(self.raceAccents[self:GetPlayerRace()] or {}) do
            if valid[preferred] then return self.accents[preferred] end
        end
        return nil
    end
    if valid[chosen] then return self.accents[chosen] end
    return nil
end
function A:VoiceText(kind, vars, preview)
    -- Settings are per-character; the built-in English text is always available.
    local voice = self.char and self.char.voice or self.voiceDefaults
    local ownTemplate = self.db and self.db.templates and self.db.templates[kind]
    if not ownTemplate then return "" end
    -- Editing a template always wins. Arbitrary user messages cannot reliably
    -- be translated or accent-transformed without altering links/user intent.
    if ownTemplate ~= self.defaults.templates[kind] then return self:Format(ownTemplate, vars) end
    local lang = voice.language or "en"
    local text = ((self.localeTemplates or {})[lang] or self.defaults.templates)[kind] or ownTemplate
    local accent = self:ResolveAccent()
    if accent and accent.text[kind] then
        text = accent.text[kind]
    end
    -- Randomize the chosen built-in template, never custom text or a Settings
    -- sample. The help composer caches this choice for its preview and Send.
    if self.db.randomizeMessages and not preview and self.ChooseMessageTemplate then
        text = self:ChooseMessageTemplate(kind, lang, accent, text)
    end
    if accent and accent.text[kind] then
        -- Light optional personality; don't prepend an interjection to [LFG].
        if kind ~= "help" and accent.flair then
            if voice.accentStrength == "moderate" then
                text = accent.flair .. text
            elseif voice.accentStrength == "expressive" then
                -- A stronger flourish without repeating the catchphrase or
                -- modifying character names, links, or placeholder values.
                text = accent.flair .. text
                if text:sub(-1) == "!" then
                    text = text .. "!"
                elseif text:sub(-1) == "." then
                    text = text:sub(1, -2) .. "!"
                end
            end
        end
    end
    return self:Format(text, vars)
end
function A:LocalizeRoleText(roles, fallback)
    local voice = self.char and self.char.voice or self.voiceDefaults
    local names = (self.localeRoleNames and self.localeRoleNames[voice.language]) or self.roleNames
    local output = {}
    for _, role in ipairs(self.roleOrder) do
        if roles and roles[role] then output[#output+1] = names[role] or self.roleNames[role] end
    end
    return #output > 0 and table.concat(output, "/") or (names[fallback] or fallback)
end
function A:LocalizeActivityType(kind)
    local voice = self.char and self.char.voice or self.voiceDefaults
    return ((self.localeActivityTypes or {})[voice.language] or {})[kind] or kind
end
