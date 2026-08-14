--## SCRIPT ##--
local module = { Cache = {}, }

function module:GetProgressionInfo(Manager, ProgressionName: string)
    local Cache = self.Cache[ProgressionName]
    if Cache then return Cache end

    for ProgressionIndex, ProgressionInfo in ipairs(Manager.Shared.Progressions) do

        local ResourceInfo = Manager.Shared.Resources[ProgressionInfo.NecessaryToken]
        if not ResourceInfo then continue end

        local Desc = ResourceInfo.Description
        ProgressionInfo.Name = Desc and string.sub(Desc, 1, Desc:find("Progression")-2):match("%w+$") or tostring(ProgressionIndex)

        ProgressionInfo.Index = ProgressionIndex
        self.Cache[ProgressionInfo.Name] = ProgressionInfo

        if ProgressionInfo.Name == ProgressionName then
            return ProgressionInfo
        end
    end
end

function module:Init(Manager, Tab, LoopCooldown)

    self:GetProgressionInfo(Manager)

    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Progressions")

    for ProgressionIndex, ProgressionInfo in ipairs(Manager.Shared.Progressions) do

        local LoopId = `ProgressionRoll{ProgressionInfo.Name}`
        local ToggleId = `autoUpgradeProgression_{ProgressionInfo.Name}`

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto Upgrade {ProgressionInfo.Name}`, Default = false })

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            self:Upgrade(Manager, ProgressionInfo.Name)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:Upgrade(Manager, ProgressionName: string)

    local ProgressionInfo = self:GetProgressionInfo(Manager, ProgressionName)
    if not ProgressionInfo then return end

    local Level = Manager.Data.ProgressionsLevel[tostring(ProgressionInfo.Index)] or 0
    if Level >= ProgressionInfo.MaxLevel then
        return
    end

    local BaseCost, MaxCost = ProgressionInfo.BaseCost, ProgressionInfo.MaxCost
    local GrowCost, LevelsForGrow = ProgressionInfo.GrowCost, ProgressionInfo.LevelsForGrow

    local ProgressionCost = math.min(math.floor(BaseCost * (1 + GrowCost / 100) ^ math.floor(Level / LevelsForGrow)), MaxCost)
    local CanUpgrade = (Manager.Data.Resources[ProgressionInfo.NecessaryToken] or 0) >= ProgressionCost

    if not CanUpgrade then
        return
    end

    Manager:Signal("UpgradeProgressionEvent", ProgressionInfo.Index)
end

return module
