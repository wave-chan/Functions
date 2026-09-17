--## SCRIPT ##--
local Functions = { Cache = {}, }
local Manager

function Functions:Init(OwnManager)
    Manager = OwnManager
    Manager.NextTerrainRequest = 0
end


function Functions:QueryEnemyParts()
    local Ok, Result = pcall(function()
        return Manager.Shared.EnemiesRoot:QueryDescendants("BasePart.EnemyServer")
    end)
    if Ok and type(Result) == "table" and #Result > 0 then
        Manager.Runtime.EnemyQueryFallback = false
        return Result
    end

    local Fallback = {}
    for _, Instance in ipairs(Manager.Shared.EnemiesRoot:GetDescendants()) do
        if Instance:IsA("BasePart")
            and (Instance:GetAttribute("HP") ~= nil
                or Instance:GetAttribute("MaxHP") ~= nil
                or Instance:GetAttribute("Id") ~= nil)
        then
            table.insert(Fallback, Instance)
        end
    end

    Manager.Runtime.EnemyQueryFallback = true
    return Fallback
end

function Functions:EnemyLabel(Enemy)
    local Id = tostring(Enemy:GetAttribute("Id") or Enemy:GetAttribute("Name") or Enemy.Name)
    local Definition = Manager.Shared.EnemyCatalog[Id]
    local Map = tostring(Definition and Definition.Map or Enemy:GetAttribute("Map") or Enemy.Parent.Name)
    return string.format("%s [%s]", Id, Map)
end

function Functions:EnemyWorld(Enemy)
    local Definition = Manager.Shared.EnemyCatalog[Enemy:GetAttribute("Id")]
    return tostring(Definition and Definition.Map or Enemy:GetAttribute("Map") or Enemy.Parent.Name)
end

function Functions:IsWorldEnemy(Enemy)
    if not Enemy or not Enemy:IsDescendantOf(Manager.Shared.EnemiesRoot) then
        return false
    end

    local Parent = Enemy.Parent
    local Server = Manager.Services.ReplicatedStorage:FindFirstChild("Server")
    local Modes = Server and Server:FindFirstChild("Gamemode")
    if not Parent or (Modes and Modes:FindFirstChild(Parent.Name)) then
        return false
    end

    return Parent.Name == Functions:EnemyWorld(Enemy)
end

function Functions:CollectEnemyOptions()
    local Seen = {}
    local Values = {}
    local Metadata = {}

    for Id, Definition in pairs(Manager.Shared.EnemyCatalog) do
        if type(Definition) == "table" and Manager.Shared.MapCatalog[Definition.Map] then
            local Label = string.format("%s [%s]", Id, Definition.Map)
            Seen[Label] = true
            table.insert(Values, Label)
            Metadata[Label] = { World = Definition.Map, MaxHealth = tonumber(Definition.HP) or 0 }
        end
    end

    for _, Enemy in ipairs(Functions:QueryEnemyParts()) do
        if not Functions:IsWorldEnemy(Enemy) then continue end
        local Label = Functions:EnemyLabel(Enemy)
        local MaxHealth = tonumber(Enemy:GetAttribute("MaxHP")) or tonumber(Enemy:GetAttribute("HP")) or 0
        local Data = Metadata[Label]
        if not Data or MaxHealth > Data.MaxHealth then
            Metadata[Label] = {
                World = Functions:EnemyWorld(Enemy),
                MaxHealth = MaxHealth,
            }
        end
        if not Seen[Label] then
            Seen[Label] = true
            table.insert(Values, Label)
        end
    end

    table.sort(Values, function(First, Second)
        local FirstData = Metadata[First] or { World = "", MaxHealth = 0 }
        local SecondData = Metadata[Second] or { World = "", MaxHealth = 0 }
        if FirstData.World ~= SecondData.World then
            local FirstOrder = (Manager.Shared.MapCatalog[FirstData.World] or {}).Order or math.huge
            local SecondOrder = (Manager.Shared.MapCatalog[SecondData.World] or {}).Order or math.huge
            if FirstOrder ~= SecondOrder then return FirstOrder < SecondOrder end
            return FirstData.World < SecondData.World
        end
        if FirstData.MaxHealth ~= SecondData.MaxHealth then
            return FirstData.MaxHealth > SecondData.MaxHealth
        end
        return First < Second
    end)
    return Values
