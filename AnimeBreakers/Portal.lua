local Portal = {
    Data = {},
    Options = {},
}

function Portal:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GamemodeData.Portal

    for Rank, Data in pairs(self.Data) do
        if typeof(Data) == "table" and typeof(Data.OpenItem) == "string" then
            table.insert(self.Options, Rank)
        end
    end

    table.sort(self.Options, function(A, B)
        return (self.Data[A].Order or 999) < (self.Data[B].Order or 999)
    end)

    self.Enabled = false
    self.Selected = {}
    Tab:CreateDivider({ text = "Portal automation", line = true })
    Tab:CreateToggle({ name = "Auto Portal", flag = "AutoPortal", value = false, callback = function(Value) self.Enabled = Value == true end })
    Tab:CreateDropdown({ name = "Portals to Farm", flag = "PortalRanks", options = self.Options, value = {}, multiSelect = true, callback = function(Value) self.Selected = Value or {} end })
    Tab:CreateToggle({ name = "Auto Join", flag = "AutoJoinPortal", value = false })
    self.Status = Tab:CreateText({ name = "Portal Status", text = "Auto Portal disabled." })
    task.spawn(function()
        while Manager.Cache.Running do
            if self.Enabled then
                local Plan = self:Current(self.Selected, "Highest first")
                Manager.UI:Change(self.Status, Plan.State == "Ready" and ("Ready: " .. Plan.Rank) or Plan.State)
            else
                Manager.UI:Change(self.Status, "Auto Portal disabled.")
            end
            task.wait(0.5)
        end
    end)
end

function Portal:Plan(Items, SelectedRanks, Order)
    if typeof(Items) ~= "table" then return { State = "WaitingInventory" } end

    local Ranks = {}
    for _, Rank in ipairs(SelectedRanks or {}) do
        if self.Data[Rank] and not table.find(Ranks, Rank) then
            table.insert(Ranks, Rank)
        end
    end

    table.sort(Ranks, function(A, B)
        local AOrder = self.Data[A].Order or 0
        local BOrder = self.Data[B].Order or 0
        if AOrder == BOrder then return A < B end
        if Order == "Lowest first" then return AOrder < BOrder end
        return AOrder > BOrder
    end)

    for _, Rank in ipairs(Ranks) do
        local Data = self.Data[Rank]
        local Count = tonumber(Items[Data.OpenItem]) or 0
        if Count >= 1 then
            return { State = "Ready", Rank = Rank, Item = Data.OpenItem, Count = Count }
        end
    end

    for _, Rank in ipairs(Ranks) do
        local Data = self.Data[Rank]
        if self.Manager.Shared.GamemodeData.Raid[Data.RaidMap] then
            return { State = "FarmRaid", Rank = Rank, Raid = Data.RaidMap }
        end
    end

    return { State = "Unavailable" }
end

function Portal:Current(SelectedRanks, Order)
    local PlayerData = self.Manager.Library.PlayerData
    return self:Plan(PlayerData and PlayerData.Items, SelectedRanks, Order)
end

function Portal:ShouldQuit(Status, Remaining, Seconds)
    Remaining = tonumber(Remaining)
    Seconds = tonumber(Seconds) or 0
    return Seconds > 0 and Status == "Running" and Remaining ~= nil and Remaining <= Seconds
end

return Portal
