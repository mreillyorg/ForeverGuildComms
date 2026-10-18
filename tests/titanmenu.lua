-- Offline Titan/LibDataBroker + nested-menu integration test.
-- Run from the addon directory: texlua tests/titanmenu.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]titanmenu%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
_G.IsInGuild = function() return true end
_G.GetGuildInfo = function() return "Example" end
_G.UnitGUID = function() return "Player-0" end
_G.UnitName = function() return "Tester" end
_G.UnitClass = function() return "Mage", "MAGE" end
_G.GetTime = function() return 100 end
_G.ForeverGuildCommsDB = {templates={login="Previously edited {name}!"}}
_G.ForeverGuildCommsCharDB = {}
_G.UIParent = {GetObjectType=function() return "Frame" end}
_G.C_Timer = {After=function(_, fn) fn() end}
local fake = {}
local mt
mt = {__index=function(_, name)
    if name == "GetText" then return function(self) return self.text end end
    if name == "GetChecked" then return function(self) return self.checked end end
    if name == "HasFocus" then return function() return false end end
    if name == "CreateFontString" then return function() return setmetatable({}, mt) end end
    if name == "SetScript" then return function(self, action, func) self[action]=func end end
    if name == "SetText" then return function(self, value) self.text=value end end
    if name == "SetChecked" then return function(self, value) self.checked=value end end
    if name == "SetVerticalScroll" then return function(self, value) self.scrolledTo=value end end
    return function() end
end}
_G.CreateFrame = function(kind, name, parent, template)
    local frame = setmetatable({kind=kind, name=name, parent=parent, template=template}, mt)
    table.insert(fake, frame)
    return frame
end
local settingsOpens = 0
_G.Settings = {
    RegisterCanvasLayoutCategory=function(panel) return {GetID=function()return 9 end} end,
    RegisterAddOnCategory=function()end,
    OpenToCategory=function(id) assert(id==9); settingsOpens=settingsOpens+1 end,
}
local dataobject
_G.LibStub = function(name, silent)
    assert(name == "LibDataBroker-1.1" and silent)
    return {NewDataObject=function(_, _, obj) dataobject = obj; return obj end}
end
local function menuNode(kind, name, selected, action)
    local node = {kind=kind, name=name, selected=selected, action=action, children={}}
    local function add(k, n, s, a)
        local child=menuNode(k,n,s,a)
        table.insert(node.children,child)
        return child
    end
    function node:CreateTitle(n) return add("title",n) end
    function node:CreateDivider() return add("divider","") end
    function node:CreateButton(n, cb) return add("button",n,nil,cb) end
    function node:CreateCheckbox(n, selectedCallback, callback)
        return add("checkbox",n,selectedCallback,callback)
    end
    function node:CreateRadio(n, selectedCallback, callback)
        return add("radio",n,selectedCallback,callback)
    end
    return node
end
local root
local lastOwner
_G.MenuUtil = {CreateContextMenu=function(owner, builder)
    lastOwner=owner
    root=menuNode("root","root")
    builder(owner,root)
end}
local A={}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms",A)
assert(loadfile(base .. "Options.lua"))("ForeverGuildComms",A)
assert(loadfile(base .. "TitanMenu.lua"))("ForeverGuildComms",A)
assert(loadfile(base .. "Broker.lua"))("ForeverGuildComms",A)
A:Initialize()
assert(dataobject, "LibDataBroker object is registered")
local panel=A.optionsPanel
assert(panel and A.optionsScroll and A.messagesScrollY, "settings registered with custom-message scroll anchor")
local function find(node, name, kind)
    if node.name == name and (not kind or node.kind == kind) then return node end
    for _, child in ipairs(node.children) do
        local got = find(child, name, kind)
        if got then return got end
    end
