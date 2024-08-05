------------------
ServerEvents = {
    LinkedEvents = {},
    AvailableEvents = {
    },

    EventKillCount = 1,
}

------------------
ServerEvents.Init = function(self)

    self:RegisterEvents()
    self:ResetEvents()

    EventCall = function(...)
        return self:CallEvent(...)
    end

    EventLink = function(...)
        return self:LinkEvent(...)
    end

    CallEvent = EventCall
    LinkEvent = EventLink
end

------------------
ServerEvents.PostInit = function(self)

    --------
    -- test
    -- LinkEvent(eServerEvent_ScriptTick, "ServerEvents", "Error")
    -- LinkEvent(eServerEvent_ScriptTick, "ServerEvents", "this_function_does_not_exist")
    -- LinkEvent(eServerEvent_ScriptTick, "this_host_does_not_exist", "this_function_does_not_exist")

    --------
    ServerLog(LOG_STARS .. LOG_STARS)

    local iTotalLinks = table.it(self.LinkedEvents, function(x, i, v) return ((x or 0) + table.count(v)) end)
    ServerLog("[%02d] Server Server Events:", iTotalLinks)
    for iEvent, aLinked in pairs(self.LinkedEvents) do
        ServerLog(" > [% 2d] Linked Callbacks: % 2d", iEvent, table.count(aLinked))
    end

    Logger:LogEventTo(GetDevs(), eLogEvent_ServerScripts, "Linked ${red}%d${gray} Server Events..", iTotalLinks)
end

------------------
ServerEvents.Error = function(self)
    this_function_does_not_exist()
end

------------------
ServerEvents.RegisterEvents = function(self)

    eServerEvent_Begin          = 0

    eServerEvent_OnScriptReload     = 1  -- ()           When Server gets re-initialized
    eServerEvent_OnScriptInit       = 2  -- (status)     When Server Initialized
    eServerEvent_ScriptUpdate       = 3  -- ()           When Server Initialized
    eServerEvent_ScriptTick         = 4  -- ()           When Server Initialized
    eServerEvent_ScriptMinuteTick   = 5  -- ()           When Server Initialized
    eServerEvent_ScriptHourTick     = 6  -- ()           When Server Initialized
    eServerEvent_OnClientInit       = 7  -- ()           When Server Initialized
    eServerEvent_OnClientTick       = 8  -- ()           When Server Initialized
    eServerEvent_OnUpdate           = 9  -- ()           When Server Initialized
    eServerEvent_OnClientValidated  = 10  -- ()           When Server Initialized
    eServerEvent_OnClientDisconnect = 11  -- ()           When Server Initialized
    eServerEvent_SavePlayerData     = 12  -- ()           When Server Initialized

    eServerEvent_End            = 13
end

------------------
ServerEvents.ResetEvents = function(self)

    for i = eServerEvent_Begin, eServerEvent_End do
        self.LinkedEvents[i] = {}
    end
end

------------------
ServerEvents.CallEvent = function(self, iEvent, ...)

    local sError
    if (not isNumber(iEvent)) then
        sError = error("attempt to call invalid event (bad identifier (" .. g_ts(iEvent) .. ")")
    elseif (iEvent <= eServerEvent_Begin or iEvent >= eServerEvent_End) then
        sError = error("attempt to call invalid event (out of range)")
    end

    if (sError) then
        if (SERVER_DEBUG_MODE) then
            error(sError)
        else


            HandleError("Execute Event (%d) Failed (%s)", sError)
            return ServerLogError(sError)
        end
    end

    local aEvents = self.LinkedEvents[iEvent]
    if (table.empty(aEvents)) then
        return
    end

    local hReturn
    local bOk, sErr
    local sHost, sFunc
    local aArgs = { ... }
    table.insert(aArgs, iEvent)

    for _, aInfo in pairs(aEvents) do

        sHost = aInfo.Host
        sFunc = aInfo.Func
        if (aInfo.Active) then
            if (SERVER_DEBUG_MODE) then
                hReturn = aInfo.Function(checkGlobal(sHost), unpack(aArgs))
            else
                bOk, sErr = pcall(aInfo.Function, checkGlobal(sHost), unpack(aArgs))
                if (not bOk) then

                    HandleError("Execute Event (%d) Failed (%s)", sErr)

                    ServerLogError("Execute Event %d for Host \"%s\" for function \"%s\" failed", iEvent, sHost, sFunc)
                    ServerLogError("%s", (sErr or "N/A"))
                    ServerLogError("%s", (debug.traceback() or "N/A"))

                    aInfo.Errors.Count = (aInfo.Errors.Count + 1)
                    if (aInfo.Errors.Count >= aInfo.Errors.KillCount) then
                        aInfo.Active = false
                        ServerLogError("Event %d for Host \"%s\" for function \"%s\" disabled", iEvent, sHost, sFunc)
                    end
                    aInfo.Errors.Last  = timernew(1)
                end
            end
        end
    end

    -- FIXME
    -- This returns only the most recent called event.
    -- this is bad!
    return hReturn
end

------------------
ServerEvents.LinkEvent = function(self, iEvent, hThis, hFunc)

    local sError
    if (not isNumber(iEvent)) then
        sError = ("attempt to link invalid event (bad identifier (" .. g_ts(iEvent) .. "))  ")
    elseif (iEvent <= eServerEvent_Begin or iEvent >= eServerEvent_End) then
        sError = ("attempt to link invalid event (out of range)")
    elseif (not isString(hThis)) then
        sError = ("due to performance issues, host for events cannot be a table")
    end

    if (sError) then
        if (SERVER_DEBUG_MODE) then
            error(sError)
        else

            HandleError("Event Linking Error (%s)", sError)
            return ServerLogError(sError)
        end
    end

    local fFunc = hFunc
    if (isString(fFunc)) then
        fFunc = checkGlobal(string.format("%s.%s", hThis, fFunc))
    end

    if (not isFunc(fFunc)) then
        error("attempt to link event with an invalid function")
    end

    table.insert(self.LinkedEvents[iEvent], {

        Active   = true,

        Function = fFunc,
        Func     = hFunc,
        Host     = hThis,

        Errors = {
            Count = 0,
            Last  = timernew(0),
            KillCount = self.EventKillCount
        }
    })
end