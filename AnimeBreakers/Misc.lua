--## SCRIPT ##--
local Functions = {}
local Manager = {}

local MovementHumanoid
local SavedSpeed
local SavedJumpPower
local SavedJumpHeight
local MiscStopped = false
local SpeedConnection
local MovementStepConnection
local WritingSpeed = false

function Functions:Init(OwnManager)
    Manager = OwnManager

    local LastExtraJumpAt = -math.huge
    local MiscJumpConnection = Manager.Services.UserInputService.JumpRequest:Connect(function()
        if MiscStopped or not Functions:IsRunning() or not Manager.Config.InfinityJump then return end
        if Manager.Services.UserInputService:GetFocusedTextBox() then return end
        local Character = Manager.Player.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Humanoid or Humanoid.Health <= 0 or Humanoid.Sit or Humanoid.PlatformStand
            or not Root or Root.Anchored then return end
        local Now = os.clock()
        if Now - LastExtraJumpAt < 0.15 then return end
        LastExtraJumpAt = Now
        ApplyMiscMovement()
        local Power = Humanoid.UseJumpPower and Humanoid.JumpPower
            or math.sqrt(2 * math.max(0, workspace.Gravity) * Humanoid.JumpHeight)
        local Velocity = Root.AssemblyLinearVelocity
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        Root.AssemblyLinearVelocity = Vector3.new(Velocity.X, Power, Velocity.Z)
    end)

    MovementStepConnection = Manager.Services.RunService.PreSimulation:Connect(function()
        if not Functions:IsRunning() then
            Functions:CleanupMisc()
            return
        end
        ApplyMiscMovement()
    end)
    
    Manager.Runtime.setSpeedEnabled = function(Enabled)
        Manager.Config.SpeedEnabled = Enabled == true
        ApplyMiscMovement()
        Functions:QueueSave()
    end

end

local function WriteSpeed(Humanoid, Value)
    WritingSpeed = true
    Humanoid.WalkSpeed = Value
    WritingSpeed = false
end

local function RestoreMiscMovement()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
    local Humanoid = MovementHumanoid
    if Humanoid and Humanoid.Parent then
        if SavedSpeed ~= nil then Humanoid.WalkSpeed = SavedSpeed end
        if SavedJumpPower ~= nil then Humanoid.JumpPower = SavedJumpPower end
        if SavedJumpHeight ~= nil then Humanoid.JumpHeight = SavedJumpHeight end
    end
    SavedSpeed, SavedJumpPower, SavedJumpHeight = nil, nil, nil
end

local function ApplyMiscMovement()
    if MiscStopped or not Functions:IsRunning() then return end
    local Character = Manager.Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid ~= MovementHumanoid then
        RestoreMiscMovement()
        MovementHumanoid = Humanoid
        if Humanoid then
            SpeedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if WritingSpeed or MiscStopped or not Functions:IsRunning() then return end
                if Manager.Config.SpeedEnabled and Humanoid.Health > 0
                    and Humanoid.WalkSpeed ~= Manager.Config.SpeedValue then
                    SavedSpeed = Humanoid.WalkSpeed
                    WriteSpeed(Humanoid, Manager.Config.SpeedValue)
                end
            end)
        end
    end
    if not Humanoid or Humanoid.Health <= 0 then return end

    if Manager.Config.SpeedEnabled then
        if SavedSpeed == nil then SavedSpeed = Humanoid.WalkSpeed end
        if Humanoid.WalkSpeed ~= Manager.Config.SpeedValue then
            WriteSpeed(Humanoid, Manager.Config.SpeedValue)
        end
    elseif SavedSpeed ~= nil then
        WriteSpeed(Humanoid, SavedSpeed)
        SavedSpeed = nil
    end

    if Manager.Config.JumpHighEnabled then
        if SavedJumpPower == nil then
            SavedJumpPower, SavedJumpHeight = Humanoid.JumpPower, Humanoid.JumpHeight
        end
        local Power = math.sqrt(2 * math.max(0, workspace.Gravity) * Manager.Config.JumpHeightValue)
        if Humanoid.JumpPower ~= Power then Humanoid.JumpPower = Power end
        if Humanoid.JumpHeight ~= Manager.Config.JumpHeightValue then
            Humanoid.JumpHeight = Manager.Config.JumpHeightValue
        end
    elseif SavedJumpPower ~= nil then
        Humanoid.JumpPower, Humanoid.JumpHeight = SavedJumpPower, SavedJumpHeight
        SavedJumpPower, SavedJumpHeight = nil, nil
    end
end

function Functions:CleanupMisc()
    MiscStopped = true
    if MovementStepConnection then
        MovementStepConnection:Disconnect()
        MovementStepConnection = nil
    end
    MiscJumpConnection:Disconnect()
    RestoreMiscMovement()
    MovementHumanoid = nil
end

return Functions
