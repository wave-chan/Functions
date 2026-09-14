--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager, Tab, LoopCooldown)
    Manager = OwnManager
    
    LoopCooldown = LoopCooldown or 0.05
    local Section = Tab:AddSection("Gamemodes")

    local MapsArray = {}
    for MapName, MapInfo in pairs(Manager.Shared.MapData) do
        MapsArray[MapInfo.Order + 1] = MapName
    end

    for ModeId, ModeInfo in pairs(Manager.Shared.GamemodeData) do
    
        local LoopId = `GamemodeLoop_{ModeId}`
        local ToggleId = `autoGamemode_{ModeId}`

        local Types = {}
        for TypeName, TypeInfo in pairs(ModeInfo) do
            Types[math.max(TypeInfo.Order or 0, 1)] = TypeName
        end

        local EntryTypes = {"Join"}
        if ModeInfo.RequiredItem then
            table.insert(EntryTypes, "Create")
        end

        local Toggle = Section:AddToggle(ToggleId, {Title = `Auto {ModeId}`, Default = false })
        Section:AddToggle(`autoGamemodeLeave_{ModeId}`, {Title = `Auto Leave`, Default = false })
        Section:AddDropdown(`entryType_{ModeId}`, {
            Title = "Select the entry type",
            Values = EntryTypes,
            Multi = false,
            Default = "Join",
        })    
        if #Types > 0 then
          Section:AddDropdown(`gamemodeMapId_{ModeId}`, {
              Title = "Select the map id",
              Values = Types,
              Multi = false,
              Default = Types[1],
          })
        end
        Section:AddDropdown(`leaveToMap_{ModeId}`, {
            Title = "Select the map to leave",
            Values = MapsArray,
            Multi = false,
            Default = MapsArray[1],
        })
        Section:AddInput(`leaveWaveGamemode_{ModeId}`, {
            Title = "Wave to leave\n(0) = infinite",
            Numeric = true,
            Finished = false,
            Default = "0",
            Callback = function(key)
            end
        })

        local Loop = Manager.Cache.Loops[LoopId]
        if Loop or not Manager.Utils.Loop then continue end

        Manager.Cache.Loops[LoopId] = Manager.Utils.Loop:Connect(LoopCooldown, function()
            self:Auto(ModeId)
        end, function()
            return Toggle and Toggle.Value
        end)

    end
end

function module:GetJoinInfo(ModeId: string, MapId: string)
    local GamemodeDiff, HostId
    
    local Folders = game.ReplicatedStorage.Server.Gamemode
    for _, GamemodeFolder in ipairs(Folders:GetChildren()) do
        local GamemodeData = GamemodeFolder:GetAttributes()
        if GamemodeData.Private or GamemodeData.Status ~= "Opened" then continue end
    
        if GamemodeData.ModeId ~= ModeId or GamemodeData.MapId ~= MapId then continue end
        GamemodeDiff, HostId = GamemodeData.Diff, GamemodeData.HostId
    end

    return GamemodeDiff, HostId
end

function module:GetData(ModeId: string, HostId: number)
    local InMode = Manager.Player:GetAttribute("InMode") or ModeId and HostId and `{ModeId}_{HostId}`
    if not InMode then return end

    local Folders = game.ReplicatedStorage.Server.Gamemode
    local GamemodeFolder = Folders:FindFirstChild(InMode)
    if not GamemodeFolder then return end

    return GamemodeFolder:GetAttributes()
end

function module:Auto(ModeId: string)
    local Options = Manager.Fluent.Options
    local Settings = {
        Auto = Options[`autoGamemode_{ModeId}`] and Options[`autoGamemode_{ModeId}`].Value,
        Leave = Options[`autoGamemodeLeave_{ModeId}`] and Options[`autoGamemodeLeave_{ModeId}`].Value,
        EntryType = Options[`entryType_{ModeId}`] and Options[`entryType_{ModeId}`].Value,
        MapId = Options[`gamemodeMapId_{ModeId}`] and Options[`gamemodeMapId_{ModeId}`].Value,
        Wave = tonumber(Options[`leaveWaveGamemode_{ModeId}`] and Options[`leaveWaveGamemode_{ModeId}`].Value or "0") or 0,
        MapToLeave = Options[`leaveToMap_{ModeId}`] and Options[`leaveToMap_{ModeId}`].Value,
    }

    if not Settings.Auto then return end

    --## COOLDOWN ##--
    local LastClock = Manager.Cooldowns[`GamemodeAuto_{Id}`]
    if LastClock and os.clock() - LastClock < 0.05 then return end
    Manager.Cooldowns[`GamemodeAuto_{Id}`] = nil

    local GamemodeData = self:GetData()
    local IsWaveToLeave = Settings.Leave and Settings.Wave ~= 0 and GamemodeData and GamemodeData.Wave and GamemodeData.Wave >= Settings.Wave

    if IsWaveToLeave then
        Manager:Signal("Teleport", "To", Settings.MapToLeave)
        return
    end

    local PlrModeId = Manager.Player:GetAttribute("Mode")
    if not PlrModeId and Settings.EntryType == "Join" then
        local Diff, HostId = self:GetJoinInfo(ModeId, Settings.MapId)
        if not HostId then return end

        Manager:Signal("GamemodeSystem", "Join", ModeId, HostId)
        return
    elseif not PlrModeId and Settings.EntryType == "Create" then
        Manager:Signal("GamemodeSystem", "Create", ModeId, Settings.MapId, "Easy")
        return
    end

    if not PlrModeId then return end
    Manager:UseFunction("Farm", 0, "Teleport", {"All"})
end

return module
