local Raid = {}

function Raid:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Data = Manager.Shared.GamemodeData.Raid
    self.Options = {}
    for Name in pairs(self.Data) do table.insert(self.Options, Name) end
    table.sort(self.Options)
    self.Enabled = false
    self.Map = self.Options[1]
    Tab:CreateDivider({ text = "Raid automation", line = true })
    Tab:CreateToggle({ name = "Auto Raid", flag = "AutoRaid", value = false, callback = function(Value) self.Enabled = Value == true end })
    Tab:CreateToggle({ name = "Auto Farm Ticket", flag = "AutoFarmTicket", value = false })
    Tab:CreateToggle({ name = "Auto Join", flag = "AutoJoinRaid", value = false })
    Tab:CreateDropdown({ name = "Raid", flag = "RaidMap", options = self.Options, value = self.Map, callback = function(Value) self.Map = Value end })
    Tab:CreateSlider({ name = "Leave at Wave", flag = "RaidLeaveWave", range = { 1, 100 }, value = 100, increment = 1 })
    self.Status = Tab:CreateText({ name = "Status", text = "Auto Raid disabled." })
end

return Raid
