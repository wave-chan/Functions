--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager)
    Manager = OwnManager

    Manager.Utils.Loop:Connect(0, function()
        Manager.Cache.AttackRange = 8 * (Manager.GetServices.Multiplier.AttackRange(Manager.Player) or 1)
        Manager.Library.Enemies = Manager.GetServices.Enemy:GetNearests()
    end, function()
        return not Manager.Fluent.Unloaded
    end)
end

function module:IsSameMap(EnemyPart: BasePart)
    if not EnemyPart or not EnemyPart.Parent then return end

    local Data = Manager.Library.PlayerData
    if not Data then return end

    local PlrMode = Manager.Player:GetAttribute("Mode")

    local EnemyMap = EnemyPart:GetAttribute("Map")
    local EnemyGamemode = EnemyPart:GetAttribute("Gamemode") and EnemyPart:GetAttribute("Type")

    if EnemyMap ~= Data.CurrentMap and not EnemyGamemode then
        return false
    elseif PlrMode and EnemyGamemode ~= PlrMode then
        return false
    end

    return true
end

function module:GetNames(Include: string)
    local array = {}

    if Include then
        table.insert(array, Include)
    end

    local Data = Manager.Library.PlayerData
    if not Data then return array end

    local Enemies = Manager.Library.Enemies
    if not Enemies then return array end

    for _, EnemyPart in ipairs(Enemies) do
        if not self:IsSameMap(EnemyPart) then continue end

        local EnemyName = EnemyPart:GetAttribute("Name") :: string
        if not EnemyName or table.find(array, EnemyName) then continue end

        array[EnemyPart:GetAttribute("Order") + 1 or #array + 1] = EnemyName
    end

    return array
end

function module:GetClosest(EnemiesSelected: {}, Settings: {})
    local Character, HRP = Manager.Utils.Character:Get()
    if not Character or not HRP then return {} end

    local Data = Manager.Library.PlayerData
    if not Data then return {} end

    local Enemies = Manager.Library.Enemies
    if not Enemies then return {} end

    EnemiesSelected = EnemiesSelected or {"All"}
    Settings = Settings or {}

    local FindAll = EnemiesSelected["All"] or table.find(EnemiesSelected, "All")

    local AttackRange = (Manager.Cache.AttackRange or 8) * 1.25
    local AllIDs = {}

    local ClosestEnemy = { Magnitude = math.huge }
    for _, EnemyPart: BasePart in ipairs(Enemies) do
        if not self:IsSameMap(EnemyPart) then continue end

        local EnemyName = EnemyPart:GetAttribute("Name")
        if not EnemyName and not FindAll then continue end

        local IsSelected = EnemiesSelected[EnemyName] or table.find(EnemiesSelected, EnemyName)
        if not IsSelected and not FindAll then continue end

        local Dead = EnemyPart:GetAttribute("Died")
        if Dead then continue end

        local HP = EnemyPart:GetAttribute("HP")
        if HP <= 0 then continue end

        local EnemyCFrame = CFrame.new(EnemyPart.Position.X, HRP.Position.Y, EnemyPart.Position.Z)
        local Magnitude = Manager.Utils.Character:GetMagnitudeFromCharacter(EnemyCFrame)

        if Magnitude <= AttackRange then
            table.insert(AllIDs, EnemyPart.Name)
        end

        if Settings.PriorityEnemy and Settings.PriorityEnemy == EnemyName then
            ClosestEnemy = { Magnitude = Magnitude, ID = EnemyPart.Name, Instance = EnemyPart, Position = EnemyPart.Position }
            break
        end

        if Magnitude < ClosestEnemy.Magnitude then
            ClosestEnemy = { Magnitude = Magnitude, ID = EnemyPart.Name, Instance = EnemyPart, Position = EnemyPart.Position }
        end
    end

    return ClosestEnemy, AllIDs, Character
end

function module:GetMost(EnemiesSelected: {}, Settings: {})
    local Character, HRP = Manager.Utils.Character:Get()
    if not Character or not HRP then return {} end

    local Data = Manager.Library.PlayerData
    if not Data then return {} end

    local Enemies = Manager.Library.Enemies
    if not Enemies then return {} end

    EnemiesSelected = EnemiesSelected or {"All"}
    Settings = Settings or {}

    local FindAll = EnemiesSelected["All"] or table.find(EnemiesSelected, "All")

    local AttackRange = Manager.Cache.AttackRange or 8
    local AttackRangeSq = AttackRange * AttackRange

    -- Step 1: collect every valid (right map, selected, alive) enemy's position
    local ValidEnemies = {}
    local PriorityEnemy = nil

    for _, EnemyPart: BasePart in ipairs(Enemies) do
        if not self:IsSameMap(EnemyPart) then continue end

        local EnemyName = EnemyPart:GetAttribute("Name")
        if not EnemyName and not FindAll then continue end

        local IsSelected = EnemiesSelected[EnemyName] or table.find(EnemiesSelected, EnemyName)
        if not IsSelected and not FindAll then continue end

        local Dead = EnemyPart:GetAttribute("Died")
        if Dead then continue end

        local HP = EnemyPart:GetAttribute("HP")
        if HP <= 0 then continue end

        local EnemyData = { ID = EnemyPart.Name, Name = EnemyName, Instance = EnemyPart, Position = EnemyPart.Position }
        table.insert(ValidEnemies, EnemyData)

        if Settings.PriorityEnemy and Settings.PriorityEnemy == EnemyName then
            PriorityEnemy = EnemyData
        end
    end

    -- Counts (and collects the IDs of) enemies within AttackRange of a point
    local function GetInRange(Position: Vector3)
        local Count = 0
        local IDs = {}
        for _, Enemy in ipairs(ValidEnemies) do
            if (Position - Enemy.Position).Magnitude ^ 2 <= AttackRangeSq then
                Count += 1
                table.insert(IDs, Enemy.ID)
            end
        end
        return Count, IDs
    end

    -- Step 2: priority enemy requested -> target it directly
    if PriorityEnemy then
        local Count, IDs = GetInRange(PriorityEnemy.Position)
        local Magnitude = Manager.Utils.Character:GetMagnitudeFromCharacter(CFrame.new(PriorityEnemy.Position))
        return { Count = Count, ID = PriorityEnemy.ID, Instance = PriorityEnemy.Instance, Position = PriorityEnemy.Position, Magnitude = Magnitude }, IDs, Character
    end

    if #ValidEnemies == 0 then
        return {}, {}, Character
    end

    -- Step 3: candidate spots — each enemy's position, the group average, and close-enough pairs' midpoints
    local CandidatePositions = {}

    for _, Enemy in ipairs(ValidEnemies) do
        table.insert(CandidatePositions, Enemy.Position)
    end

    local SumPosition = Vector3.zero
    for _, Enemy in ipairs(ValidEnemies) do
        SumPosition += Enemy.Position
    end
    table.insert(CandidatePositions, SumPosition / #ValidEnemies)

    local MaxPairDistance = AttackRange * 2
    for i = 1, #ValidEnemies do
        for j = i + 1, #ValidEnemies do
            local A, B = ValidEnemies[i].Position, ValidEnemies[j].Position
            if (A - B).Magnitude <= MaxPairDistance then
                table.insert(CandidatePositions, (A + B) / 2)
            end
        end
    end

    -- Step 4: pick whichever candidate has the most enemies in range, tiebreak by distance to player
    local Best = { Count = 0, Magnitude = math.huge }
    local BestIDs = {}

    for _, TestPosition in ipairs(CandidatePositions) do
        local Count, IDs = GetInRange(TestPosition)
        local Magnitude = Manager.Utils.Character:GetMagnitudeFromCharacter(CFrame.new(TestPosition))

        if Count > Best.Count or (Count == Best.Count and Count > 0 and Magnitude < Best.Magnitude) then
            Best = { Count = Count, Position = TestPosition, Magnitude = Magnitude }
            BestIDs = IDs
        end
    end

    return Best, BestIDs, Character
end

return module
