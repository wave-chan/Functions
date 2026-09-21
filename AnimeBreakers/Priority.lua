local Priority = {}

function Priority:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    Tab:CreateText({ name = "Priority order", text = "Select which enabled activity should run first." })
    Tab:CreateDropdown({ name = "Activity Priority", flag = "ModePriority", options = { "Trial", "Portal", "Raid", "Farm" }, value = { "Trial", "Portal", "Raid", "Farm" }, multiSelect = true, callback = function(Value)
        Manager.Cache.ModePriority = Value or {}
    end })
end

return Priority
