-------------
ServerConfig = (ServerConfig or {
    ModifiedCVars = {},
    DefaultConfig = {
        ID = "Default",
        Active = false,
        Config = {

        }
    }
})

-------------

ServerConfig.ActiveConfig = nil
ServerConfig.LoadedConfigs = {}

-------------

eConfigGet_Any     = 0
eConfigGet_Number  = 1
eConfigGet_String  = 2
eConfigGet_Boolean = 3
eConfigGet_Array   = 4

--------------------------------
--- Init
ServerConfig.Init = function(self)

    ServerLog("Config.Init()")

    -----
    ConfigGet = self.Get
    ConfigGetMerge = self.GetAndMerge
    ConfigCreate = self.Create

    -----
    self:LoadServerConfig()
    ServerLog("Loaded %02d Custom Configurations", table.size(self.LoadedConfigs))

    -----
    if (not self:GetActiveConfig()) then
        self.ActiveConfig = self.DefaultConfig
    end

    -------------------
    --- Init Logging!
    local aActive = (self:GetActiveConfig())
    local iEntries = table.countRec(aActive.Config)
    local iCVars = table.count(self.ModifiedCVars)

    ServerLog("Active Config: %s", aActive.ID)
    ServerLog(" > Configuration Entries: %02d, CVars Changed: %02d", iEntries, iCVars)

end

--------------------------------
--- Init
ServerConfig.PostInit = function(self)

    ServerLog("Config.PostInit()")

    -------------------
    --- Init Logging!
    local aActive = (self:GetActiveConfig())
    local iEntries = table.countRec(aActive.Config)
    local iCVars = table.count(self.ModifiedCVars)

    Logger:LogEventTo(GetDevs(), eLogEvent_Config, "Selected Config %s with ${red}%d${gray} Modifications and ${red}%d${gray} CVars", aActive.ID, iEntries, iCVars)
end

--------------------------------
--- Init
ServerConfig.LoadServerConfig = function(self)

    local aFiles = ServerLFS.DirGetFiles(SERVER_DIR_CONFIG, GETFILES_FILES, ".*\.lua$")
    if (table.empty(aFiles)) then
        return ServerLog("No Configuration files found.")
    end

    local iConfigCount = 0
    local iLastCount = 0
    for _, sFile in pairs(aFiles) do

        if (not FileLoader:LoadFile(sFile, eFileType_Config)) then
            -- TODO: Error Handler
            -- ErrorHandler()

            HandleError("Failed to load Config file %s (%s)", ServerLFS.FileGetName(sFile), FileLoader.LAST_ERROR)
        end

        iConfigCount = table.count(self.LoadedConfigs)
        if (iConfigCount == iLastCount) then
            HandleError("File %s is not a proper Config file!", ServerLFS.FileGetName(sFile))
        end

        iLastCount = iConfigCount
    end
end

--------------------------------
--- Init
ServerConfig.Create = function(aConfig)

    if (not aConfig) then
        throw_error("ConfigCreate() no config provided")
    end

    if (not isArray(aConfig)) then
        throw_error("ConfigCreate() config provided is not an array")
    end

    if (not isArray(aConfig.Config)) then
        throw_error("ConfigCreate() config provided in arg is not an array")
    end

    local sId = checkString(aConfig.ID, ServerConfig:GetConfigId())
    if (ServerConfig:GetConfig(sId)) then
        throw_error(string.format("Config %s already exists", sId))
    end

    ServerConfig.LoadedConfigs[sId] = aConfig
    if (aConfig.Active) then
        if (ServerConfig:GetActiveConfig() ~= nil) then
            ServerLogError("Multiple active configs found.. using most recently loaded..")
        end

        ServerConfig:SetActiveConfig(sId)
    end
end

--------------------------------
--- Init
ServerConfig.SetActiveConfig = function(self, sId)

    ServerLog("Activating Config %s", sId)

    -- Restore previous CVars
    self:RestoreCVars()

    self.ActiveConfig = table.copy(self.LoadedConfigs[sId])
    self:ChangeCVars(self.ActiveConfig.CVars)

    if (self.ActiveConfig.FixInvalid) then
        ServerLog("Analysing Config Data..")
        self:ResolveConfig(self.ActiveConfig.Config)
    end
