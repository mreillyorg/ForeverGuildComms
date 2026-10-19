-- Run with: texlua tests/keybindings.lua
-- Exercise the actual Lua code embedded in the game's auto-loaded Bindings.xml.
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]keybindings%.lua$")) or "./"
_G.SlashCmdList = {}
_G.CreateFrame = function() return {RegisterEvent=function()end, SetScript=function()end} end
local printed={}
_G.print = function(text) table.insert(printed, tostring(text)) end
local sent=0
_G.SendChatMessage=function() sent=sent+1 end
local A={}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms", A)
assert(loadfile(base .. "Alerts.lua"))("ForeverGuildComms", A)
A.initialized=true
A.char={recipes={}}
A.db={enabled=true}
local alerts, requests=0,0
A.ShowAlerts=function() alerts=alerts+1 end
A.ShowRequest=function() requests=requests+1 end
local bindings=assert(io.open(base .. "Bindings.xml","r")):read("*a")
assert(bindings:find('category="ADDONS"',1,true), "bindings should appear in WoW AddOns category")
assert(bindings:find('header="FOREVERGUILDCOMMS"',1,true), "addon must have category header")
assert(not bindings:find('default=',1,true), "hotkeys must be opt-in")
local map={}
for name,body in bindings:gmatch('<Binding%s+name="([^"]+)"[^>]*>(.-)</Binding>') do
    assert(not map[name],"duplicate binding action")
    map[name]=assert(load(body,'binding ' .. name))
end
assert(map.FGC_OPEN_ALERTS and map.FGC_ASK_HELP and map.FGC_RESCAN_PROFESSION)
assert(BINDING_HEADER_FOREVERGUILDCOMMS=="Forever Guild Comms")
assert(BINDING_NAME_FGC_OPEN_ALERTS and BINDING_NAME_FGC_ASK_HELP and BINDING_NAME_FGC_RESCAN_PROFESSION)
map.FGC_OPEN_ALERTS()
map.FGC_ASK_HELP()
assert(alerts==1 and requests==1,"binding actions must open the intended windows")
assert(sent==0,"opening the help composer must NEVER send guild messages")
-- Missing profession UI gets honest feedback without an exception.
map.FGC_RESCAN_PROFESSION()
assert(#printed>0 and printed[#printed]:find('Open a profession window first',1,true))
-- An open learned profession should populate the existing recipe cache.
_G.C_TradeSkillUI={
    GetAllRecipeIDs=function()return {17,18}end,
    GetRecipeInfo=function(id)
        if id==17 then return {learned=true,name="Greater Magic Wand"} end
        return {learned=false,name="Unavailable Item"}
    end,
    GetProfessionChildSkillLineID=function()return 333 end,
    GetProfessionInfoBySkillLineID=function()return {professionName="Enchanting"}end,
}
map.FGC_RESCAN_PROFESSION()
assert(A.char.recipes.Enchanting["greater magic wand"]=="Greater Magic Wand")
assert(not A.char.recipes.Enchanting["unavailable item"])
assert(printed[#printed]:find("Open profession rescanned",1,true))
assert(sent==0,"quick actions should not send a message")
-- A disabled addon still allows viewing the private windows.
A.db.enabled=false
map.FGC_OPEN_ALERTS()
map.FGC_ASK_HELP()
assert(alerts==2 and requests==2)
-- No-op until initialized (e.g. early key press on login).
A.initialized=false
map.FGC_OPEN_ALERTS()
assert(alerts==2)
io.write("PASSED: Key Bindings XML, action dispatch, no auto-send, profession scan/feedback\n")
