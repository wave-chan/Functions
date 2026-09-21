local Enemies = {}

function Enemies:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.Root = Manager.Services.Workspace:WaitForChild("_ENEMIES"):WaitForChild("Server")
    self.MapData = Manager.Shared.MapData
end

function Enemies:Get()
    return self.Root:GetChildren()
end

function Enemies:IsAlive(Enemy)
    return Enemy and Enemy.Parent ~= nil and Enemy:GetAttribute("Dead") ~= true
        and (tonumber(Enemy:GetAttribute("HP")) or 0) > 0
end

function Enemies:GetAlive()
    local Alive = {}
    for _, Enemy in ipairs(self:Get()) do
        if self:IsAlive(Enemy) then table.insert(Alive, Enemy) end
    end
    return Alive
end

function Enemies:GetNames()
    local Names, Seen = {}, {}
    for _, Enemy in ipairs(self:Get()) do
        if self:IsAlive(Enemy) and not Seen[Enemy.Name] then
            Seen[Enemy.Name] = true
            table.insert(Names, Enemy.Name)
        end
    end
    table.sort(Names)
    return Names
end

function Enemies:GetWorldNames()
    local Worlds = {}
    for Name, Data in pairs(self.MapData) do
        if typeof(Data) == "table" then table.insert(Worlds, Name) end
    end
    table.sort(Worlds)
    return Worlds
end

function Enemies:GetClosest(Selected)
    local Character = self.Manager.Player.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end
    local Allowed = {}
    for _, Name in ipairs(Selected or {}) do Allowed[Name] = true end
    local Closest, Distance
    for _, Enemy in ipairs(self:GetAlive()) do
        local Position = Enemy:GetPivot().Position
        local Magnitude = (Root.Position - Position).Magnitude
        if (next(Allowed) == nil or Allowed[Enemy.Name]) and (not Distance or Magnitude < Distance) then
            Closest, Distance = Enemy, Magnitude
        end
    end
    return Closest, Distance
end

return Enemies
