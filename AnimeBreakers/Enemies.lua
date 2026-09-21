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

return Enemies
