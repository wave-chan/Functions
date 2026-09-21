local Gamemodes = {}

function Gamemodes:Init(Manager)
    self.Manager = Manager
    self.Data = Manager.Shared.GamemodeData
    self.Service = Manager.GetServices.Gamemode
end

return Gamemodes