end

--------------------------------
--- Init
ServerConfig.ResolveConfig = function(self, aData, sTrace)

    if (not isArray(aData)) then
        return
    end

    sTrace = sTrace or "Config"

    local sType, hType, sKey
    for i, v in pairs(aData) do
        if (isArray(v)) then
            self:ResolveConfig(aData[i], (sTrace .. "." .. i))
        else
            sType = string.sub(i, 1, 1)
            sKey = string.sub(i, 2)
            hType = type(v)
            if (string.islc(sType)) then
                if (string.matchex(sType, "f", "n", "i")) then
                    if (not isNumber(v)) then
                        ServerLogWarning("Entry %s in %s is not a Number (It's %s)", i, sTrace, hType)
                        aData[i] = nil
                    else
                     --   aData[sKey] = v
                    end
                elseif (string.match(sType, "b")) then
                    if (not isBoolean(v) or isNumber(v)) then
                        ServerLogWarning("Entry %s in %s is not a Boolean or Integer (It's %s)", i, sTrace, hType)
                        aData[i] = nil
                    else
                    --    aData[i] = (v == true or (v == 1))
                    --    aData[sKey] = (v == true or (v == 1))
                    end
                elseif (string.match(sType, "s")) then
                    if (not isString(v)) then
                        ServerLogWarning("Entry %s in %s is not a string (It's %s)", i, sTrace, hType)
                        aData[i] = nil
                    else
                    --    aData[sKey] = v
                    end
                end
            end
        end
    end
end

--------------------------------
--- Init
ServerConfig.RestoreCVars = function(self)

    local aOriginal = self.ModifiedCVars
    if (table.empty(aOriginal)) then
        return
    end

    ServerLog("Restoring %d original CVars..", table.count(self.ModifiedCVars))
    self:ChangeCVars(aOriginal, true)
    self.ModifiedCVars = {}
end

--------------------------------
--- Init
ServerConfig.ChangeCVars = function(self, aList, bNoSave)

    if (not isArray(aList)) then
        return
    end

    for sCVar, sVal in pairs(aList) do
        if (not bNoSave) then
            if (self.ModifiedCVars[sCVar]) then
                ServerLog("%s - Overwriting stored CVar backup!", sCVar)
            end
            self.ModifiedCVars[sCVar] = GetCVar(sCVar)
        end

        SetCVar(sCVar, g_ts(sVal))
    end
end

--------------------------------
--- Init
ServerConfig.GetActiveConfig = function(self, sId)
    return (self.ActiveConfig)
end

--------------------------------
--- Init
ServerConfig.GetConfig = function(self, sId)
    return self.LoadedConfigs[sId]
end

--------------------------------
--- Init
ServerConfig.GetConfigId = function(self)
    return (string.format("Config-%02d", table.count(self.LoadedConfigs)))
end

--------------------------------
--- Init
ServerConfig.GetAndMerge = function(sGet, hMerge, hDefault, bDeep)
    local hValue = ServerConfig.Get(sGet, hDefault, (eConfigGet_Array   ))

    local hMerged
    if (isArray(hValue)) then
        hMerged = table.deepMerge(hMerge, hValue, bDeep)
    end

    return (hMerged or hValue)
end

--------------------------------
--- Init
ServerConfig.Get = function(sGet, hDefault, iType)
    local hValue = checkGlobal("ServerConfig.ActiveConfig.Config." .. sGet, hDefault)

    iType = (iType or eConfigGet_Any)
    if (iType == eConfigGet_Any) then
        if (hValue ~= nil) then
            return hValue
        end
        return hDefault

    elseif (iType == eConfigGet_Array) then
        if (not isArray(hValue)) then
            return hDefault
        end

   elseif (iType == eConfigGet_Number) then
        if (not isNumber(hValue)) then
            return hDefault
        end

   elseif (iType == eConfigGet_String) then
        if (not isString(hValue)) then
            return hDefault
        end

   elseif (iType == eConfigGet_Boolean) then
        if (not isBool(hValue)) then
            return hDefault
        end
    end

    return hValue
end