local Equipment = {}

function Equipment:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.MultiplierService = Manager.GetServices.Multiplier
    self.Enabled = { Weapon = false, Accessory = false, Pet = false, Merge = false }
    Tab:CreateDivider({ text = "Inventory equipment", line = true })
    for _, Category in { "Weapon", "Accessory", "Pet" } do
        Tab:CreateToggle({ name = "Auto Equip Best " .. Category, flag = "AutoEquip" .. Category, value = false, callback = function(Value) self.Enabled[Category] = Value == true end })
    end
    Tab:CreateToggle({ name = "Auto Merge All Weapons", flag = "AutoMergeWeapons", value = false, callback = function(Value) self.Enabled.Merge = Value == true end })
    task.spawn(function()
        while Manager.Cache.Running do
            for _, Category in { "Weapon", "Accessory", "Pet" } do
                if self.Enabled[Category] then Manager.Library.Remote:Fire("InventorySystem", "EquipBest", Category) end
            end
            if self.Enabled.Merge then Manager.Library.Remote:Fire("MergeSystem", "MakeAll", "Weapon") end
            task.wait(5)
        end
    end)
end

return Equipment
