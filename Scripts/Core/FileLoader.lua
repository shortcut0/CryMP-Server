----------------
FileLoader = {
    LAST_ERROR = nil, -- Last Error ?!
}

----------------
FileLoader.Init = function(self)

    eFileError_NotFound = "File does not exist."
    eFileError_LoadFailed = "Failed to load the file."
    eFileError_ExecFailed = "Failed to execute the file."
end

----------------
FileLoader.LoadFile = function(self, sFile, sType)

    -- TODO: Check if the path is absolute, if not try to find the file with the prefix root dir
    -- CheckDirAbsolute()

    local bOk, sErr = ServerLFS.FileExists(sFile)
    if (not bOk) then
        self:SetError((sErr or eFileError_NotFound))
        return false
    end

    local hLib
    hLib, sErr = loadfile(sFile)
    if (not hLib or sErr) then
        self:SetError((sErr or eFileError_LoadFailed))
        return false
    end

    if (SERVER_DEBUG_MODE) then
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

----------------
FileLoader.SetError = function(self, sError)
    self.LAST_ERROR = sError
end