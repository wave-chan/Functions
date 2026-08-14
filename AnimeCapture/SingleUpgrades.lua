--## SCRIPT ##--
local module = { Cache = {}, }

function module:Init(Manager, Tab, LoopCooldown)

    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Single Upgrades")

    for UpgradeIndex, UpgradeInfo in ipairs(Manager.Shared.SingleUpgrades) do

        local ResourceInfo = Manager.Shared.Resources[UpgradeInfo.NecessaryResource]
        if not ResourceInfo then continue end

        UpgradeInfo.Name = ResourceInfo.Description:gsub("Used in ", "")
        UpgradeInfo.Index = UpgradeIndex

        module.Cache[UpgradeInfo.Name] = UpgradeInfo

        local LoopId = `SingleUpgrade{UpgradeInfo.Name}`
        local ToggleId = `autoSingleUpgrade_{UpgradeInfo.Name}`

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto Upgrade {UpgradeInfo.Name}`, Default = false })

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            Functions:Upgrade(Manager, UpgradeInfo.Name)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:Upgrade(Manager, UpgradeName: string)

    local UpgradeInfo = self.Cache[UpgradeName]
    if not UpgradeInfo then return end

    local Level = Manager.Data.SingleUpgrades[tostring(UpgradeInfo.Index)] or 0
    if Level >= UpgradeInfo.LevelMax then
        return
    end

    local UpgradeCost = UpgradeInfo.GetCost(Level) or 0
    local CanUpgrade = (Manager.Data.Resources[UpgradeInfo.NecessaryResource] or 0) >= UpgradeCost

    if not CanUpgrade then
        return
    end

    Manager:Signal("SingleUpgradeEvent", UpgradeInfo.Index)
end

return module
