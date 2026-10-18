local _, A = ...
-- Titan Panel 9.3.5 includes LibDataBroker. We use its existing copy, no embedded
-- library and no hard dependency: the addon works normally without Titan.
function A:TryBroker()
    if self.broker then return end
    local lib = LibStub and LibStub("LibDataBroker-1.1", true)
    if not lib then return end
    self.broker = lib:NewDataObject("ForeverGuildComms", {
        type = "data source",
        text = "Guild Comms",
        label = "Guild Comms",
        icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
        OnClick = function(_, button)
            if button == "RightButton" then A:OpenSettings()
            elseif IsShiftKeyDown() then A:ShowRequest()
            elseif #A.pendingApprovals > 0 then A:ShowApprovals()
            else A:ShowAlerts() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Forever Guild Comms")
            tooltip:AddLine("Online: " .. A.onlineCount .. " / " .. A.guildCount, 1, 1, 1)
            tooltip:AddLine("Private alerts: " .. #A.alerts, 1, 1, 1)
            tooltip:AddLine("Messages awaiting approval: " .. #A.pendingApprovals, 1, 0.8, 0.4)
            tooltip:AddLine("Outgoing mode: " .. (A.db and A.db.outgoingMode or "automatic"), 1, 1, 1)
            tooltip:AddLine("Left-click: review messages (when pending), else alerts", 0.7, 0.8, 1)
            tooltip:AddLine("Shift + left-click: request help", 0.7, 0.8, 1)
            tooltip:AddLine("Right-click: settings", 0.7, 0.8, 1)
        end,
    })
    self:UpdateBroker()
end
function A:UpdateBroker()
    if self.broker then
        self.broker.text = "Guild " .. self.onlineCount .. " / " .. self.guildCount
            .. " | Alerts " .. #self.alerts
            .. (#self.pendingApprovals > 0 and (" | Review " .. #self.pendingApprovals) or "")
    end
end