end

function Functions:CollectWorldOptions()
    local Seen = {}
    local Values = {}
    for _, Definition in pairs(Manager.Shared.EnemyCatalog) do
        local World = Definition.Map
        if World and Manager.Shared.MapCatalog[World] and not Seen[World] then
            Seen[World] = true
            table.insert(Values, World)
        end
    end
    for _, Enemy in ipairs(Functions:QueryEnemyParts()) do
        if not Functions:IsWorldEnemy(Enemy) then continue end
        local World = Functions:EnemyWorld(Enemy)
        if not Seen[World] then
            Seen[World] = true
            table.insert(Values, World)
        end
    end
    table.sort(Values, function(A, B)
        local Ao = (Manager.Shared.MapCatalog[A] or {}).Order or math.huge
        local Bo = (Manager.Shared.MapCatalog[B] or {}).Order or math.huge
        if Ao ~= Bo then return Ao < Bo end
        return A < B
    end)
    return Values
end

function Functions:IsPrioritized(Label)
    return table.find(Manager.Config.PriorityList, Label) ~= nil
end

function Functions:IsAlive(Enemy)
    return Enemy
        and Enemy:IsDescendantOf(Manager.Shared.EnemiesRoot)
        and Enemy:GetAttribute("Dead") ~= true
        and (tonumber(Enemy:GetAttribute("HP")) or 0) > 0
        and Enemy.Position.Y > workspace.FallenPartsDestroyHeight + 10
        and Enemy.Position.Magnitude < 1000000
end

function Functions:SupportedRootPosition(Position)
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Excluded = { workspace._ENEMIES }
    if Manager.Player.Character then table.insert(Excluded, Manager.Player.Character) end
    local Ignore = workspace:FindFirstChild("_IGNORE")
    if Ignore then table.insert(Excluded, Ignore) end
    Params.FilterDescendantsInstances = Excluded
    Params.RespectCanCollide = true

    local Hit = workspace:Raycast(Position + Vector3.new(0, 6, 0), Vector3.new(0, -24, 0), Params)
    if Hit and Hit.Normal.Y > 0.3 then
        local Humanoid = Manager.Player.Character and Manager.Player.Character:FindFirstChildOfClass("Humanoid")
        local Root = Manager.Player.Character and Manager.Player.Character:FindFirstChild("HumanoidRootPart")
        local Height = Humanoid and Root and (Humanoid.HipHeight + Root.Size.Y / 2) or Manager.Constants.SpotYOffset
        if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6 then Height += 2 end
        return Vector3.new(Position.X, Hit.Position.Y + Height + 0.1, Position.Z)
    end
    if workspace.StreamingEnabled and os.clock() >= Manager.NextTerrainRequest then
        Manager.NextTerrainRequest = os.clock() + 5
        task.spawn(function()
            pcall(function() Manager.Player:RequestStreamAroundAsync(Position, 2) end)
        end)
    end
    return nil
end

function Functions:FindTarget(Label)
    local Character = Manager.Player.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local BestTarget
    local BestDistance = math.huge

    for _, Enemy in ipairs(Functions:QueryEnemyParts()) do
        if Functions:IsWorldEnemy(Enemy) and Functions:EnemyLabel(Enemy) == Label and Functions:IsAlive(Enemy) then
            local Distance = RootPart and (RootPart.Position - Enemy.Position).Magnitude or 0
            if Distance < BestDistance then
                BestDistance = Distance
                BestTarget = Enemy
            end
        end
    end

    return BestTarget
end

