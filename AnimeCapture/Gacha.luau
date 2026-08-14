--## SCRIPT ##--
local module = { Cache = {}, }

function module:GetGachaInfo(Manager, GachaName: string)
    local Cache = self.Cache[GachaName]
    if Cache then return Cache end

    for GachaIndex, GachaInfo in ipairs(Manager.Shared.Gachas) do
        GachaInfo.Index = GachaIndex
        self.Cache[GachaInfo.Name] = GachaInfo

        if GachaInfo.Name == GachaName then
            return GachaInfo
        end
    end
end

function module:Init(Manager, Tab, LoopCooldown)

    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Gachas")

    for GachaIndex, GachaInfo in ipairs(Manager.Shared.Gachas) do

        local LoopId = `GachaRoll{GachaInfo.Name}`
        local ToggleId = `autoRollGacha_{GachaInfo.Name}`

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto Roll {GachaInfo.Name}`, Default = false })

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            self:RollGacha(Manager, GachaInfo.Name)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:RollGacha(Manager, GachaName: string)

    --## INFO ##--
    local GachaInfo = self:GetGachaInfo(Manager, GachaName)
    if not GachaInfo then return end

    --## CHECKS ##--
    local GachaDiscount = 1 - (Manager.Data.GachaDiscount or 0)
    local GachaCost = GachaInfo.RollCost.Amount * GachaDiscount
    local CanRoll = (Manager.Data.Resources[GachaInfo.RollCost.Resource] or 0) >= GachaCost

    if not CanRoll then
        return
    end

    local EventName = GachaInfo.IsBanner and "RollGachaBanner" or "RollGacha"
    Manager:Signal(`{EventName}Event`, GachaInfo.Index)

end

return module
