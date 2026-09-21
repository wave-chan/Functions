local Farm = {}

function Farm:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Enabled = false
    self.Selected = {}

    Tab:CreateDivider({ text = "Farming and target order", line = true })
    Tab:CreateToggle({ name = "Auto Farm", flag = "AutoFarm", value = false, callback = function(Value)
        self.Enabled = Value == true
    end })
    self.Worlds = Tab:CreateDropdown({ name = "World Priority", flag = "WorldPriorityList", options = Manager.Functions.Enemies:GetWorldNames(), value = {}, multiSelect = true })
    self.Enemies = Tab:CreateDropdown({ name = "Priority List", flag = "PriorityList", options = Manager.Functions.Enemies:GetNames(), value = {}, multiSelect = true, callback = function(Value)
        self.Selected = Value or {}
    end })
    Tab:CreateButton({ name = "Refresh Enemies", callback = function()
        self.Enemies:Refresh(Manager.Functions.Enemies:GetNames())
    end })
    self.Status = Tab:CreateText({ name = "Status", text = "Auto Farm disabled." })

    task.spawn(function()
        while Manager.Cache.Running do
            if self.Enabled then
                local Enemy = Manager.Functions.Enemies:GetClosest(self.Selected)
                local Character = Manager.Player.Character
                if Enemy and Character then
                    Manager.UI:Change(self.Status, "Farming " .. Enemy.Name)
                    Character:PivotTo(Enemy:GetPivot() * CFrame.new(0, 3, 0))
                else
                    Manager.UI:Change(self.Status, "Waiting for a selected enemy...")
                end
            else
                Manager.UI:Change(self.Status, "Auto Farm disabled.")
            end
            task.wait(self.Enabled and 0.1 or 0.5)
        end
    end)
end

return Farm