end
local frame={GetObjectType=function() return "Button" end}
dataobject.OnClick(frame,"RightButton")
assert(root and lastOwner == frame, "LDB right-click should open nested context menu on its frame")
assert(find(root,"Outgoing guild messages") and find(root,"Private guild requests") and find(root,"Guild tabard") and find(root,"Quick actions"), "all menu sections")
assert(not find(root,"Previously edited {name}!"), "templates are not editable via Titan")
local disabled = find(root,"Enable addon", "checkbox")
assert(disabled and disabled.selected())
disabled.action()
assert(not A.db.enabled, "Titan toggle stores settings")
disabled.action()
assert(A.db.enabled, "toggle can be restored")
find(root,"Verify with a click", "radio").action()
assert(A.db.outgoingMode=="verify", "Titan changes sending mode")
assert(A.optionsPanel, "Settings panel should remain registered")
local settingsRadios={}
for _, item in ipairs(fake) do
    if item.template=="UIRadioButtonTemplate" then table.insert(settingsRadios,item) end
end
assert(#settingsRadios==2 and settingsRadios[2].checked, "Blizzard Settings radios reflect Titan change")
A.pendingApprovals={{text="test"}}
find(root,"Automatic", "radio").action()
assert(A.db.outgoingMode=="automatic" and #A.pendingApprovals==1, "existing approvals aren't auto-sent when changing mode")
local timing=find(root,"Automatic message spacing: 6 seconds", "button")
assert(timing,"spacing submenu shows current value")
find(timing,"15 seconds", "radio").action()
assert(A.db.messageSpacing==15, "timing preset saved")
local numericEdit
for _, item in ipairs(fake) do
    if item.kind=="EditBox" and item.text=="15" then numericEdit=item; break end
end
assert(numericEdit, "Blizzard Settings numeric field refreshed from Titan")
find(timing,"Reset to default (6 seconds)","button").action()
assert(A.db.messageSpacing==6,"reset timing preset")
local cooldown=find(root,"Login greeting cooldown: 5 minutes", "button")
find(cooldown,"Off (every detected login)","radio").action()
assert(A.db.loginCooldown==0,"zero cooldown preset")
find(root,"Alert on craft requests","checkbox").action()
assert(A.db.craftingAlerts==false)
find(root,"Ask to remove tabard when leaving","checkbox").action()
assert(A.db.tabardOnExit==true)
local calls={}
A.ShowApprovals = function() calls[#calls+1]="review" end
A.ShowAlerts = function() calls[#calls+1]="alerts" end
A.ShowRequest = function() calls[#calls+1]="help" end
A.ScanRecipes = function() calls[#calls+1]="recipes" end
find(root,"Review pending messages (0)","button").action()
find(root,"Show private alerts (0)","button").action()
find(root,"Ask guild for help...","button").action()
find(root,"Rescan open profession","button").action()
assert(table.concat(calls,",")=="review,alerts,help,recipes", "quick actions call existing functions")
find(root,"Edit custom messages in Settings...","button").action()
assert(settingsOpens==1 and A.optionsScroll.scrolledTo==A.messagesScrollY, "custom message shortcut opens and scrolls Settings")
find(root,"Open full Settings...","button").action()
assert(settingsOpens==2,"full Settings shortcut")
assert(A.db.templates.login=="Previously edited {name}!", "existing custom template untouched")
-- Reopen the menu: labels and selected radio state must be reconstructed from DB.
dataobject.OnClick(frame,"RightButton")
assert(find(root,"Automatic message spacing: 6 seconds"))
assert(find(root,"Login greeting cooldown: Off (every detected login)"))
assert(find(root,"Automatic","radio").selected())
-- Missing modern MenuUtil must fail safely to the same settings page.
_G.MenuUtil=nil
dataobject.OnClick(frame,"RightButton")
assert(settingsOpens==3,"graceful fallback when Blizzard context menus unavailable")
print("PASSED: LDB Titan right click, nested menus, shared Settings state, presets, quick actions, custom-message shortcut, fallback")
