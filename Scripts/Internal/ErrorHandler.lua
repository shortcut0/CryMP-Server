----------------
ErrorHandler = {
    CollectedErrors = {},
    LogTimer = timernew(5),
    UnloggedErrorCount = 0
}

----------------
ErrorHandler.Init = function(self)
    HandleError = self.OnError
end

----------------
ErrorHandler.OnError = function(sMessage, ...)

    local sFormatted = string.formatex(sMessage, ...)

    ErrorHandler:CollectedError(sFormatted)
    ErrorHandler:Log(sFormatted)

end

----------------
ErrorHandler.Log = function(self, sFormatted)

    if (self.LogTimer.expired()) then
        self.LogTimer.refresh()
        Logger:LogEvent(eLogEvent_ScriptError, string.format("%d New Script Errors Occured, Check Error Log!", self.UnloggedErrorCount))
        self.UnloggedErrorCount = 0
    end

    self.UnloggedErrorCount = ((self.UnloggedErrorCount or 0) + 1)
    ServerLogError("Script Error: %s", sFormatted)
end

----------------
ErrorHandler.CollectedError = function(self, sFormatted)

    table.insert(self.CollectedErrors, {
        Timer   = timernew(),
        Message = sFormatted
    })

end