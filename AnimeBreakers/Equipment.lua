local Equipment = {}

function Equipment:Init(Manager, Tab)
    self.Manager = Manager
    self.Tab = Tab
    self.MultiplierService = Manager.GetServices.Multiplier
end

return Equipment
