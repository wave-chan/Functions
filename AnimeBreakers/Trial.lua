local Trial = {}

function Trial:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GamemodeData["Time Trial"] or Manager.Shared.GamemodeData.Trial
    self.Enabled = false
    self.LeaveWave = 100
    Tab:CreateDivider({ text = "Trial automation", line = true })
    Tab:CreateToggle({ name = "Auto Time Trial", flag = "AutoGamemode", value = false, callback = function(Value) self.Enabled = Value == true end })
    Tab:CreateSlider({ name = "Leave at Wave", flag = "TrialLeaveWave", range = { 1, 100 }, value = 100, increment = 1, callback = function(Value) self.LeaveWave = Value end })
    self.Status = Tab:CreateText({ name = "Status", text = "Auto Time Trial disabled." })
    task.spawn(function()
        while Manager.Cache.Running do
            if self.Enabled then
                local Mode = Manager.Player:GetAttribute("Mode")
                if Mode ~= "Time Trial" then
                    Manager.Library.Remote:Fire("GamemodeSystem", "Enter", "Time Trial", "The Hallway", "Easy")
                    self.Status:Set("Waiting to enter Time Trial...")
                else
                    self.Status:Set("Time Trial active.")
                end
            end
            task.wait(self.Enabled and 1 or 2)
        end
    end)
end

return Trial
