--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager, Tab, LoopCooldown)
    Manager = OwnManager
    
    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Gachas")

    local AuxArray = {}
    for GachaName, GachaInfo in pairs(Manager.Shared.GachaConfig) do
        if GachaInfo.SelectGacha then continue end
        local Index = (Manager.Shared.MapData[GachaInfo.Map or "Lobby"].Order or 0) + 1
        
        if not AuxArray[Index] then
            AuxArray[Index] = {}
        end

        table.insert(AuxArray[Index], GachaName)
    end

    local GachaArray = {}
    for CategoryIndex, Table in ipairs(AuxArray) do
        for GachaIndex, GachaName in ipairs(Table) do
            table.insert(GachaArray, #GachaArray + 1, GachaName)
        end
    end

    for Index, GachaName in ipairs(GachaArray) do

        local GachaInfo = Manager.Shared.GachaConfig[GachaName]
        if not GachaInfo then continue end
    
        local LoopId = `GachaRoll{GachaName}`
        local ToggleId = `autoRollGacha_{GachaName}`

        local Types = {}
        for TypeName, TypeInfo in pairs(GachaInfo.Types or {}) do
            Types[TypeInfo.Order or 1] = TypeName
        end

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto Roll {GachaName}`, Default = false })
        local Dropdown
        if #Types > 1 or not (GachaInfo.Types or {}).Default then
          Dropdown = Section:AddDropdown(`rollGachaType_{GachaName}`, {
              Title = "Select the enemies",
              Values = Types,
              Multi = false,
              Default = Types[1],
          })
        end

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            self:Roll(GachaName, Dropdown and Dropdown.Value)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:Roll(GachaName: string, GachaType: string)

    GachaType = GachaType or "Default"

    --## INFO ##--
    local GachaInfo = Manager.Shared.GachaConfig[GachaName]
    if not GachaInfo then return end

    local TypeInfo = (GachaInfo.Types or {})[GachaType]
    if not TypeInfo then return end
  
    --## CHECKS ##--
    local GachaCost = (TypeInfo.CostAmount or 10) * (Manager.Library.PlayerData.Gamepasses.VIP and 0.70 or 1)
    local CanRoll = (Manager.Library.PlayerData.Items[TypeInfo.Currency] or 0) >= GachaCost

    if not CanRoll then
        return
    end

    Manager:Signal("GachaSystem", "Spin", GachaName, GachaType, {})

end

return module
