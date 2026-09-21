local Gacha = {
    Options = {},
    PetOptions = {},
    CustomNames = {},
}

function Gacha:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GachaConfig

    for Name, Data in pairs(self.Data) do
        if Data.System == "Pet" then
            for TypeName in pairs(Data.Types or {}) do
                local Label = `{Name} ({TypeName})`
                self.CustomNames[Label] = { Name = Name, Type = TypeName }
                table.insert(self.PetOptions, Label)
            end
        elseif not Data.SelectGacha then
            if Data.Banner then
                for TypeName in pairs(Data.Types or {}) do
                    local Label = `{Name} ({TypeName})`
                    self.CustomNames[Label] = { Name = Name, Type = TypeName }
                    table.insert(self.Options, Label)
                end
            else
                table.insert(self.Options, Name)
            end
        end
    end

    table.sort(self.Options)
    table.sort(self.PetOptions)
end

return Gacha
