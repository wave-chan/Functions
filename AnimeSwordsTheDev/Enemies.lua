--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager)
    Manager = OwnManager
end

function module:IsSameWorld(EnemyTable)
    local Current = Manager.Player:GetAttribute("Mode") or Manager.Library.Data.Map
    if not Current then return end

    local EnemyFolder = EnemyTable.Instance and EnemyTable.Instance.Parent
    if not EnemyFolder then return end

    local EnemyMap = EnemyFolder.Name
    if not EnemyMap then return end

    Current = string.gsub(Current, " ", "")
    EnemyMap = string.gsub(EnemyMap, " ", "")

    print(Current, EnemyMap)

    return Current == EnemyMap
end

function module:GetClosest(EnemiesSelected: {}, Settings: {})
    local Character, HRP = Manager.Utils.Character:Get()
    if not Character or not HRP then return {} end

    local InGamemode = Manager.Data.Gamemode
    Settings = Settings or {}

    EnemiesSelected = EnemiesSelected or {"All"}
    local FindAll = EnemiesSelected["All"] or table.find(EnemiesSelected, "All")

    local ClosestEnemy = { Magnitude = math.huge }
    for EnemyId, EnemyTable in pairs(Manager.Library.Enemies) do
        if typeof(EnemyTable) ~= "table" then continue end
        if not self:IsSameWorld(EnemyTable) then continue end

        local EnemyName = EnemyTable.Name
        if not EnemyName then continue end

        local IsSelected = EnemiesSelected[EnemyName] or table.find(EnemiesSelected, EnemyName)
        if not IsSelected and not FindAll then continue end

        local Dead = EnemyTable.Instance:GetAttribute("Died")
        if Dead then continue end

        local Health = EnemyTable.Instance:GetAttribute("Health")
        if Health <= 0 then continue end

        local EnemyCFrame = CFrame.new(EnemyTable.Instance.Position.X, HRP.Position.Y, EnemyTable.Instance.Position.Z)
        local Magnitude = Manager.Utils.Character:GetMagnitudeFromCharacter(EnemyCFrame)

        if Settings.PriorityEnemy and Settings.PriorityEnemy == EnemyName then
            ClosestEnemy = { Magnitude = Magnitude, EnemyMagnitude = EnemyMagnitude, ID = EnemyId, Model = EnemyTable.Character, Position = EnemyTable.Instance.Position }
            break
        end

        if Magnitude < ClosestEnemy.Magnitude then
            ClosestEnemy = { Magnitude = Magnitude, EnemyMagnitude = EnemyMagnitude, ID = EnemyId, Model = EnemyTable.Character, Position = EnemyTable.Instance.Position }
        end
    end

    return ClosestEnemy :: {}, Character :: Model
end

function module:GetIDs()
    local Character, HRP = Manager.Utils.Character:Get()
    if not Character or not HRP then return {} end

    local AttackDistance = Manager.Library.Shared.Player_Stats.AttackDistance:Get() or 10
    AttackDistance = math.max(AttackDistance, 20)

    local IDs = {}
    for EnemyId, EnemyTable in pairs(Manager.Library.Enemies) do
        if typeof(EnemyTable) ~= "table" then continue end

        local Dead = EnemyTable.Instance:GetAttribute("Died")
        if Dead then continue end

        local Health = EnemyTable.Instance:GetAttribute("Health")
        if Health <= 0 then continue end

        local EnemyCFrame = CFrame.new(EnemyTable.Instance.Position.X, HRP.Position.Y, EnemyTable.Instance.Position.Z)
        local Magnitude = Manager.Utils.Character:GetMagnitudeFromCharacter(EnemyCFrame)
        if Magnitude > AttackDistance then continue end

        IDs[EnemyId] = true
    end

    return IDs
end

return module
