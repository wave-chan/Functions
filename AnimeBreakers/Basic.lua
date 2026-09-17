--## SCRIPT ##--
local module = { Cache = {}, }
local Manager

function module:Init(OwnManager)
    Manager = OwnManager
end

function module:LoadGameDependencies()
    local Library = require(Manager.Services.ReplicatedStorage.Framework.Library)
    return Library,
        Library:GetService("MultiplierService"),
        Library:GetService("GamemodeService"),
        Library:GetService("GuiService"),
        Library:GetScreen("Notification"):WaitForChild("Messages"),
        Library:GetScreen("Results")
end

function module:WithGameModuleContext(Callback)
    local GetIdentity = getthreadidentity or getidentity
    local SetIdentity = setthreadidentity or setidentity

    if type(GetIdentity) ~= "function" or type(SetIdentity) ~= "function" then
        local Result = table.pack(pcall(Callback))
        if not Result[1] then
            error("Failed to load game modules. This runtime does not expose getthreadidentity/setthreadidentity (or their aliases): " .. tostring(Result[2]), 0)
        end
        return table.unpack(Result, 2, Result.n)
    end

    local PreviousIdentity = GetIdentity()
    local Result = table.pack(xpcall(function()
        SetIdentity(2)
        return Callback()
    end, function(Message)
        return debug.traceback(tostring(Message), 2)
    end))

    local Restored, RestoreError = pcall(SetIdentity, PreviousIdentity)
    if not Restored then
        error("Could not restore the caller's thread identity: " .. tostring(RestoreError), 0)
    end
    if not Result[1] then
        error(Result[2], 0)
    end
    return table.unpack(Result, 2, Result.n)
end

return module
