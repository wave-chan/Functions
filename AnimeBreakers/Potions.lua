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
end

return Potions
