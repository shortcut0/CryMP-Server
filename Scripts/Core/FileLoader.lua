----------------
FileLoader = {
    LAST_ERROR = nil, -- Last Error ?!
}

----------------

eFileError_NotFound   = "File does not exist."
eFileError_LoadFailed = "Failed to load the file."
eFileError_ExecFailed = "Failed to execute the file."

--------------------------------
--- Init
FileLoader.Init = function(self)
end

--------------------------------
--- Init
FileLoader.LoadFile = function(self, sFile, sType)

    -- TODO: Check if the path is absolute, if not try to find the file with the prefix root dir
    -- CheckDirAbsolute()

    local bOk, sErr = ServerLFS.FileExists(sFile)
    if (not bOk) then
        self:SetError((sErr or eFileError_NotFound))
        return false, sErr
    end

    local hLib
    hLib, sErr = loadfile(sFile)
    if (not hLib or sErr) then
        self:SetError((sErr or eFileError_LoadFailed))
        return false, sErr
    end

    if (DebugMode()) then
        bOk, sErr = true, nil
        hLib()
    else
        bOk, sErr = pcall(hLib)
    end

    if (not bOk or sErr) then
        self:SetError((sErr or eFileError_ExecFailed))
        return false
    end

    -- Statistical purposes..
    Server.Initializer:OnFileLoaded(sFile, sType)

    return true
end

--------------------------------
--- Init
FileLoader.ReadFile = function(self, sFile, sType)

    -- TODO: Check if the path is absolute, if not try to find the file with the prefix root dir
    -- CheckDirAbsolute()

    local bOk, sErr = ServerLFS.FileExists(sFile)
    if (not bOk) then
        self:SetError((sErr or eFileError_NotFound))
        return nil, sErr
    end

    local sData = FileRead(sFile)
    if (not sData) then
        return
    end

    -- Statistical purposes..
    Server.Initializer:OnFileLoaded(sFile, sType)

    return sData
end

--------------------------------
--- Init
FileLoader.ExecuteFile = function(self, sFile, sType, hDefault)

    local sData, sError = self:ReadFile(sFile, sType)
    if (string.empty(sData)) then
        if (sError) then

            HandleError("Error Reading file %s for executing (%s)", sFile, (sError or "N/A"))
            ServerLogError("Error Reading file %s for executing (%s)", sFile, (sError or "N/A"))
        end
        return hDefault
    end

    local bOk, sErr = pcall(loadstring(sData))
    if (not bOk) then

        HandleError("Failed to execute file %s (%s)", sFile, g_ts(sErr))
        ServerLogError("Failed to execute file %s (%s)", sFile, g_ts(sErr))
        return hDefault
    end

    return sErr
end

--------------------------------
--- Init
FileLoader.SetError = function(self, sError)
    self.LAST_ERROR = sError
end