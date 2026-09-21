local ModeContext = {}

function ModeContext:Init(Manager)
    self.Manager = Manager
end

function ModeContext:GetRoom()
    local Id = self.Manager.Player:GetAttribute("InMode")
    if Id == nil or Id == false or Id == "" then return nil end

    local Server = self.Manager.Services.ReplicatedStorage:FindFirstChild("Server")
    local Rooms = Server and Server:FindFirstChild("Gamemode")
    return Rooms and Rooms:FindFirstChild(tostring(Id))
end

function ModeContext:Confirm(Mode, RoomMode, Status, Teleporting, Results, Healthy)
    if Teleporting or Results or not Healthy then return nil end
    if Mode ~= RoomMode or Status ~= "Running" then return nil end
    if Mode == "Portal" or Mode == "Raid" or Mode == "Time Trial" then return Mode end
    return nil
end

function ModeContext:Get()
    local Room = self:GetRoom()
    local Character = self.Manager.Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Healthy = Humanoid ~= nil and Humanoid.Health > 0
        and Character:FindFirstChild("HumanoidRootPart") ~= nil
    local Results = self.Manager.Library:GetScreen("Results")

    return self:Confirm(
        self.Manager.Player:GetAttribute("Mode"),
        Room and Room:GetAttribute("ModeId"),
        Room and Room:GetAttribute("Status"),
        self.Manager.Player:GetAttribute("Teleporting"),
        Results.Enabled,
        Healthy
    )
end

function ModeContext:IsEnabled(Mode, Config)
    if Mode == "Portal" then return Config.AutoPortal or Config.AutoJoinPortal end
    if Mode == "Raid" then return Config.AutoRaid or Config.AutoJoinRaid end
    return false
end

return ModeContext
