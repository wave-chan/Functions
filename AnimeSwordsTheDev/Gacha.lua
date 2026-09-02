--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager, Tab, LoopCooldown)
    Manager = OwnManager
    
    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Gachas")

    local GachaArray = {}
    for GachaName, GachaInfo in pairs(Manager.Library.Shared.Gachas) do
        GachaInfo.Information.Index = GachaInfo.Information.Index or 1
        table.insert(GachaArray, GachaInfo.Information.Index + #GachaArray, GachaName)
    end

    for Index, GachaName in ipairs(Manager.Library.Shared.Gachas) do
    
        local LoopId = `GachaRoll{GachaName}`
        local ToggleId = `autoRollGacha_{GachaName}`

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto Roll {GachaName}`, Default = false })

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            self:Roll(GachaName)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:Roll(GachaName: string)

    --## INFO ##--
    local GachaInfo = Manager.Library.Shared.Gachas[GachaName]
    if not GachaInfo then return end

    --## CHECKS ##--
    local GachaCost = GachaInfo.Information.Amount
    local CanRoll = (Manager.Library.Data.Inventory[GachaInfo.Information.Item] or 0) >= GachaCost

    if not CanRoll then
        return
    end

    Manager:Signal("General", "Gacha", "Roll", GachaName, {})

end

return module
