----------------
ErrorHandler = {
    CollectedErrors    = {},
    LogTimer           = nil,
    UnloggedErrorCount = 0
}

----------------
ErrorHandler.Init = function(self)

    self.LogTimer = timernew(5)

    HandleError = self.OnError
    DllErrorCallback = self.DllErrorCallback
    Interrupt = function(sMsg)
        HandleError(sMsg)
        ServerDLL.SetScriptErrorLog(false)
        error()
    end

end

----------------
ErrorHandler.DllErrorCallback = function(sMessage, ...)

    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
    -- ONLY USE PCALL, NO UNPROTECTED FUNCTIONS HERE !
    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!

    pcall(function()
        DLL_ERROR = true
        HandleError()
    end)

    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
    -- ONLY USE PCALL, NO UNPROTECTED FUNCTIONS HERE !
    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
end

----------------
ErrorHandler.OnError = function(sMessage, ...)

    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
    -- ONLY USE PCALL, NO UNPROTECTED FUNCTIONS HERE !
    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!

    local aParams = { ... }
    pcall(function()

        local sFormatted = string.formatex(sMessage, unpack(aParams))

        ErrorHandler:CollectedError(sFormatted)
        ErrorHandler:Log(sFormatted)
    end)

    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
    -- ONLY USE PCALL, NO UNPROTECTED FUNCTIONS HERE !
    -- !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!!
end

----------------
ErrorHandler.Log = function(self, sFormatted)

    self.UnloggedErrorCount = ((self.UnloggedErrorCount or 0) + 1)
    if (not DLL_ERROR or not ERROR_THROWN) then
        ServerLogError("Script Error: %s", g_ts(sFormatted or ""))
    end

    if (self.LogTimer.expired()) then
        self.LogTimer.refresh()
        Logger:LogEvent(eLogEvent_ScriptError, string.format("%d New Script Errors Occurred, Check Error Log!", self.UnloggedErrorCount))
        self.UnloggedErrorCount = 0
    end

    DLL_ERROR = false
end

----------------
ErrorHandler.GetErrorList = function(self)
    return (self.CollectedErrors)
end

----------------
ErrorHandler.CollectedError = function(self, sFormatted)

    local sErrorDesc = (string.matchex(sFormatted, "^(Error Thrown .-)\n*", "^(Error .-)\n") or sFormatted)
    local aLocation  = string.split(sFormatted, "\n", 2)
    local sFixed
    for i, sLine in pairs(aLocation) do
        sFixed = ""
        for ii = 3, 1, -1 do
            sFixed = string.matchex(sLine, ".*\\(" .. string.repeats(".-\\", ii) .. ".-:%d+: .+'?)$")
            if (sFixed) then
                break
            end
        end
        if (sFixed) then
            aLocation[i] = sFixed
        end
    end

    table.insert(self.CollectedErrors, {
        GetTimestamp = GetTimestamp(),
        Timer        = timernew(),
        Error        = {
            Desc     = sErrorDesc,
            Location = aLocation
        }
    })

end