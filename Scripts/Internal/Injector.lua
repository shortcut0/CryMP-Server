-------------------
ServerInjector = {
    Pending = {}, -- ???

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

    ServerLog(LOG_STARS)
    ServerLog("[%04d] Injections:", table.it(self.LOADED_FILES, function(x, i, v) return ((x or 0) + v.Injections) end))
    for sFile, aData in pairs(self.LOADED_FILES) do
        ServerLog(" > [%-15s] Loaded: %5s, Calls: %02d, Injections: %03d", ServerLFS.FileGetName(sFile), g_ts(aData.Error ~= true), aData.Calls, aData.Injections)
    end
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
ServerInjector.InjectAll = function(aArray)

    local sFile = (ServerInjector.FILE)

    local aHost = (aArray.This)
    for _, aInject in pairs(aArray) do

        if (isFunc(aInject)) then
            aInject(aHost)

            -- Statistical purposes
            if (sFile) then
                ServerInjector.LOADED_FILES[sFile].Calls = (ServerInjector.LOADED_FILES[sFile].Calls + 1)
            end
        else
            ServerInjector.Inject(aInject)

            -- Statistical purposes
            if (sFile) then
                ServerInjector.LOADED_FILES[sFile].Injections = (ServerInjector.LOADED_FILES[sFile].Injections + 1)
            end
        end
    end
end


-------------------
ServerInjector.Inject = function(aParams)

    local sEntity = aParams.Class
    local hEntity = aParams.Entity

    local sTarget = aParams.Target

    local sFunction = aParams.Target
    local fFunction = aParams.Function

    local iType = (aParams.Type or eInjection_Replace)

    if (hEntity) then
        ServerInjector.InjectEntity(aParams)
    end

    local hClass = _G[sEntity]
    if (not hClass) then

        -- FIXME: Error Handler
        return
    end

    local function Replace(sT, c)
        local hTarget
        local aNest = string.split(sT, ".")
        local iNest = table.size(aNest)
        for i, s in pairs(aNest) do

            if (hTarget) then
                hTarget = hTarget[s]
            elseif (i == 1) then
                hTarget = c[s]
            end

            if (i < iNest and hTarget == nil) then

                -- Just create it?
                -- hTarget[s] = {}

                -- FIXME: Error Handler
                -- return ServerLogError("Target %s at index %d to inject on %s not found", s, i, sEntity)
            end
        end
    end

    if (isArray(sTarget)) then
        for _, s in pairs(sTarget) do
            Replace(s, hClass, fFunction)
        end
    else
        Replace(sTarget, hClass, fFunction)
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