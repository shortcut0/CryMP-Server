----------------
ErrorHandler = {
    CollectedErrors = {}
}

----------------
ErrorHandler.Init = function(self)
    ErrorHandler = self.ErrorHandler
end

----------------
ErrorHandler.ErrorHandler = function(self, sMessage, ...)

    local sFormatted = string.formatex(sMessage, ...)
    Logger:LogEvent(eLogEvent_ScriptError, sFormatted)

    table.insert(self.CollectedErrors, {
        Timer   = timernew(),
        Message = sFormatted
    })
end