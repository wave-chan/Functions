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

    self.Enabled = false
    self.Selected = {}
    self.PetEnabled = false
    self.PetSelected = nil
    Tab:CreateDivider({ text = "Regular gachas", line = true })
    Tab:CreateToggle({ name = "Auto Gachas", flag = "AutoGacha", value = false, callback = function(Value) self.Enabled = Value == true end })
    Tab:CreateDropdown({ name = "Gacha Priority List", flag = "GachaPriorityList", options = self.Options, value = {}, multiSelect = true, callback = function(Value) self.Selected = Value or {} end })
    Tab:CreateDivider({ text = "Pet auto spin", line = true })
    Tab:CreateToggle({ name = "Auto Pets", flag = "AutoPetGacha", value = false, callback = function(Value) self.PetEnabled = Value == true end })
    Tab:CreateDropdown({ name = "Pet Gacha", flag = "PetGachaSelection", options = self.PetOptions, value = nil, callback = function(Value) self.PetSelected = Value end })
    self.Status = Tab:CreateText({ name = "Gacha Status", text = "Waiting for selection." })

    task.spawn(function()
        while Manager.Cache.Running do
            if self.Enabled then
                for _, Label in ipairs(self.Selected) do
                    local Custom = self.CustomNames[Label]
                    local Name = Custom and Custom.Name or Label
                    local Type = Custom and Custom.Type or nil
                    Manager.Library.Remote:Fire("GachaSystem", "Spin", Name, Type, {})
                    self.Status:Set("Spinning " .. Label)
                    task.wait(0.15)
                    if not self.Enabled then break end
                end
            end
            if self.PetEnabled and self.PetSelected then
                local Data = self.CustomNames[self.PetSelected]
                if Data then
                    Manager.Library.Remote:Fire("SpinManagerSystem", "Add", Data.Name, Data.Type, {}, nil)
                    self.Status:Set("Pet auto spin: " .. self.PetSelected)
                end
            end
            task.wait((self.Enabled or self.PetEnabled) and 0.5 or 1)
        end
    end)
end

return Gacha
