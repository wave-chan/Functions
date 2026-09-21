local Potions = { Options = {} }

function Potions:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab

    for Id, Data in pairs(Manager.Shared.ItemData) do
        if typeof(Id) == "string" and Id:match("Potion[12]$") and Data.Type == "Consumable" then
            table.insert(self.Options, Id)
        end
    end

    table.sort(self.Options)
    self.Enabled = false
    self.Selected = {}
    Tab:CreateDivider({ text = "Spend inventory potions", line = true })
    Tab:CreateToggle({ name = "Auto Use Potion", flag = "AutoUsePotion", value = false, callback = function(Value) self.Enabled = Value == true end })
    Tab:CreateDropdown({ name = "Selected Potions", flag = "SelectedPotions", options = self.Options, value = {}, multiSelect = true, callback = function(Value) self.Selected = Value or {} end })
    task.spawn(function()
        while Manager.Cache.Running do
            if self.Enabled then
                local Items = Manager.Library.PlayerData and Manager.Library.PlayerData.Items or {}
                for _, Id in ipairs(self.Selected) do
                    if (tonumber(Items[Id]) or 0) >= 100 then
                        Manager.Library.Remote:Fire("ItemSystem", "Use", Id, 10, nil)
                    end
                end
            end
            task.wait(1)
        end
    end)
end

return Potions