function Functions:PrioritizedAliveEnemies()
    local Enemies = {}
    for _, Enemy in ipairs(Functions:QueryEnemyParts()) do
        if Functions:IsWorldEnemy(Enemy) and Functions:IsPrioritized(Functions:EnemyLabel(Enemy)) and Functions:IsAlive(Enemy) then
            table.insert(Enemies, Enemy)
        end
    end
    return Enemies
end

function Functions:GetAttackGeometry()
    local Character = Manager.Player.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Ignore = workspace:FindFirstChild("_IGNORE")
    local Area = Ignore and Ignore:FindFirstChild("AttackRange")
    local Hitbox = Area and Area:FindFirstChild("Hitbox", true)

    if not (RootPart and Hitbox and Hitbox:IsA("BasePart")) then
        return nil
    end

    local Radius = math.min(Hitbox.Size.X, Hitbox.Size.Y, Hitbox.Size.Z) / 2
    return {
        radius = math.max(1, Radius - Manager.Constants.HitboxMargin),
        rawRadius = Radius,
        centerYOffset = Manager.Constants.SpotYOffset,
        hitbox = Hitbox,
    }
end

function Functions:AddCandidate(Candidates, Seen, Position)
    local Key = string.format("%.1f:%.1f", Position.X, Position.Z)
    if not Seen[Key] then
        Seen[Key] = true
        table.insert(Candidates, Position)
    end
end

function Functions:DistanceToEnemyHitbox(ZoneCenter, Enemy)
    local LocalPoint = Enemy.CFrame:PointToObjectSpace(ZoneCenter)
    local HalfSize = Enemy.Size * 0.5
    local Dx = math.max(math.abs(LocalPoint.X) - HalfSize.X, 0)
    local Dy = math.max(math.abs(LocalPoint.Y) - HalfSize.Y, 0)
    local Dz = math.max(math.abs(LocalPoint.Z) - HalfSize.Z, 0)
    return math.sqrt(Dx * Dx + Dy * Dy + Dz * Dz)
end

function Functions:EnemyIntersectsAttackZone(ZoneCenter, Enemy, Geometry)
    return Functions:IsAlive(Enemy)
        and Functions:DistanceToEnemyHitbox(ZoneCenter, Enemy) <= Geometry.radius
end

