local Misc = {}

function Misc:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.SpeedEnabled = false
    self.Speed = 16
    self.JumpEnabled = false
    self.JumpHeight = 7

    Tab:CreateDivider({ text = "Miscellaneous", line = true })
    Tab:CreateToggle({ name = "Anti-AFK", flag = "AntiAFK", value = true })
    Tab:CreateDivider({ text = "Movement", line = true })
    Tab:CreateToggle({ name = "Speed", flag = "SpeedEnabled", value = false, callback = function(Value) self.SpeedEnabled = Value == true end })
    Tab:CreateSlider({ name = "Speed Value", flag = "SpeedValue", range = { 1, 150 }, value = 16, increment = 1, callback = function(Value) self.Speed = Value end })
    Tab:CreateToggle({ name = "Jump High", flag = "JumpHighEnabled", value = false, callback = function(Value) self.JumpEnabled = Value == true end })
    Tab:CreateSlider({ name = "Jump Height", flag = "JumpHeightValue", range = { 5, 100 }, value = 7, increment = 1, callback = function(Value) self.JumpHeight = Value end })

    task.spawn(function()
        while Manager.Cache.Running do
            local Humanoid = self:GetHumanoid()
            if Humanoid then
                if self.SpeedEnabled then self:SetSpeed(self.Speed) end
                if self.JumpEnabled then self:SetJumpHeight(self.JumpHeight) end
            end
            task.wait(0.1)
        end
    end)
end

function Misc:GetHumanoid()
    local Character = self.Manager.Player.Character
    return Character and Character:FindFirstChildOfClass("Humanoid")
end

function Misc:SetSpeed(Value)
    local Humanoid = self:GetHumanoid()
    if Humanoid then Humanoid.WalkSpeed = Value end
end

function Misc:SetJumpHeight(Value)
    local Humanoid = self:GetHumanoid()
    if not Humanoid then return end
    Humanoid.JumpHeight = Value
    Humanoid.JumpPower = math.sqrt(2 * math.max(0, workspace.Gravity) * Value)
end

return Misc
