-------------------
ServerInjector = {
    QueuedFunctions = {},

    FILE = nil,
    LOADED_FILES = {},

    DataDir = (SERVER_DIR_INTERNAL .. "Injections\\"),
}

-------------------
ServerInjector.Init = function(self)

    eInjection_Replace = 0
    eInjection_Post = 1
    eInjection_Pre = 2

    self.LOADED_FILES = {}
    self:LoadFiles()
    self:ExecuteQueue()

    local iTotalInjections = table.it(self.LOADED_FILES, function(x, i, v) return ((x or 0) + v.Injections) end)
    if (SERVER_DEBUG_MODE) then
        ServerLog(LOG_STARS)
        ServerLog("[%04d] Injections:", iTotalInjections)
        for sFile, aData in pairs(self.LOADED_FILES) do
            ServerLog(" > [%-15s] Loaded: %5s, Calls: %02d, Injections: %03d", ServerLFS.FileGetName(sFile), g_ts(aData.Error ~= true), aData.Calls, aData.Injections)
        end
    end

    Logger:LogEventTo(GetDevs(), eLogEvent_ServerScripts, "Injected ${red}%d${gray} Script Functions..", iTotalInjections)
end

-------------------
ServerInjector.LoadFiles = function(self)

    -- TODO: Make it recursive
    local aFiles = ServerLFS.DirGetFiles(self.DataDir, GETFILES_FILES, ".*\.lua$")
    if (table.empty(aFiles)) then
        return ServerLog("No Injection files found.")
    end

    for _, sFile in pairs(aFiles) do

        -- Statistical purposes..
        self.FILE = sFile
        self.LOADED_FILES[sFile] = { Error = false, Calls = 0, Injections = 0 }

        if (not FileLoader:LoadFile(sFile)) then

            -- TODO: Error Handler
            -- ErrorHandler()

            ServerLogError("Failed to load file %s (%s)", ServerLFS.FileGetName(sFile), FileLoader.LAST_ERROR)
            self.LOADED_FILES[sFile].Error = true
        else
        end
    end
end

-------------------
ServerInjector.ExecuteQueue = function(self)

    if (table.empty(self.QueuedFunctions)) then
        return
    end

    for _, aCall in pairs(self.QueuedFunctions) do
        for __, hFunc in pairs(aCall[2]) do
            hFunc(aCall[1])
        end
    end

    self.QueuedFunctions = nil
end

-------------------
ServerInjector.InjectAll = function(aArray)

    local sFile = (ServerInjector.FILE)
    local aHost = (aArray.This)
    if (isString(aHost)) then
        aHost = _G[aHost]
    end
    local aFuncs = {}

    for _, aInject in pairs(aArray) do
        if (isFunc(aInject)) then
            table.insert(aFuncs, aInject)

            -- Statistical purposes
            if (sFile) then
                ServerInjector.LOADED_FILES[sFile].Calls = (ServerInjector.LOADED_FILES[sFile].Calls + 1)
            end
        elseif (isArray(aInject)) then
            ServerInjector.Inject(aInject, aArray)

            -- Statistical purposes
            if (sFile) then
                ServerInjector.LOADED_FILES[sFile].Injections = (ServerInjector.LOADED_FILES[sFile].Injections + 1)
            end
        end
    end

    if (not table.empty(aFuncs)) then
        table.insert(ServerInjector.QueuedFunctions, { aHost, aFuncs })
    end
end


-------------------
ServerInjector.Inject = function(aParams, aInfo)

    local sEntity   = aParams.Class
    local hEntity   = aParams.Entity
    local sTarget   = aParams.Target
    local fFunction = aParams.Function
    local iType     = (aParams.Type or eInjection_Replace)
    local bPatchEntities = aInfo.PatchEntities

    if (hEntity) then
        ServerInjector.InjectEntity(aParams)
    end

    local hClass = _G[sEntity]
    if (not hClass) then

        -- FIXME: Error Handler
        -- ErrorHandler()

        ServerLogError("Class %s to Inject not found", sEntity)
        return
    end

    local function Replace(sT, c, f)

        --Debug(string.format("replace %s on %s",sT,g_ts(c)))
        local aNest = string.split(sT, ".")
        local iNest = table.size(aNest)
        if (iNest == 1) then

            local o = (sT .. "_ORIGINAL")
            local r = (sT .. "_REPLACED")
            if (iType == eInjection_Replace) then
                c[sT] = f


            else

                -- FIXME
                throw_error("implementation missing")
            end
        else
            local h = table.remove(aNest, 1)
            if (not c[h]) then
                throw_error("index " .. g_ts(h) .. " not found")
            end
            return Replace(table.concat(aNest, "."), c[h], f)
        end
    end

    if (isArray(sTarget)) then
        for _, s in pairs(sTarget) do
            Replace(s, hClass, fFunction)
        end
    else
        Replace(sTarget, hClass, fFunction)
    end

    if (bPatchEntities) then
        for _, hEnt in pairs(GetEntities(sEntity) or {}) do
            if (isArray(sTarget)) then
                for _, s in pairs(sTarget) do
                    Replace(s, hEnt, fFunction)
                end
            else
                Replace(sTarget, hEnt, fFunction)
            end
        end
    end
end

--[[
ServerInjector.Inject({
    Class = "g_gameRules"
    Entity = nil, -- Literal entity

    Target = "OnInit", -- Target Function
    Target = "Array.OnInit", -- Target Function
    Target = "Array.Array.OnInit", -- Target Function

    Function = function() end, -- Replacement function

    Type = eInjection_Replace, -- Replace
    Type = eInjection_Pre, -- Target + Original
    Type = eInjection_Post, -- Original + Target

    Finish = function() end, -- Called once injection finished
})

]]