function Functions:AddClusterCentroids(Candidates, Seen, Enemies, RootY)
    local Groups = {}

    for _, Enemy in ipairs(Enemies) do
        local Key = tostring(Enemy:GetAttribute("Id") or Enemy:GetAttribute("Name") or Enemy.Name)
        local Group = Groups[Key]
        if not Group then
            Group = {}
            Groups[Key] = Group
        end
        table.insert(Group, Enemy)
    end

    for _, Group in pairs(Groups) do
        if #Group > 1 then
            local SumX, SumZ = 0, 0
            for _, Enemy in ipairs(Group) do
                SumX += Enemy.Position.X
                SumZ += Enemy.Position.Z
            end
            Functions:AddCandidate(Candidates, Seen, Vector3.new(SumX / #Group, RootY, SumZ / #Group))
        end
    end

    for _, Seed in ipairs(Enemies) do
        local Neighbours = table.clone(Enemies)
        table.sort(Neighbours, function(First, Second)
            local FirstDelta = First.Position - Seed.Position
            local SecondDelta = Second.Position - Seed.Position
            local FirstDistance = FirstDelta.X * FirstDelta.X + FirstDelta.Z * FirstDelta.Z
            local SecondDistance = SecondDelta.X * SecondDelta.X + SecondDelta.Z * SecondDelta.Z
            return FirstDistance < SecondDistance
        end)

        local SumX, SumZ = 0, 0
        for Index = 1, math.min(6, #Neighbours) do
            SumX += Neighbours[Index].Position.X
            SumZ += Neighbours[Index].Position.Z
            if Index >= 2 then
                Functions:AddCandidate(Candidates, Seen, Vector3.new(SumX / Index, RootY, SumZ / Index))
            end
        end
    end
end

function Functions:HorizontalRange(Enemy, ZoneCenterY, Radius)
    local VerticalDistance = ZoneCenterY - Enemy.Position.Y
    return math.sqrt(math.max(0, Radius ^ 2 - VerticalDistance ^ 2))
end

function Functions:AddCircleIntersections(Candidates, Seen, First, Second, RootY, Geometry)
    local Dx = Second.Position.X - First.Position.X
    local Dz = Second.Position.Z - First.Position.Z
    local Distance = math.sqrt(Dx * Dx + Dz * Dz)
    if Distance < 0.001 then
        return
    end

    local ZoneCenterY = RootY - Geometry.centerYOffset
    local FirstRange = Functions:HorizontalRange(First, ZoneCenterY, Geometry.radius)
    local SecondRange = Functions:HorizontalRange(Second, ZoneCenterY, Geometry.radius)
    if Distance > FirstRange + SecondRange or Distance < math.abs(FirstRange - SecondRange) then
        return
    end

    local Along = (FirstRange ^ 2 - SecondRange ^ 2 + Distance ^ 2) / (2 * Distance)
    local HeightSquared = FirstRange ^ 2 - Along ^ 2
    if HeightSquared < 0 then
        return
    end

    local Height = math.sqrt(HeightSquared)
    local UnitX, UnitZ = Dx / Distance, Dz / Distance
    local BaseX = First.Position.X + Along * UnitX
    local BaseZ = First.Position.Z + Along * UnitZ
    local OffsetX, OffsetZ = -UnitZ * Height, UnitX * Height

    Functions:AddCandidate(Candidates, Seen, Vector3.new(BaseX + OffsetX, RootY, BaseZ + OffsetZ))
    Functions:AddCandidate(Candidates, Seen, Vector3.new(BaseX - OffsetX, RootY, BaseZ - OffsetZ))
end

function Functions:BestFarmSpot(PrimaryTarget, Enemies, AllowRetarget)
    local Geometry = Functions:GetAttackGeometry()
    if not Geometry then
        Manager.Runtime.attackGeometryMissing = true
        local FallbackSpot = PrimaryTarget.Position + Vector3.new(0, Manager.Constants.SpotYOffset, 0)
        return FallbackSpot, { PrimaryTarget }, nil, PrimaryTarget
    end
    Manager.Runtime.attackGeometryMissing = false

    local Supported = Functions:SupportedRootPosition(PrimaryTarget.Position)
    if not Supported then return nil, {}, Geometry, PrimaryTarget end
    local RootY = Supported.Y
    local Candidates = {}
    local Seen = {}

    Functions:AddCandidate(Candidates, Seen, Vector3.new(PrimaryTarget.Position.X, RootY, PrimaryTarget.Position.Z))
    for _, Enemy in ipairs(Enemies) do
        Functions:AddCandidate(Candidates, Seen, Vector3.new(Enemy.Position.X, RootY, Enemy.Position.Z))
        Functions:AddCandidate(Candidates, Seen, Vector3.new(
            (PrimaryTarget.Position.X + Enemy.Position.X) / 2,
            RootY,
            (PrimaryTarget.Position.Z + Enemy.Position.Z) / 2
        ))
    end

    for FirstIndex = 1, #Enemies - 1 do
        for SecondIndex = FirstIndex + 1, #Enemies do
            local First = Enemies[FirstIndex]
            local Second = Enemies[SecondIndex]
            Functions:AddCandidate(Candidates, Seen, Vector3.new(
                (First.Position.X + Second.Position.X) / 2,
                RootY,
                (First.Position.Z + Second.Position.Z) / 2
            ))
        end
    end
    Functions:AddClusterCentroids(Candidates, Seen, Enemies, RootY)

    for FirstIndex = 1, #Enemies - 1 do
        for SecondIndex = FirstIndex + 1, #Enemies do
            Functions:AddCircleIntersections(
                Candidates,
                Seen,
                Enemies[FirstIndex],
                Enemies[SecondIndex],
                RootY,
                Geometry
            )
        end
    end

    local Character = Manager.Player.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local BestPosition
    local BestCovered = {}
    local BestCount = -1
    local BestMargin = -math.huge
    local BestTravel = math.huge

    for _, Candidate in ipairs(Candidates) do
        local ZoneCenter = Candidate - Vector3.new(0, Geometry.centerYOffset, 0)
        if AllowRetarget or Functions:EnemyIntersectsAttackZone(ZoneCenter, PrimaryTarget, Geometry) then
            local Covered = {}
            local Margin = 0

            for _, Enemy in ipairs(Enemies) do
                local Distance = Functions:DistanceToEnemyHitbox(ZoneCenter, Enemy)
                if Functions:IsAlive(Enemy) and Distance <= Geometry.radius then
                    table.insert(Covered, Enemy)
                    Margin += (Geometry.radius - Distance) / Geometry.radius
                end
            end

            local Travel = RootPart and (RootPart.Position - Candidate).Magnitude or 0
            if #Covered > BestCount
                or (#Covered == BestCount and Margin > BestMargin + 0.0001)
                or (#Covered == BestCount and math.abs(Margin - BestMargin) <= 0.0001 and Travel < BestTravel)
            then
                BestPosition = Candidate
                BestCovered = Covered
                BestCount = #Covered
                BestMargin = Margin
                BestTravel = Travel
            end
        end
    end

    Manager.Runtime.attackRadius = Geometry.rawRadius
    Manager.Runtime.safeAttackRadius = Geometry.radius
    Manager.Runtime.plannedCovered = #BestCovered
    local Focus = PrimaryTarget
    if AllowRetarget and not table.find(BestCovered, Focus) then
        Focus = BestCovered[1] or PrimaryTarget
    end
    return BestPosition, BestCovered, Geometry, Focus
end

Manager.Runtime.inspectEnemy = function(Label)
    local Target = Functions:FindTarget(Label)
    local Spot, Covered
    if Target then Spot, Covered = Functions:BestFarmSpot(Target, { Target }, false) end
    return {
        worlds = Functions:CollectWorldOptions(), enemies = Functions:CollectEnemyOptions(),
        targetPosition = Target and tostring(Target.Position),
        safeSpot = Spot and tostring(Spot), position = Spot, covered = Covered and #Covered or 0,
    }
end

function Functions:ActualTargetCount(Enemies)
    if type(Manager.GameLibrary.Target) ~= "table" then
        return 0
    end

    local Count = 0
    for _, Enemy in ipairs(Enemies) do
        if Enemy and table.find(Manager.GameLibrary.Target, Enemy.Name) then
            Count += 1
        end
    end
    Manager.Runtime.actualTargets = Count
    return Count
end

function Functions:IsActualTarget(Enemy)
    return Enemy
        and type(Manager.GameLibrary.Target) == "table"
        and table.find(Manager.GameLibrary.Target, Enemy.Name) ~= nil
end

function Functions:CoveredHealth(Enemies)
    local Total = 0
    for _, Enemy in ipairs(Enemies) do
        if Enemy and Enemy.Parent then
            Total += math.max(0, tonumber(Enemy:GetAttribute("HP")) or 0)
        end
    end
    return Total
end

function Functions:TeleportOnce(Position)
    if not Position then return false end
    Position = Functions:SupportedRootPosition(Position)
    if not Position then
        Manager.Runtime.movementStatus = "Waiting for terrain to load; teleport blocked."
        return false
    end
    local Character = Manager.Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not (Humanoid and Humanoid.Health > 0 and RootPart and Position) then
        return false
    end

    local TargetCFrame = CFrame.new(Position) * RootPart.CFrame.Rotation

    local Ok = pcall(function()
        Character:PivotTo(TargetCFrame)
    end)

    if not Ok then
        Ok = pcall(function()
            RootPart.CFrame = TargetCFrame
        end)
    end

    if Ok then
        pcall(function()
            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    Manager.Runtime.lastTeleportSucceeded = Ok
    return Ok
end

return Functions
