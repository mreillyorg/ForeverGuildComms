-- Settings UI + SavedVariables migration test; run: texlua tests/settings.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]settings%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
_G.IsInGuild = function() return false end
_G.UnitGUID = function() return "Player-1" end
_G.UnitName = function() return "Tester" end
_G.UnitClass = function() return "Mage", "MAGE" end
_G.C_Timer = {After=function()end}
_G.ForeverGuildCommsDB = {
    enabled=true,
    templates={login="My special greeting, {name}!", join="", level="   "},
}
_G.ForeverGuildCommsCharDB = {}
_G.GetTime = function() return 1100 end
_G.UIParent = {}
local widgets = {}
local noop = function()end
local mt
mt = {__index=function(tbl, method)
    if method == 'SetText' then return function(self, text) self.text=text end end
    if method == 'GetText' then return function(self) return self.text end end
    if method == 'SetChecked' then return function(self, checked) self.checked=checked end end
    if method == 'GetChecked' then return function(self) return self.checked end end
    if method == 'SetScript' then return function(self, event, cb) self[event]=cb end end
    if method == 'HasFocus' then return function() return false end end
    if method == 'CreateFontString' then return function() return setmetatable({}, mt) end end
    return noop
end}
_G.CreateFrame=function(kind, name, parent, template)
    local w=setmetatable({kind=kind,name=name,parent=parent,template=template},mt)
    table.insert(widgets,w)
    return w
end
_G.Settings={
    RegisterCanvasLayoutCategory=function(panel,title)
        _G.panel=panel
        return {GetID=function()return 5 end}
    end,
    RegisterAddOnCategory=function()end,
}
local A={}
assert(loadfile(base.."Core.lua"))("ForeverGuildComms",A)
assert(loadfile(base.."Options.lua"))("ForeverGuildComms",A)
A:Initialize()
assert(A.db.templates.login == "My special greeting, {name}!", "do not overwrite existing custom wording")
assert(A.db.templates.join == "Welcome to the guild, {name}!", "blank welcome must use default")
assert(A.db.templates.level == "Congratulations on level {level}, {name}!", "blank level must use default")
assert(A.db.templates.help == A.defaults.templates.help, "missing help must use default")
assert(A.db.outgoingMode == "automatic", "original behavior should be default")
local radios={}
local useDefaultButtons={}
for _,widget in ipairs(widgets) do
    if widget.template == 'UIRadioButtonTemplate' then table.insert(radios,widget) end
    if widget.text == 'Use default' then table.insert(useDefaultButtons,widget) end
end
assert(#radios == 2, "two radio options should exist")
assert(#useDefaultButtons == 4, "default restore button per custom template")
assert(radios[1].checked and not radios[2].checked, "automatic selected by default")
radios[2].OnClick(radios[2])
assert(A.db.outgoingMode == 'verify' and radios[2].checked and not radios[1].checked, "verify radio must switch mode")
radios[1].OnClick(radios[1])
assert(A.db.outgoingMode == 'automatic', "automatic radio must switch mode back")
print('PASSED: SavedVariables migration, default templates, two radio modes, four Use default buttons')
