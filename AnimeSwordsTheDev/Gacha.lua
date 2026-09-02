--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager, Tab, LoopCooldown)
    Manager = OwnManager
    
    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Gachas")

    local AuxArray = {}
    for GachaName, GachaInfo in pairs(Manager.Library.Shared.Gachas) do
        local Index = GachaInfo.Information.Index or 1
        
        if not AuxArray[Index] then
            table.insert(AuxArray, Index, {})
        end

        print("Added category index", Index, GachaName)
        table.insert(AuxArray[Index], GachaName)
    end

    local GachaArray = {}
    for CategoryIndex, Table in ipairs(AuxArray) do
        for GachaIndex, GachaName in ipairs(Table) do
            print("Added category", CategoryIndex - 1, "added gacha index", GachaIndex, GachaName, "|", (CategoryIndex - 1) + GachaIndex)
            table.insert(GachaArray, (CategoryIndex - 1) + GachaIndex, GachaName)
        end
    end

    for Index, GachaName in ipairs(GachaArray) do
    
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
