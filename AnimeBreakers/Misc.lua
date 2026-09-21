local Misc = {}

function Misc:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
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
