--## SCRIPT ##--
local module = { Cache = {}, }

function module:GetInfo(Manager, WorldName: string)
    local Cache = self.Cache[WorldName]
    if Cache then return Cache end

    for Index, Info in ipairs(Manager.Shared.Worlds) do
        Info.CacheIndex = Index
        self.Cache[Info.Name] = Info

        if Info.Name == WorldName then
            return Info
        end
    end

    return not WorldName and self.Cache or nil
end

return module
