----------------
ErrorHandler = {
    CollectedErrors    = {},
    LogTimer           = nil,
    UnloggedErrorCount = 0
}

DllErrorCallback = GetDummyFunc()
HandleError = GetDummyFunc()
Interrupt = GetDummyFunc()

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

    DLL_ERROR    = false
    ERROR_THROWN = false
end

----------------
ErrorHandler.GetErrorList = function(self, bCopy)
    local aList = self.CollectedErrors
    return (bCopy and table.copy(aList) or aList)
end

----------------
ErrorHandler.CollectedError = function(self, sFormatted)

    local sFixed
    local sErrorDesc = (string.matchex(sFormatted, "^(Error Thrown .-)\n*", "^(Error .-)\n", "(\\%w+%.lua:%d+:.*)") or sFormatted)
    local aLocation  = string.split(sFormatted, "\n", 2)
    if (table.empty(aLocation)) then
        aLocation = string.split(debug.traceback(), "\n", 2)
    end
    for i, sLine in pairs(aLocation) do
        sFixed = string.gsub(sLine, "^\t+", "")
        for ii = 3, 1, -1 do
            --sFixed = string.matchex(sLine, ".*\\(" .. string.repeats(".-\\", ii) .. ".-:%d+: .+'?)$")
            --sFixed = string.gsub(sLine, "^(.*\\CryMP%-Server\\)", "")
            --sFixed = string.gsub(sLine, "^(.*/CryMP%-Server/)", "")
            if (sFixed) then
                break
            end
        end
        if (sFixed) then
            aLocation[i] = sFixed
        end
    end

    local sEnd = aLocation[1]
    if (sEnd) then
        local sEndTrimmed = string.match(sEnd, ".*:%d+: in (.*)")
        if (sEndTrimmed) then aLocation = table.insertFirst(aLocation, sEndTrimmed) end
    end

    table.insert(self.CollectedErrors, {
        GetTimestamp = GetTimestamp(),
        Timer        = timernew(),
        Error        = {
            Desc     = sErrorDesc,
            Location = aLocation
        }
    })

    --[[
    == [ ~ Error Log ~ ] =============================================================================
    [
    [   1) <1d: 30m: 1s Ago>  : Attempt to Call a Nil Value
    [
    ==================================================================================================
    ]]

end